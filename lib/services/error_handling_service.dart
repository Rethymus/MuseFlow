import '../utils/logger.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/user_friendly_error_handler.dart';
import '../widgets/error_display_widgets.dart';

/// 错误处理服务
///
/// 提供全局的错误处理、报告和分析功能
class ErrorHandlingService {
  // 单例模式
  static ErrorHandlingService? _instance;
  static ErrorHandlingService get instance {
    _instance ??= ErrorHandlingService._internal();
    return _instance!;
  }

  ErrorHandlingService._internal() {
    _initializeErrorHandling();
  }

  final List<UserFriendlyError> _errorHistory = [];
  final StreamController<UserFriendlyError> _errorStreamController =
      StreamController<UserFriendlyError>.broadcast();
  int _errorCount = 0;
  int _criticalErrorCount = 0;

  /// 初始化错误处理
  void _initializeErrorHandling() {
    // 设置全局错误处理
    if (kDebugMode) {
      Logger.debug('错误处理服务已初始化');
    }

    // 在生产环境中，这里应该设置Crashlytics等错误报告服务
    // 例如：FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }

  /// 处理错误并返回用户友好的错误信息
  UserFriendlyError handleError(dynamic error, [dynamic stackTrace]) {
    final userFriendlyError =
        userFriendlyErrorHandler.handleError(error, stackTrace);

    // 记录错误
    _recordError(userFriendlyError);

    // 记录到日志
    userFriendlyErrorHandler.logError(userFriendlyError);

    // 发送到错误流
    _errorStreamController.add(userFriendlyError);

    // 在生产环境中发送到错误报告服务
    if (!kDebugMode) {
      _sendToErrorReporting(userFriendlyError, stackTrace);
    }

    return userFriendlyError;
  }

  /// 记录错误
  void _recordError(UserFriendlyError error) {
    _errorHistory.add(error);
    _errorCount++;

    if (error.severity == ErrorSeverity.critical) {
      _criticalErrorCount++;
    }

    // 限制历史记录大小
    if (_errorHistory.length > 100) {
      _errorHistory.removeAt(0);
    }

    if (kDebugMode) {
      Logger.debug('错误已记录。总错误数: $_errorCount, 严重错误数: $_criticalErrorCount');
    }
  }

  /// 发送到错误报告服务
  void _sendToErrorReporting(UserFriendlyError error, dynamic stackTrace) {
    // 这里应该将错误发送到Crashlytics、Sentry等服务
    // 例如：FirebaseCrashlytics.instance.recordError(error, stackTrace);

    if (kDebugMode) {
      Logger.debug('错误报告已生成：${error.title}');
    }
  }

  /// 显示错误
  Future<void> showError(
    BuildContext context,
    dynamic error, [
    dynamic stackTrace,
  ]) async {
    final userFriendlyError = handleError(error, stackTrace);

    await ErrorDisplayWidgets.showErrorDialog(context, userFriendlyError);
  }

  /// 显示错误横幅
  void showErrorBanner(
    BuildContext context,
    dynamic error, [
    dynamic stackTrace,
  ]) {
    final userFriendlyError = handleError(error, stackTrace);

    ErrorDisplayWidgets.showErrorBanner(
      context,
      userFriendlyError,
      onAction: () => ErrorDisplayWidgets.showErrorDialog(context, userFriendlyError),
    );
  }

  /// 错误流
  Stream<UserFriendlyError> get errorStream => _errorStreamController.stream;

  /// 获取错误历史
  List<UserFriendlyError> getErrorHistory({int limit = 50}) {
    if (_errorHistory.length <= limit) {
      return List.from(_errorHistory);
    }
    return _errorHistory.sublist(_errorHistory.length - limit);
  }

  /// 获取错误统计
  Map<String, dynamic> getErrorStatistics() {
    final recentErrors = getErrorHistory(limit: 100);

    final categoryCounts = <ErrorCategory, int>{};
    final severityCounts = <ErrorSeverity, int>{};

    for (final error in recentErrors) {
      categoryCounts[error.category] =
          (categoryCounts[error.category] ?? 0) + 1;
      severityCounts[error.severity] =
          (severityCounts[error.severity] ?? 0) + 1;
    }

    return {
      'total_errors': _errorCount,
      'critical_errors': _criticalErrorCount,
      'recent_errors': recentErrors.length,
      'category_counts': categoryCounts.map(
        (category, count) => MapEntry(category.toString(), count),
      ),
      'severity_counts': severityCounts.map(
        (severity, count) => MapEntry(severity.toString(), count),
      ),
    };
  }

  /// 创建错误报告
  Future<String> createErrorReport() async {
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'statistics': getErrorStatistics(),
      'recent_errors':
          getErrorHistory(limit: 20).map((error) => error.toJson()).toList(),
      'system_info': _getSystemInfo(),
    };

    // 这里应该将报告保存到文件或发送到服务器
    final reportPath = await _saveErrorReport(report);

    if (kDebugMode) {
      Logger.debug('错误报告已生成：$reportPath');
    }

    return reportPath;
  }

  /// 保存错误报告
  Future<String> _saveErrorReport(Map<String, dynamic> report) async {
    // 生成报告文件名
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'error_report_$timestamp.json';

    // 在实际应用中，应该保存到应用的文档目录
    // 这里简化处理
    final directory = Directory.systemTemp;
    final file = File('${directory.path}/museflow/$fileName');

    await file.create(recursive: true);
    await file
        .writeAsString(const JsonEncoder.withIndent('  ').convert(report));

    return file.path;
  }

  /// 获取系统信息
  Map<String, dynamic> _getSystemInfo() {
    return {
      'operating_system': Platform.operatingSystem,
      'operating_system_version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
      'path_separator': Platform.pathSeparator,
      'number_of_processors': Platform.numberOfProcessors,
      // 安全修复：生产环境中移除敏感路径信息
      if (kDebugMode) ...{
        'executable': Platform.executable,
        'resolved_executable': Platform.resolvedExecutable,
        'script': Platform.script.path,
      },
    };
  }

  /// 清除错误历史
  void clearErrorHistory() {
    _errorHistory.clear();
    _errorCount = 0;
    _criticalErrorCount = 0;

    if (kDebugMode) {
      Logger.debug('错误历史已清除');
    }
  }

  /// 检查是否有严重错误
  bool hasCriticalErrors() {
    return _criticalErrorCount > 0;
  }

  /// 获取最近的严重错误
  List<UserFriendlyError> getRecentCriticalErrors() {
    return _errorHistory
        .where((error) => error.severity == ErrorSeverity.critical)
        .toList();
  }

  /// 分析错误模式
  Map<String, dynamic> analyzeErrorPatterns() {
    final recentErrors = getErrorHistory(limit: 100);

    // 分析错误类别频率
    final categoryFrequency = <ErrorCategory, int>{};
    for (final error in recentErrors) {
      categoryFrequency[error.category] =
          (categoryFrequency[error.category] ?? 0) + 1;
    }

    // 找出最常见的错误类别
    final mostCommonCategory =
        categoryFrequency.entries.reduce((a, b) => a.value > b.value ? a : b);

    // 分析错误趋势
    final recentTrend = _analyzeErrorTrend(recentErrors);

    return {
      'most_common_category': mostCommonCategory.key.toString(),
      'most_common_category_count': mostCommonCategory.value,
      'total_recent_errors': recentErrors.length,
      'trend': recentTrend,
      'recommendations':
          _generateRecommendations(categoryFrequency, recentTrend),
    };
  }

  /// 分析错误趋势
  String _analyzeErrorTrend(List<UserFriendlyError> errors) {
    if (errors.length < 10) return '数据不足';

    final recentErrors = errors.take(10).toList();
    final olderErrors = errors.skip(10).take(10).toList();

    final recentCriticalCount =
        recentErrors.where((e) => e.severity == ErrorSeverity.critical).length;

    final olderCriticalCount =
        olderErrors.where((e) => e.severity == ErrorSeverity.critical).length;

    if (recentCriticalCount > olderCriticalCount * 2) {
      return '错误严重程度在增加';
    } else if (recentCriticalCount < olderCriticalCount ~/ 2) {
      return '错误严重程度在减少';
    } else {
      return '错误严重程度稳定';
    }
  }

  /// 生成改进建议
  List<String> _generateRecommendations(
    Map<ErrorCategory, int> categoryFrequency,
    String trend,
  ) {
    final recommendations = <String>[];

    // 基于最常见错误类别的建议
    final mostCommon =
        categoryFrequency.entries.reduce((a, b) => a.value > b.value ? a : b);

    switch (mostCommon.key) {
      case ErrorCategory.fileSystem:
        recommendations.add('建议检查文件访问权限和存储空间');
        recommendations.add('考虑增加文件操作的错误处理');
        break;
      case ErrorCategory.network:
        recommendations.add('建议优化网络连接处理');
        recommendations.add('考虑添加离线模式支持');
        break;
      case ErrorCategory.permission:
        recommendations.add('建议检查应用权限设置');
        recommendations.add('考虑提供权限请求引导');
        break;
      case ErrorCategory.aiService:
        recommendations.add('建议检查AI服务配置和API密钥');
        recommendations.add('考虑添加服务降级机制');
        break;
      default:
        recommendations.add('建议加强错误监控和预防措施');
    }

    // 基于趋势的建议
    if (trend == '错误严重程度在增加') {
      recommendations.add('严重错误增加，建议立即检查系统状态');
      recommendations.add('考虑进行系统维护和优化');
    }

    return recommendations;
  }

  /// 释放资源
  void dispose() {
    _errorStreamController.close();
    clearErrorHistory();
  }
}

/// 全局错误处理服务实例
final errorHandlingService = ErrorHandlingService.instance;

/// 错误处理辅助函数
///
/// 便于在代码中快速处理错误
void handleErrorSilently(dynamic error, [dynamic stackTrace]) {
  errorHandlingService.handleError(error, stackTrace);
}

Future<void> handleErrorWithDialog(
  BuildContext context,
  dynamic error, [
  dynamic stackTrace,
]) async {
  await errorHandlingService.showError(context, error, stackTrace);
}

void handleErrorWithBanner(
  BuildContext context,
  dynamic error, [
  dynamic stackTrace,
]) {
  errorHandlingService.showErrorBanner(context, error, stackTrace);
}

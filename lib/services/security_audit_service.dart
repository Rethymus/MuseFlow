import '../utils/logger.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/file_security_validator.dart';

/// 安全审计服务
///
/// 负责记录和管理所有文件操作的安全审计日志
class SecurityAuditService {
  // 单例模式
  static SecurityAuditService? _instance;
  static SecurityAuditService get instance {
    _instance ??= SecurityAuditService._internal();
    return _instance!;
  }

  SecurityAuditService._internal() {
    _initializeAudit();
  }

  final List<SecurityAuditLog> _auditLogs = [];
  final List<SecurityAlert> _alerts = [];
  bool _isInitialized = false;

  /// 初始化审计系统
  Future<void> _initializeAudit() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final auditDir = Directory('${appDir.path}/museflow/audit');

      if (!await auditDir.exists()) {
        await auditDir.create(recursive: true);
      }

      // 加载现有审计日志
      await _loadExistingAuditLogs(auditDir.path);

      _isInitialized = true;
      Logger.debug('安全审计服务初始化完成');
    } catch (e) {
      Logger.debug('安全审计服务初始化失败: $e');
    }
  }

  /// 记录文件操作
  void logFileOperation({
    required String operation,
    required String filePath,
    required bool allowed,
    String? reason,
    int? fileSize,
    Map<String, dynamic>? metadata,
  }) {
    final log = SecurityAuditLog(
      timestamp: DateTime.now(),
      operation: operation,
      filePath: filePath,
      allowed: allowed,
      reason: reason,
      fileSize: fileSize,
    );

    _auditLogs.add(log);

    // 如果操作被拒绝，创建警报
    if (!allowed) {
      _createAlert(
        severity: AlertSeverity.high,
        message: '文件操作被拒绝: $operation',
        details: reason ?? '未知原因',
        filePath: filePath,
      );
    }

    // 限制内存中的日志数量
    _maintainLogSize();

    Logger.debug('[审计] $log');
  }

  /// 记录安全事件
  void logSecurityEvent({
    required SecurityEventType eventType,
    required String message,
    String? filePath,
    Map<String, dynamic>? details,
  }) {
    final log = SecurityAuditLog(
      timestamp: DateTime.now(),
      operation: eventType.name,
      filePath: filePath,
      allowed: false,
      reason: message,
    );

    _auditLogs.add(log);

    // 根据事件类型创建警报
    final severity = _getSeverityForEvent(eventType);
    _createAlert(
      severity: severity,
      message: message,
      details: details?.toString() ?? '',
      filePath: filePath,
    );

    Logger.debug('[安全事件] $eventType: $message');
  }

  /// 获取审计统计信息
  Map<String, dynamic> getAuditStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));

    final recent24Logs =
        _auditLogs.where((log) => log.timestamp.isAfter(last24Hours)).toList();
    final recent7DaysLogs =
        _auditLogs.where((log) => log.timestamp.isAfter(last7Days)).toList();

    final rejected24 = recent24Logs.where((log) => !log.allowed).length;
    final rejected7Days = recent7DaysLogs.where((log) => !log.allowed).length;

    return {
      'total_logs': _auditLogs.length,
      'last_24_hours': recent24Logs.length,
      'last_7_days': recent7DaysLogs.length,
      'rejected_last_24_hours': rejected24,
      'rejected_last_7_days': rejected7Days,
      'total_alerts': _alerts.length,
      'active_alerts': _alerts.where((alert) => !alert.resolved).length,
      'high_severity_alerts': _alerts
          .where((alert) =>
              alert.severity == AlertSeverity.high && !alert.resolved)
          .length,
    };
  }

  /// 获取最近的审计日志
  List<SecurityAuditLog> getRecentLogs({int limit = 100}) {
    if (_auditLogs.length <= limit) {
      return List.unmodifiable(_auditLogs);
    }
    return List.unmodifiable(_auditLogs.sublist(_auditLogs.length - limit));
  }

  /// 获取活跃的警报
  List<SecurityAlert> getActiveAlerts() {
    return _alerts.where((alert) => !alert.resolved).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 解决警报
  void resolveAlert(String alertId) {
    final alert = _alerts.firstWhere(
      (a) => a.id == alertId,
      orElse: () => throw Exception('警报未找到: $alertId'),
    );
    alert.resolved = true;
    alert.resolvedAt = DateTime.now();
    Logger.debug('警报已解决: $alertId');
  }

  /// 导出审计报告
  Future<String> exportAuditReport() async {
    if (!_isInitialized) {
      throw Exception('审计服务未初始化');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String();
    final reportFile =
        File('${appDir.path}/museflow/audit/report_$timestamp.json');

    final report = {
      'generated_at': timestamp,
      'statistics': getAuditStatistics(),
      'recent_logs':
          getRecentLogs(limit: 500).map((log) => log.toJson()).toList(),
      'active_alerts':
          getActiveAlerts().map((alert) => alert.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(report);
    await reportFile.writeAsString(jsonString);

    Logger.debug('审计报告已导出: ${reportFile.path}');
    return reportFile.path;
  }

  /// 清理旧日志
  Future<void> cleanupOldLogs(
      {Duration maxAge = const Duration(days: 30)}) async {
    final cutoff = DateTime.now().subtract(maxAge);
    final initialSize = _auditLogs.length;

    _auditLogs.removeWhere((log) => log.timestamp.isBefore(cutoff));

    final removedCount = initialSize - _auditLogs.length;
    Logger.debug('清理了 $removedCount 条旧审计日志');
  }

  // 私有方法

  Future<void> _loadExistingAuditLogs(String auditDir) async {
    try {
      final auditFiles = Directory(auditDir)
          .listSync()
          .where((entity) => entity.path.endsWith('.json'))
          .toList();

      for (final file in auditFiles) {
        if (file is! File) continue;

        try {
          final jsonString = await file.readAsString();
          final data = jsonDecode(jsonString) as Map<String, dynamic>;

          if (data.containsKey('logs')) {
            final logs = data['logs'] as List;
            for (final logData in logs) {
              try {
                final log = SecurityAuditLog.fromJson(logData);
                _auditLogs.add(log);
              } catch (e) {
                Logger.debug('解析审计日志失败: $e');
              }
            }
          }
        } catch (e) {
          Logger.debug('加载审计文件失败: ${file.path}, 错误: $e');
        }
      }

      // 按时间戳排序
      _auditLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      Logger.debug('加载现有审计日志失败: $e');
    }
  }

  void _createAlert({
    required AlertSeverity severity,
    required String message,
    required String details,
    String? filePath,
  }) {
    final alert = SecurityAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      severity: severity,
      message: message,
      details: details,
      filePath: filePath,
    );

    _alerts.add(alert);

    // 高严重性警报需要立即处理
    if (severity == AlertSeverity.critical) {
      Logger.debug('[严重警报] $message: $details');
    }
  }

  AlertSeverity _getSeverityForEvent(SecurityEventType eventType) {
    switch (eventType) {
      case SecurityEventType.pathTraversal:
        return AlertSeverity.critical;
      case SecurityEventType.dangerousFileType:
        return AlertSeverity.high;
      case SecurityEventType.fileSizeExceeded:
        return AlertSeverity.medium;
      case SecurityEventType.permissionDenied:
        return AlertSeverity.high;
      case SecurityEventType.invalidOperation:
        return AlertSeverity.low;
      case SecurityEventType.suspiciousActivity:
        return AlertSeverity.high;
    }
  }

  void _maintainLogSize() {
    const maxLogs = 10000;
    if (_auditLogs.length > maxLogs) {
      final removeCount = _auditLogs.length - maxLogs;
      _auditLogs.removeRange(0, removeCount);
      Logger.debug('移除了 $removeCount 条旧审计日志以限制内存使用');
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    _auditLogs.clear();
    _alerts.clear();
    Logger.debug('安全审计服务已关闭');
  }
}

/// 安全事件类型
enum SecurityEventType {
  pathTraversal,
  dangerousFileType,
  fileSizeExceeded,
  permissionDenied,
  invalidOperation,
  suspiciousActivity,
}

/// 警报严重级别
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

/// 安全警报
class SecurityAlert {
  String id;
  DateTime timestamp;
  AlertSeverity severity;
  String message;
  String details;
  String? filePath;
  bool resolved;
  DateTime? resolvedAt;

  SecurityAlert({
    required this.id,
    required this.timestamp,
    required this.severity,
    required this.message,
    required this.details,
    this.filePath,
    this.resolved = false,
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.name,
      'message': message,
      'details': details,
      'file_path': filePath,
      'resolved': resolved,
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    return SecurityAlert(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.medium,
      ),
      message: json['message'] as String,
      details: json['details'] as String,
      filePath: json['file_path'] as String?,
      resolved: json['resolved'] as bool? ?? false,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }
}

/// 全局安全审计服务实例
final securityAuditService = SecurityAuditService.instance;

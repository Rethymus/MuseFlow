import '../utils/logger.dart';
import '../config/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// 错误严重程度
enum ErrorSeverity {
  /// 信息性 - 不影响功能，仅提示
  info,

  /// 警告 - 可能影响某些功能
  warning,

  /// 错误 - 功能无法使用
  error,

  /// 严重 - 应用核心功能受损
  critical,
}

/// 错误分类
enum ErrorCategory {
  /// 文件相关错误
  fileSystem,

  /// 网络相关错误
  network,

  /// 权限相关错误
  permission,

  /// AI服务相关错误
  aiService,

  /// 数据相关错误
  data,

  /// UI相关错误
  ui,

  /// 系统相关错误
  system,

  /// 未知错误
  unknown,
}

/// 用户友好的错误信息
class UserFriendlyError {
  final String title;
  final String description;
  final List<String> solutions;
  final ErrorSeverity severity;
  final ErrorCategory category;
  final String? technicalDetails;
  final String? helpLink;
  final String? contactSupport;

  const UserFriendlyError({
    required this.title,
    required this.description,
    required this.solutions,
    required this.severity,
    required this.category,
    this.technicalDetails,
    this.helpLink,
    this.contactSupport,
  });

  /// 获取显示用的图标
  String get emoji {
    switch (severity) {
      case ErrorSeverity.info:
        return 'ℹ️';
      case ErrorSeverity.warning:
        return '⚠️';
      case ErrorSeverity.error:
        return '❌';
      case ErrorSeverity.critical:
        return '🚨';
    }
  }

  /// 获取颜色代码（用于日志）
  String get colorCode {
    switch (severity) {
      case ErrorSeverity.info:
        return '\x1B[34m'; // 蓝色
      case ErrorSeverity.warning:
        return '\x1B[33m'; // 黄色
      case ErrorSeverity.error:
        return '\x1B[31m'; // 红色
      case ErrorSeverity.critical:
        return '\x1B[35m'; // 紫色
    }
  }

  /// 获取重置代码
  String get resetCode => '\x1B[0m';

  /// 格式化输出
  String format() {
    final buffer = StringBuffer();

    buffer.writeln('$emoji $title');
    buffer.writeln('$description');
    buffer.writeln('\n解决方案：');

    for (int i = 0; i < solutions.length; i++) {
      buffer.writeln('${i + 1}. ${solutions[i]}');
    }

    if (helpLink != null) {
      buffer.writeln('\n📚 帮助文档：$helpLink');
    }

    if (contactSupport != null) {
      buffer.writeln('\n📞 技术支持：$contactSupport');
    }

    if (technicalDetails != null && kDebugMode) {
      buffer.writeln('\n🔧 技术详情：$technicalDetails');
    }

    return buffer.toString();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'solutions': solutions,
      'severity': severity.toString(),
      'category': category.toString(),
      'technicalDetails': technicalDetails,
      'helpLink': helpLink,
      'contactSupport': contactSupport,
    };
  }
}

/// 用户友好的错误处理系统
///
/// 将技术错误转换为用户友好的语言，提供具体的解决步骤和帮助信息
class UserFriendlyErrorHandler {
  // 单例模式
  static UserFriendlyErrorHandler? _instance;
  static UserFriendlyErrorHandler get instance {
    _instance ??= UserFriendlyErrorHandler._internal();
    return _instance!;
  }

  UserFriendlyErrorHandler._internal();

  /// 将异常转换为用户友好的错误信息
  UserFriendlyError handleError(dynamic error, [dynamic stackTrace]) {
    if (error == null) {
      return _unknownError();
    }

    // 文件系统错误
    if (error is FileSystemException) {
      return _handleFileSystemError(error);
    }

    // 权限错误
    if (error is PermissionDeniedException) {
      return _handlePermissionError(error);
    }

    // 网络错误
    if (error is SocketException || error is HttpException) {
      return _handleNetworkError(error);
    }

    // 格式错误
    if (error is FormatException) {
      return _handleFormatError(error);
    }

    // 状态错误
    if (error is StateError) {
      return _handleStateError(error);
    }

    // 超时错误
    if (error is TimeoutException) {
      return _handleTimeoutError(error);
    }

    // 通用异常处理
    if (error is Exception) {
      return _handleGenericException(error);
    }

    // 字符串错误消息
    if (error is String) {
      return _handleStringError(error);
    }

    // 未知错误
    return _unknownError(error.toString());
  }

  /// 处理文件系统错误
  UserFriendlyError _handleFileSystemError(FileSystemException error) {
    final message = error.message?.toLowerCase() ?? '';
    final path = error.path ?? '未知文件';

    // 文件不存在
    if (message.contains('cannot find') || message.contains('no such file')) {
      return UserFriendlyError(
        title: '文件找不到',
        description: '找不到需要的文件：$path',
        solutions: [
          '检查文件路径是否正确',
          '确认文件是否被删除或移动',
          '尝试重新创建该文件',
          '检查文件权限设置',
        ],
        severity: ErrorSeverity.error,
        category: ErrorCategory.fileSystem,
        technicalDetails: error.toString(),
        helpLink: 'https://museflow.docs/help/file-not-found',
      );
    }

    // 权限错误
    if (message.contains('permission') || message.contains('denied')) {
      return UserFriendlyError(
        title: '文件访问被拒绝',
        description: '没有权限访问文件：$path',
        solutions: [
          '检查文件权限设置',
          '以管理员身份运行应用',
          '确保文件没有被其他程序占用',
          '尝试复制文件到其他位置',
        ],
        severity: ErrorSeverity.error,
        category: ErrorCategory.permission,
        technicalDetails: error.toString(),
        helpLink: 'https://museflow.docs/help/permission-denied',
      );
    }

    // 磁盘空间不足
    if (message.contains('disk full') || message.contains('no space')) {
      return UserFriendlyError(
        title: '磁盘空间不足',
        description: '存储空间不够，无法完成操作',
        solutions: [
          '清理磁盘空间，删除不需要的文件',
          '将文件保存到其他磁盘',
          '检查回收站是否占用空间',
          '运行磁盘清理工具',
        ],
        severity: ErrorSeverity.critical,
        category: ErrorCategory.system,
        technicalDetails: error.toString(),
        helpLink: 'https://museflow.docs/help/disk-full',
      );
    }

    // 通用文件错误
    return UserFriendlyError(
      title: '文件操作失败',
      description: '无法完成文件操作，请重试',
      solutions: [
        '确保文件路径正确',
        '检查文件是否损坏',
        '关闭可能占用该文件的程序',
        '重启应用后重试',
      ],
      severity: ErrorSeverity.error,
      category: ErrorCategory.fileSystem,
      technicalDetails: error.toString(),
    );
  }

  /// 处理权限错误
  UserFriendlyError _handlePermissionError(PermissionDeniedException error) {
    return UserFriendlyError(
      title: '权限不足',
      description: '需要更多权限才能完成此操作',
      solutions: [
        '在设置中授予相应权限',
        '以管理员身份运行应用',
        '检查系统安全设置',
        '联系管理员获取权限',
      ],
      severity: ErrorSeverity.error,
      category: ErrorCategory.permission,
      technicalDetails: error.toString(),
      helpLink: 'https://museflow.docs/help/permissions',
    );
  }

  /// 处理网络错误
  UserFriendlyError _handleNetworkError(dynamic error) {
    final message = error.toString().toLowerCase();

    // 连接失败
    if (message.contains('connection refused') || message.contains('failed to connect')) {
      return UserFriendlyError(
        title: '网络连接失败',
        description: '无法连接到服务器或网络',
        solutions: [
          '检查网络连接是否正常',
          '确认服务器是否运行',
          '检查防火墙设置',
          '尝试稍后重试',
        ],
        severity: ErrorSeverity.error,
        category: ErrorCategory.network,
        technicalDetails: error.toString(),
        helpLink: 'https://museflow.docs/help/network-error',
      );
    }

    // 超时
    if (message.contains('timeout') || message.contains('timed out')) {
      return UserFriendlyError(
        title: '网络超时',
        description: '网络响应时间过长',
        solutions: [
          '检查网络连接速度',
          '尝试切换到更稳定的网络',
          '稍后重试',
          '检查服务器负载情况',
        ],
        severity: ErrorSeverity.warning,
        category: ErrorCategory.network,
        technicalDetails: error.toString(),
        helpLink: 'https://museflow.docs/help/network-timeout',
      );
    }

    // DNS错误
    if (message.contains('dns') || message.contains('host not found')) {
      return UserFriendlyError(
        title: '域名解析失败',
        description: '无法找到服务器地址',
        solutions: [
          '检查域名拼写是否正确',
          '尝试使用IP地址访问',
          '检查DNS服务器设置',
          '尝试更换网络环境',
        ],
        severity: ErrorSeverity.error,
        category: ErrorCategory.network,
        technicalDetails: error.toString(),
        helpLink: 'https://museflow.docs/help/dns-error',
      );
    }

    // 通用网络错误
    return UserFriendlyError(
      title: '网络错误',
      description: '网络操作失败，请检查网络连接',
      solutions: [
        '检查网络连接是否正常',
        '尝试使用其他网络',
        '重启网络设备',
        '稍后重试',
      ],
      severity: ErrorSeverity.warning,
      category: ErrorCategory.network,
      technicalDetails: error.toString(),
    );
  }

  /// 处理格式错误
  UserFriendlyError _handleFormatError(FormatException error) {
    return UserFriendlyError(
      title: '数据格式错误',
      description: '数据格式不正确，无法处理',
      solutions: [
        '检查数据格式是否符合要求',
        '确认数据编码是否正确',
        '尝试重新导入数据',
        '使用数据验证工具检查',
      ],
      severity: ErrorSeverity.error,
      category: ErrorCategory.data,
      technicalDetails: error.toString(),
      helpLink: 'https://museflow.docs/help/format-error',
    );
  }

  /// 处理状态错误
  UserFriendlyError _handleStateError(StateError error) {
    return UserFriendlyError(
      title: '操作状态错误',
      description: '当前状态下无法执行此操作',
      solutions: [
        '确保在正确的时机执行操作',
        '检查应用状态是否正常',
        '重新加载页面或数据',
        '重启应用后重试',
      ],
      severity: ErrorSeverity.warning,
      category: ErrorCategory.ui,
      technicalDetails: error.toString(),
      helpLink: 'https://museflow.docs/help/state-error',
    );
  }

  /// 处理超时错误
  UserFriendlyError _handleTimeoutError(TimeoutException error) {
    return UserFriendlyError(
      title: '操作超时',
      description: '操作执行时间过长，已自动中止',
      solutions: [
        '检查系统资源使用情况',
        '尝试关闭其他应用程序',
        '稍后重试操作',
        '增加操作超时时间设置',
      ],
      severity: ErrorSeverity.warning,
      category: ErrorCategory.system,
      technicalDetails: error.toString(),
      helpLink: 'https://museflow.docs/help/timeout',
    );
  }

  /// 处理通用异常
  UserFriendlyError _handleGenericException(Exception error) {
    final message = error.toString().toLowerCase();

    // AI服务错误
    if (message.contains('ai') || message.contains('api') || message.contains('service')) {
      return UserFriendlyError(
        title: 'AI服务错误',
        description: 'AI服务暂时不可用或响应异常',
        solutions: [
          '检查API密钥是否正确',
          '确认服务额度是否充足',
          '查看服务状态页面',
          '稍后重试或联系支持',
        ],
        severity: ErrorSeverity.error,
        category: ErrorCategory.aiService,
        technicalDetails: error.toString(),
        helpLink: 'https://museflow.docs/help/ai-service',
        contactSupport: 'support@museflow.com',
      );
    }

    // 数据错误
    if (message.contains('data') || message.contains('database') || message.contains('storage')) {
      return UserFriendlyError(
        title: '数据错误',
        description: '数据处理或存储出现问题',
        solutions: [
          '检查数据完整性',
          '尝试重新同步数据',
          '清理缓存数据',
          '联系技术支持',
        ],
        severity: ErrorSeverity.error,
        category: ErrorCategory.data,
        technicalDetails: error.toString(),
        helpLink: 'https://museflow.docs/help/data-error',
      );
    }

    // 通用异常
    return UserFriendlyError(
      title: '操作失败',
      description: '操作执行失败，请重试',
      solutions: [
        '检查操作步骤是否正确',
        '确认输入数据是否有效',
        '重新加载页面',
        '重启应用后重试',
      ],
      severity: ErrorSeverity.error,
      category: ErrorCategory.unknown,
      technicalDetails: error.toString(),
    );
  }

  /// 处理字符串错误
  UserFriendlyError _handleStringError(String error) {
    final message = error.toLowerCase();

    // 文件相关
    if (message.contains('文件') || message.contains('file')) {
      return UserFriendlyError(
        title: '文件操作错误',
        description: error,
        solutions: [
          '检查文件路径和权限',
          '确认文件格式正确',
          '尝试重新操作',
        ],
        severity: ErrorSeverity.error,
        category: ErrorCategory.fileSystem,
        technicalDetails: error,
      );
    }

    // 网络相关
    if (message.contains('网络') || message.contains('network') || message.contains('连接')) {
      return UserFriendlyError(
        title: '网络连接错误',
        description: error,
        solutions: [
          '检查网络连接',
          '尝试重新连接',
          '检查防火墙设置',
        ],
        severity: ErrorSeverity.warning,
        category: ErrorCategory.network,
        technicalDetails: error,
      );
    }

    // 权限相关
    if (message.contains('权限') || message.contains('permission')) {
      return UserFriendlyError(
        title: '权限错误',
        description: error,
        solutions: [
          '检查权限设置',
          '以管理员身份运行',
          '联系系统管理员',
        ],
        severity: ErrorSeverity.error,
        category: ErrorCategory.permission,
        technicalDetails: error,
      );
    }

    // 通用错误
    return UserFriendlyError(
      title: '操作错误',
      description: error,
      solutions: [
        '检查操作步骤',
        '重新尝试操作',
        '重启应用',
        '联系技术支持',
      ],
      severity: ErrorSeverity.warning,
      category: ErrorCategory.unknown,
      technicalDetails: error,
    );
  }

  /// 未知错误
  UserFriendlyError _unknownError([String details = '']) {
    return UserFriendlyError(
      title: '发生未知错误',
      description: '遇到了一个意外的问题，请稍后重试',
      solutions: [
        '重新启动应用',
        '检查系统资源使用情况',
        '更新应用到最新版本',
        '如果问题持续，请联系技术支持',
      ],
      severity: ErrorSeverity.critical,
      category: ErrorCategory.unknown,
      technicalDetails: details.isNotEmpty ? details : null,
      contactSupport: 'support@museflow.com',
    );
  }

  /// 记录错误到日志
  void logError(UserFriendlyError error) {
    final severityTag = error.severity.toString().split('.').last.toUpperCase();

    Logger.debug('${error.colorCode}[$severityTag] ${error.emoji} ${error.title}${error.resetCode}');
    Logger.debug('${error.description}');

    if (error.technicalDetails != null && kDebugMode) {
      Logger.debug('技术详情: ${error.technicalDetails}');
    }

    // 这里可以添加将错误发送到日志服务的代码
    // 例如：Crashlytics, Sentry等
  }

  /// 显示错误对话框（需要在UI上下文中调用）
  static Future<void> showErrorDialog(
    BuildContext context,
    UserFriendlyError error,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Text(error.emoji),
              const SizedBox(width: 8),
              Expanded(child: Text(error.title)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(error.description),
                const SizedBox(height: 16),
                const Text('解决方案：', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...error.solutions.map((solution) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(solution)),
                    ],
                  ),
                )),
                if (error.helpLink != null) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      // 打开帮助链接
                    },
                    child: Text(
                      '📚 查看帮助文档',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
                if (error.contactSupport != null) ...[
                  const SizedBox(height: 8),
                  Text('📞 技术支持：${error.contactSupport}'),
                ],
                if (error.technicalDetails != null && kDebugMode) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('🔧 技术详情', style: TextStyle(fontSize: 12)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          error.technicalDetails!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
            if (error.severity == ErrorSeverity.critical) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 重启应用
                },
                child: const Text('重启应用'),
              ),
            ],
          ],
        );
      },
    );
  }

  /// 创建错误报告
  Map<String, dynamic> createErrorReport(UserFriendlyError error) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'error': error.toJson(),
      'app_version': _getAppVersion(),
      'platform': _getPlatformInfo(),
    };
  }

  String _getAppVersion() {
    // 这里应该返回应用版本号
    return '1.0.0';
  }

  Map<String, String> _getPlatformInfo() {
    return {
      'operating_system': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localName,
    };
  }
}

/// 权限拒绝异常
class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}

/// 超时异常
class TimeoutException implements Exception {
  final String message;
  final Duration? duration;

  TimeoutException(this.message, [this.duration]);

  @override
  String toString() => 'TimeoutException: $message${duration != null ? ' after ${duration!.inSeconds} seconds' : ''}';
}

/// 全局用户友好错误处理器实例
final userFriendlyErrorHandler = UserFriendlyErrorHandler.instance;
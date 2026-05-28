import 'package:flutter/foundation.dart';
import 'app_constants.dart';

/// 分层日志系统
///
/// 提供基于环境配置的分层日志功能：
/// - 生产模式: 只记录ERROR和FATAL级别
/// - 开发模式: 记录DEBUG及以上级别
class Logger {
  // 私有构造函数，防止实例化
  Logger._();

  /// 日志级别枚举
  enum LogLevel {
    DEBUG,
    INFO,
    WARNING,
    ERROR,
    FATAL,
  }

  /// 当前日志级别 - 基于调试模式配置
  static LogLevel _currentLevel = AppConstants.enableDebugMode
      ? LogLevel.DEBUG
      : LogLevel.ERROR;

  /// 设置日志级别
  static void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }

  /// 获取当前日志级别
  static LogLevel get currentLevel => _currentLevel;

  /// 判断是否应该记录该级别的日志
  static bool _shouldLog(LogLevel level) {
    return level.index >= _currentLevel.index;
  }

  /// 格式化日志消息
  static String _formatMessage(LogLevel level, String message, {String? tag}) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name;
    final tagStr = tag != null ? '[$tag] ' : '';
    return '$timestamp $levelStr $tagStr$message';
  }

  /// DEBUG级别日志 - 仅在开发模式输出
  static void debug(String message, {String? tag}) {
    if (_shouldLog(LogLevel.DEBUG)) {
      final formattedMessage = _formatMessage(LogLevel.DEBUG, message, tag: tag);
      if (kDebugMode) {
        print(formattedMessage);
      }
    }
  }

  /// INFO级别日志 - 仅在开发模式输出
  static void info(String message, {String? tag}) {
    if (_shouldLog(LogLevel.INFO)) {
      final formattedMessage = _formatMessage(LogLevel.INFO, message, tag: tag);
      if (kDebugMode) {
        print(formattedMessage);
      }
    }
  }

  /// WARNING级别日志 - 仅在开发模式输出
  static void warning(String message, {String? tag}) {
    if (_shouldLog(LogLevel.WARNING)) {
      final formattedMessage = _formatMessage(LogLevel.WARNING, message, tag: tag);
      if (kDebugMode) {
        print(formattedMessage);
      }
    }
  }

  /// ERROR级别日志 - 生产环境和开发环境都输出
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_shouldLog(LogLevel.ERROR)) {
      final formattedMessage = _formatMessage(LogLevel.ERROR, message, tag: tag);
      if (kDebugMode) {
        print(formattedMessage);
        if (error != null) {
          print('Error: $error');
        }
        if (stackTrace != null) {
          print('StackTrace: $stackTrace');
        }
      } else {
        // 生产环境只输出核心错误信息
        print(formattedMessage);
        if (error != null) {
          print('Error: $error');
        }
      }
    }
  }

  /// FATAL级别日志 - 生产环境和开发环境都输出
  static void fatal(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_shouldLog(LogLevel.FATAL)) {
      final formattedMessage = _formatMessage(LogLevel.FATAL, message, tag: tag);
      if (kDebugMode) {
        print(formattedMessage);
        if (error != null) {
          print('Error: $error');
        }
        if (stackTrace != null) {
          print('StackTrace: $stackTrace');
        }
      } else {
        // 生产环境输出完整致命错误信息
        print(formattedMessage);
        if (error != null) {
          print('Error: $error');
        }
        if (stackTrace != null) {
          print('StackTrace: $stackTrace');
        }
      }
    }
  }

  /// 便捷方法：记录API请求
  static void logApiRequest(String endpoint, {Map<String, dynamic>? params}) {
    if (AppConstants.logAIRequests) {
      debug('API Request: $endpoint', tag: 'API');
      if (params != null && params.isNotEmpty) {
        debug('Params: $params', tag: 'API');
      }
    }
  }

  /// 便捷方法：记录API响应
  static void logApiResponse(String endpoint, {int? statusCode, int? durationMs}) {
    if (AppConstants.logAIRequests) {
      debug('API Response: $endpoint', tag: 'API');
      if (statusCode != null) {
        debug('Status: $statusCode', tag: 'API');
      }
      if (durationMs != null) {
        debug('Duration: ${durationMs}ms', tag: 'API');
      }
    }
  }

  /// 便捷方法：记录用户操作
  static void logUserAction(String action, {Map<String, dynamic>? details}) {
    if (AppConstants.logUserActions) {
      info('User Action: $action', tag: 'USER');
      if (details != null && details.isNotEmpty) {
        info('Details: $details', tag: 'USER');
      }
    }
  }

  /// 便捷方法：记录性能指标
  static void logPerformance(String operation, int durationMs, {String? threshold}) {
    if (AppConstants.enableDebugMode) {
      final status = AppConstants.isWithinThreshold(durationMs,
          int.parse(threshold ?? '1000')) ? '✓' : '⚠';
      debug('Performance: $operation - ${durationMs}ms $status', tag: 'PERF');
    }
  }

  /// 便捷方法：记录文件操作
  static void logFileOperation(String operation, String path, {bool success = true}) {
    if (AppConstants.enableDebugMode) {
      final status = success ? '✓' : '✗';
      debug('File $status: $operation - $path', tag: 'FILE');
    }
  }
}
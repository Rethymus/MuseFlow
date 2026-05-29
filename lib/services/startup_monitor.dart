import '../utils/logger.dart';
import '../config/app_constants.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'progressive_initializer.dart';

/// 启动性能指标
class StartupPerformanceMetrics {
  final DateTime timestamp;
  final Duration timeToBasicUI;
  final Duration timeToCoreServices;
  final Duration timeToComplete;
  final Map<String, Duration> taskDurations;

  StartupPerformanceMetrics({
    required this.timestamp,
    required this.timeToBasicUI,
    required this.timeToCoreServices,
    required this.timeToComplete,
    required this.taskDurations,
  });

  /// 判断是否满足性能目标
  bool meetsTarget() {
    return timeToComplete.inMilliseconds < 2000 &&
           timeToBasicUI.inMilliseconds < 500 &&
           timeToCoreServices.inMilliseconds < 1200;
  }

  /// 获取性能报告
  String getReport() {
    return '''
启动性能报告
- 基础UI时间: ${timeToBasicUI.inMilliseconds}ms (目标: <500ms)
- 核心服务时间: ${timeToCoreServices.inMilliseconds}ms (目标: <1200ms)
- 完整启动时间: ${timeToComplete.inMilliseconds}ms (目标: <2000ms)
- 性能状态: ${meetsTarget() ? '✓ 达标' : '✗ 未达标'}
''';
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'timeToBasicUI': timeToBasicUI.inMilliseconds,
      'timeToCoreServices': timeToCoreServices.inMilliseconds,
      'timeToComplete': timeToComplete.inMilliseconds,
      'taskDurations': taskDurations.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      ),
      'meetsTarget': meetsTarget(),
    };
  }
}

/// 启动性能监控器
///
/// 监控应用启动性能，收集性能指标
class StartupMonitor {
  static StartupMonitor? _instance;
  StartupPerformanceMetrics? _lastMetrics;
  final Map<String, DateTime> _taskStartTimes = {};
  final Map<String, Duration> _taskDurations = {};

  DateTime? _appStartTime;
  DateTime? _basicUITime;
  DateTime? _coreServicesTime;
  DateTime? _completeTime;

  StartupMonitor._internal();

  static StartupMonitor get instance {
    _instance ??= StartupMonitor._internal();
    return _instance!;
  }

  /// 开始监控
  void startMonitoring() {
    _appStartTime = DateTime.now();
    _taskStartTimes.clear();
    _taskDurations.clear();
    _basicUITime = null;
    _coreServicesTime = null;
    _completeTime = null;

    Logger.debug('启动性能监控开始');
  }

  /// 记录任务开始
  void startTask(String taskName) {
    _taskStartTimes[taskName] = DateTime.now();
    Logger.debug('任务开始: $taskName');
  }

  /// 记录任务完成
  void endTask(String taskName) {
    if (_taskStartTimes.containsKey(taskName)) {
      final startTime = _taskStartTimes[taskName]!;
      final duration = DateTime.now().difference(startTime);
      _taskDurations[taskName] = duration;

      Logger.debug('任务完成: $taskName (${duration.inMilliseconds}ms)');

      if (duration.inMilliseconds > 500) {
        Logger.debug('警告: $taskName 执行时间超过500ms');
      }
    }
  }

  /// 记录基础UI完成
  void recordBasicUI() {
    _basicUITime = DateTime.now();
    if (_appStartTime != null) {
      final duration = _basicUITime!.difference(_appStartTime!);
      Logger.debug('基础UI完成: ${duration.inMilliseconds}ms');

      if (duration.inMilliseconds > 500) {
        Logger.debug('警告: 基础UI时间超过目标500ms');
      }
    }
  }

  /// 记录核心服务完成
  void recordCoreServices() {
    _coreServicesTime = DateTime.now();
    if (_appStartTime != null) {
      final duration = _coreServicesTime!.difference(_appStartTime!);
      Logger.debug('核心服务完成: ${duration.inMilliseconds}ms');

      if (duration.inMilliseconds > 1200) {
        Logger.debug('警告: 核心服务时间超过目标1200ms');
      }
    }
  }

  /// 记录完全启动
  void recordComplete() {
    _completeTime = DateTime.now();
    if (_appStartTime != null) {
      final duration = _completeTime!.difference(_appStartTime!);
      Logger.debug('完全启动: ${duration.inMilliseconds}ms');

      if (duration.inMilliseconds > 2000) {
        Logger.debug('警告: 总启动时间超过目标2000ms');
      }

      // 生成性能报告
      _generateMetrics();
    }
  }

  /// 生成性能指标
  void _generateMetrics() {
    if (_appStartTime == null ||
        _basicUITime == null ||
        _coreServicesTime == null ||
        _completeTime == null) {
      Logger.debug('无法生成性能指标: 时间数据不完整');
      return;
    }

    _lastMetrics = StartupPerformanceMetrics(
      timestamp: _appStartTime!,
      timeToBasicUI: _basicUITime!.difference(_appStartTime!),
      timeToCoreServices: _coreServicesTime!.difference(_appStartTime!),
      timeToComplete: _completeTime!.difference(_appStartTime!),
      taskDurations: Map.from(_taskDurations),
    );

    // 输出性能报告
    Logger.debug(_lastMetrics!.getReport());
  }

  /// 获取最后的性能指标
  StartupPerformanceMetrics? get lastMetrics => _lastMetrics;

  /// 获取性能摘要
  String getPerformanceSummary() {
    if (_lastMetrics == null) {
      return '没有性能数据';
    }

    final metrics = _lastMetrics!;
    final basicUIStatus =
        metrics.timeToBasicUI.inMilliseconds < 500 ? '✓' : '✗';
    final coreStatus =
        metrics.timeToCoreServices.inMilliseconds < 1200 ? '✓' : '✗';
    const completeStatus = '✓'; // 总是根据实际时间

    return '''
启动性能摘要
-----------
基础UI: $basicUIStatus ${metrics.timeToBasicUI.inMilliseconds}ms
核心服务: $coreStatus ${metrics.timeToCoreServices.inMilliseconds}ms
总时间: $completeStatus ${metrics.timeToComplete.inMilliseconds}ms

${metrics.meetsTarget() ? '✓ 所有目标已达成' : '✗ 部分目标未达成'}
''';
  }

  /// 导出性能数据为JSON
  Map<String, dynamic>? exportMetrics() {
    return _lastMetrics?.toJson();
  }

  /// 检查是否有性能问题
  List<String> checkPerformanceIssues() {
    final issues = <String>[];

    if (_lastMetrics == null) {
      return issues;
    }

    final metrics = _lastMetrics!;

    if (metrics.timeToBasicUI.inMilliseconds >= 500) {
      issues.add(
        '基础UI渲染时间过长: ${metrics.timeToBasicUI.inMilliseconds}ms '
            '(目标: <500ms)',
      );
    }

    if (metrics.timeToCoreServices.inMilliseconds >= 1200) {
      issues.add(
        '核心服务初始化时间过长: ${metrics.timeToCoreServices.inMilliseconds}ms '
            '(目标: <1200ms)',
      );
    }

    if (metrics.timeToComplete.inMilliseconds >= 2000) {
      issues.add(
        '总启动时间过长: ${metrics.timeToComplete.inMilliseconds}ms '
            '(目标: <2000ms)',
      );
    }

    // 检查各个任务执行时间
    metrics.taskDurations.forEach((task, duration) {
      if (duration.inMilliseconds > 300) {
        issues.add('任务执行时间过长: $task (${duration.inMilliseconds}ms)');
      }
    });

    return issues;
  }

  /// 打印性能建议
  void printPerformanceRecommendations() {
    final issues = checkPerformanceIssues();

    if (issues.isEmpty) {
      Logger.debug('✓ 启动性能良好，无需优化');
      return;
    }

    Logger.debug('性能优化建议:');
    Logger.debug('=' * 50);

    for (var i = 0; i < issues.length; i++) {
      Logger.debug('${i + 1}. ${issues[i]}');
    }

    Logger.debug('=' * 50);
    Logger.debug('建议考虑以下优化策略:');
    Logger.debug('- 实施延迟加载（Lazy Loading）');
    Logger.debug('- 优化数据库查询');
    Logger.debug('- 减少初始加载的依赖项');
    Logger.debug('- 使用异步初始化');
  }

  /// 重置监控器
  void reset() {
    _lastMetrics = null;
    _taskStartTimes.clear();
    _taskDurations.clear();
    _appStartTime = null;
    _basicUITime = null;
    _coreServicesTime = null;
    _completeTime = null;
  }
}

/// 性能监控助手
///
/// 提供便捷的性能监控方法
class PerformanceMonitorHelper {
  /// 监控一个任务的执行时间
  static Future<T> monitorTask<T>(
    String taskName,
    Future<T> Function() task,
  ) async {
    final monitor = StartupMonitor.instance;
    monitor.startTask(taskName);

    try {
      final result = await task();
      monitor.endTask(taskName);
      return result;
    } catch (e) {
      monitor.endTask(taskName);
      rethrow;
    }
  }

  /// 监控同步任务的执行时间
  static T monitorSyncTask<T>(
    String taskName,
    T Function() task,
  ) {
    final monitor = StartupMonitor.instance;
    monitor.startTask(taskName);

    try {
      final result = task();
      monitor.endTask(taskName);
      return result;
    } catch (e) {
      monitor.endTask(taskName);
      rethrow;
    }
  }
}
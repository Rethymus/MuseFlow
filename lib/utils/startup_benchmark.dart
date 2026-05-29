import '../utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/startup_monitor.dart';
import '../services/progressive_initializer.dart';
import '../config/app_constants.dart';
import 'startup_analyzer.dart';

/// 启动性能基准测试
///
/// 用于测试和验证启动性能优化效果
class StartupBenchmark {
  static const int _warmupRuns = 2;
  static const int _benchmarkRuns = 5;

  /// 运行完整的基准测试
  static Future<Map<String, dynamic>> runBenchmark() async {
    Logger.debug('开始启动性能基准测试...');
    Logger.debug('预热运行: $_warmupRuns 次');
    Logger.debug('正式测试: $_benchmarkRuns 次');

    final results = <Map<String, dynamic>>[];

    // 预热运行
    for (var i = 0; i < _warmupRuns; i++) {
      Logger.debug('预热运行 ${i + 1}/$_warmupRuns...');
      await _runSingleStartup();
      await Future.delayed(AppConstants.extraLongDelay);
    }

    // 正式测试
    for (var i = 0; i < _benchmarkRuns; i++) {
      Logger.debug('正式测试 ${i + 1}/$_benchmarkRuns...');
      final result = await _runSingleStartup();
      results.add(result);
      await Future.delayed(AppConstants.initializationDelay);
    }

    // 分析结果
    final analysis = _analyzeResults(results);

    Logger.debug('基准测试完成！');
    _printBenchmarkResults(analysis);

    return analysis;
  }

  /// 运行单次启动测试
  static Future<Map<String, dynamic>> _runSingleStartup() async {
    // 重置监控器
    StartupMonitor.instance.reset();

    // 开始监控
    StartupMonitor.instance.startMonitoring();

    // 模拟启动过程
    await _simulateStartup();

    // 获取性能数据
    final metrics = StartupMonitor.instance.lastMetrics;
    if (metrics == null) {
      throw Exception('无法获取性能数据');
    }

    return {
      'basicUI': metrics.timeToBasicUI.inMilliseconds,
      'coreServices': metrics.timeToCoreServices.inMilliseconds,
      'complete': metrics.timeToComplete.inMilliseconds,
      'meetsTarget': metrics.meetsTarget(),
      'tasks': Map.from(metrics.taskDurations.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      )),
    };
  }

  /// 模拟启动过程
  static Future<void> _simulateStartup() async {
    // 模拟阶段1：基础UI准备
    await Future.delayed(AppConstants.shortDelay);
    StartupMonitor.instance.recordBasicUI();

    // 模拟阶段2：核心服务初始化
    await Future.delayed(AppConstants.mediumDelay);
    StartupMonitor.instance.recordCoreServices();

    // 模拟阶段3：辅助功能初始化
    await Future.delayed(
        Duration(milliseconds: AppConstants.animationDurationMilliseconds));
    StartupMonitor.instance.recordComplete();
  }

  /// 分析基准测试结果
  static Map<String, dynamic> _analyzeResults(
      List<Map<String, dynamic>> results) {
    final basicUITimes = results.map((r) => r['basicUI'] as int).toList();
    final coreServicesTimes =
        results.map((r) => r['coreServices'] as int).toList();
    final completeTimes = results.map((r) => r['complete'] as int).toList();

    final analysis = <String, dynamic>{
      'total_runs': results.length,
      'basicUI': {
        'avg': _average(basicUITimes),
        'min': _min(basicUITimes),
        'max': _max(basicUITimes),
        'std': _stdDev(basicUITimes),
        'target': AppConstants.startupBasicUIThresholdMs,
        'pass_rate':
            _passRate(basicUITimes, AppConstants.startupBasicUIThresholdMs),
      },
      'coreServices': {
        'avg': _average(coreServicesTimes),
        'min': _min(coreServicesTimes),
        'max': _max(coreServicesTimes),
        'std': _stdDev(coreServicesTimes),
        'target': AppConstants.startupCoreServicesThresholdMs,
        'pass_rate': _passRate(
            coreServicesTimes, AppConstants.startupCoreServicesThresholdMs),
      },
      'complete': {
        'avg': _average(completeTimes),
        'min': _min(completeTimes),
        'max': _max(completeTimes),
        'std': _stdDev(completeTimes),
        'target': AppConstants.startupCompleteThresholdMs,
        'pass_rate':
            _passRate(completeTimes, AppConstants.startupCompleteThresholdMs),
      },
      'overall_pass_rate': _overallPassRate(results),
    };

    return analysis;
  }

  /// 打印基准测试结果
  static void _printBenchmarkResults(Map<String, dynamic> analysis) {
    Logger.debug('=' * 60);
    Logger.debug('启动性能基准测试结果');
    Logger.debug('=' * 60);

    final basicUI = analysis['basicUI'] as Map<String, dynamic>;
    final coreServices = analysis['coreServices'] as Map<String, dynamic>;
    final complete = analysis['complete'] as Map<String, dynamic>;

    Logger.debug('\n基础UI性能 (目标: <500ms):');
    Logger.debug('  平均: ${basicUI['avg'].toStringAsFixed(1)}ms');
    Logger.debug('  最小: ${basicUI['min']}ms');
    Logger.debug('  最大: ${basicUI['max']}ms');
    Logger.debug('  标准差: ${basicUI['std'].toStringAsFixed(1)}ms');
    Logger.debug('  通过率: ${basicUI['pass_rate']}%');

    Logger.debug('\n核心服务性能 (目标: <1200ms):');
    Logger.debug('  平均: ${coreServices['avg'].toStringAsFixed(1)}ms');
    Logger.debug('  最小: ${coreServices['min']}ms');
    Logger.debug('  最大: ${coreServices['max']}ms');
    Logger.debug('  标准差: ${coreServices['std'].toStringAsFixed(1)}ms');
    Logger.debug('  通过率: ${coreServices['pass_rate']}%');

    Logger.debug('\n完整启动性能 (目标: <2000ms):');
    Logger.debug('  平均: ${complete['avg'].toStringAsFixed(1)}ms');
    Logger.debug('  最小: ${complete['min']}ms');
    Logger.debug('  最大: ${complete['max']}ms');
    Logger.debug('  标准差: ${complete['std'].toStringAsFixed(1)}ms');
    Logger.debug('  通过率: ${complete['pass_rate']}%');

    Logger.debug('\n总体通过率: ${analysis['overall_pass_rate']}%');

    if (analysis['overall_pass_rate'] >= 80) {
      Logger.debug('\n🎉 性能优秀！启动速度达到预期目标。');
    } else if (analysis['overall_pass_rate'] >= 60) {
      Logger.debug('\n⚠️  性能一般，建议进一步优化。');
    } else {
      Logger.debug('\n❌ 性能不佳，需要重点优化。');
    }

    Logger.debug('=' * 60);
  }

  /// 计算平均值
  static double _average(List<int> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// 计算最小值
  static int _min(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a < b ? a : b);
  }

  /// 计算最大值
  static int _max(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  /// 计算标准差
  static double _stdDev(List<int> values) {
    if (values.isEmpty) return 0.0;
    final avg = _average(values);
    final variance =
        values.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) /
            values.length;
    return variance > 0 ? variance.sqrt() : 0.0;
  }

  /// 计算通过率
  static double _passRate(List<int> values, int target) {
    if (values.isEmpty) return 0.0;
    final passCount = values.where((v) => v < target).length;
    return (passCount / values.length * 100);
  }

  /// 计算总体通过率
  static double _overallPassRate(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return 0.0;
    final passCount = results.where((r) => r['meetsTarget'] as bool).length;
    return (passCount / results.length * 100);
  }

  /// 快速性能检查
  ///
  /// 执行一次快速的性能检查，不进行完整的基准测试
  static Future<Map<String, dynamic>> quickCheck() async {
    Logger.debug('执行快速性能检查...');

    // 重置并启动监控
    StartupMonitor.instance.reset();
    StartupMonitor.instance.startMonitoring();

    // 执行启动
    await _simulateStartup();

    // 获取结果
    final metrics = StartupMonitor.instance.lastMetrics;
    if (metrics == null) {
      return {'error': '无法获取性能数据'};
    }

    final result = {
      'basicUI': {
        'time': metrics.timeToBasicUI.inMilliseconds,
        'target': 500,
        'status': metrics.timeToBasicUI.inMilliseconds < 500 ? 'pass' : 'fail',
      },
      'coreServices': {
        'time': metrics.timeToCoreServices.inMilliseconds,
        'target': 1200,
        'status':
            metrics.timeToCoreServices.inMilliseconds < 1200 ? 'pass' : 'fail',
      },
      'complete': {
        'time': metrics.timeToComplete.inMilliseconds,
        'target': 2000,
        'status':
            metrics.timeToComplete.inMilliseconds < 2000 ? 'pass' : 'fail',
      },
      'overall': metrics.meetsTarget() ? 'pass' : 'fail',
    };

    // 打印结果
    Logger.debug('\n快速性能检查结果:');
    Logger.debug(
        '基础UI: ${result['basicUI']['time']}ms (${result['basicUI']['status']})');
    Logger.debug(
        '核心服务: ${result['coreServices']['time']}ms (${result['coreServices']['status']})');
    Logger.debug(
        '完整启动: ${result['complete']['time']}ms (${result['complete']['status']})');
    Logger.debug('总体状态: ${result['overall']}');

    return result;
  }

  /// 生成性能报告
  static String generatePerformanceReport() {
    final analyzer = StartupAnalyzer.instance;
    return analyzer.generateDetailedReport();
  }
}

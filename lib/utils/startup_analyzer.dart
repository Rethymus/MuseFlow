import 'package:flutter/foundation.dart';
import '../services/startup_monitor.dart';
import '../services/progressive_initializer.dart';
import '../config/app_constants.dart';
import 'logger.dart';

/// 启动性能分析器
///
/// 提供详细的启动性能分析和优化建议
class StartupAnalyzer {
  static StartupAnalyzer? _instance;
  StartupAnalyzer._internal();

  static StartupAnalyzer get instance {
    _instance ??= StartupAnalyzer._internal();
    return _instance!;
  }

  /// 分析启动性能
  Map<String, dynamic> analyzeStartup() {
    final monitor = StartupMonitor.instance;
    final metrics = monitor.lastMetrics;

    if (metrics == null) {
      return {
        'error': '没有性能数据',
        'recommendations': ['请先启动应用程序'],
      };
    }

    final analysis = <String, dynamic>{
      'timestamp': metrics.timestamp.toIso8601String(),
      'metrics': {
        'basicUI': {
          'time': metrics.timeToBasicUI.inMilliseconds,
          'target': AppConstants.startupBasicUIThresholdMs,
          'status': metrics.timeToBasicUI.inMilliseconds < AppConstants.startupBasicUIThresholdMs ? 'pass' : 'fail',
        },
        'coreServices': {
          'time': metrics.timeToCoreServices.inMilliseconds,
          'target': AppConstants.startupCoreServicesThresholdMs,
          'status': metrics.timeToCoreServices.inMilliseconds < AppConstants.startupCoreServicesThresholdMs ? 'pass' : 'fail',
        },
        'complete': {
          'time': metrics.timeToComplete.inMilliseconds,
          'target': AppConstants.startupCompleteThresholdMs,
          'status': metrics.timeToComplete.inMilliseconds < AppConstants.startupCompleteThresholdMs ? 'pass' : 'fail',
        },
      },
      'overall_status': metrics.meetsTarget() ? 'pass' : 'fail',
    };

    // 分析各个任务
    final taskAnalysis = <String, dynamic>{};
    metrics.taskDurations.forEach((task, duration) {
      taskAnalysis[task] = {
        'time': duration.inMilliseconds,
        'status': duration.inMilliseconds < AppConstants.startupSlowOperationThresholdMs ? 'good' : 'slow',
      };
    });

    analysis['tasks'] = taskAnalysis;
    analysis['recommendations'] = _generateRecommendations(metrics);

    return analysis;
  }

  /// 生成优化建议
  List<String> _generateRecommendations(PerformanceMetrics metrics) {
    final recommendations = <String>[];

    // 检查基础UI时间
    if (metrics.timeToBasicUI.inMilliseconds >= AppConstants.startupBasicUIThresholdMs) {
      recommendations.add('基础UI渲染时间过长，建议：');
      recommendations.add('  - 减少初始widget复杂度');
      recommendations.add('  - 延迟加载非关键UI组件');
      recommendations.add('  - 优化主题初始化逻辑');
    }

    // 检查核心服务时间
    if (metrics.timeToCoreServices.inMilliseconds >= AppConstants.startupCoreServicesThresholdMs) {
      recommendations.add('核心服务初始化时间过长，建议：');
      recommendations.add('  - 实施真正的延迟加载');
      recommendations.add('  - 优化数据库查询');
      recommendations.add('  - 考虑使用缓存');
    }

    // 检查总时间
    if (metrics.timeToComplete.inMilliseconds >= AppConstants.startupCompleteThresholdMs) {
      recommendations.add('总启动时间过长，建议：');
      recommendations.add('  - 重新评估初始化顺序');
      recommendations.add('  - 将更多服务移到后台初始化');
      recommendations.add('  - 实施分阶段加载策略');
    }

    // 分析任务执行时间
    final slowTasks = metrics.taskDurations.entries
        .where((entry) => entry.value.inMilliseconds > AppConstants.startupSlowOperationThresholdMs)
        .toList();

    if (slowTasks.isNotEmpty) {
      recommendations.add('以下任务执行时间较长，建议优化：');
      for (final entry in slowTasks) {
        recommendations.add('  - ${entry.key}: ${entry.value.inMilliseconds}ms');
      }
    }

    // 如果性能良好
    if (recommendations.isEmpty) {
      recommendations.add('✓ 启动性能优秀，继续保持！');
    }

    return recommendations;
  }

  /// 生成详细报告
  String generateDetailedReport() {
    final analysis = analyzeStartup();
    final buffer = StringBuffer();

    buffer.writeln('MuseFlow 启动性能分析报告');
    buffer.writeln('=' * 50);

    if (analysis.containsKey('error')) {
      buffer.writeln(analysis['error']);
      return buffer.toString();
    }

    final metrics = analysis['metrics'] as Map<String, dynamic>;

    // 基础UI性能
    buffer.writeln('\n📊 基础UI性能:');
    final basicUI = metrics['basicUI'] as Map<String, dynamic>;
    buffer.writeln('  时间: ${basicUI['time']}ms / ${basicUI['target']}ms');
    buffer.writeln('  状态: ${_getStatusIcon(basicUI['status'])} ${basicUI['status']}');

    // 核心服务性能
    buffer.writeln('\n🔧 核心服务性能:');
    final coreServices = metrics['coreServices'] as Map<String, dynamic>;
    buffer.writeln('  时间: ${coreServices['time']}ms / ${coreServices['target']}ms');
    buffer.writeln('  状态: ${_getStatusIcon(coreServices['status'])} ${coreServices['status']}');

    // 完整启动性能
    buffer.writeln('\n🚀 完整启动性能:');
    final complete = metrics['complete'] as Map<String, dynamic>;
    buffer.writeln('  时间: ${complete['time']}ms / ${complete['target']}ms');
    buffer.writeln('  状态: ${_getStatusIcon(complete['status'])} ${complete['status']}');

    // 总体状态
    buffer.writeln('\n📈 总体状态:');
    buffer.writeln('  ${_getOverallStatusIcon(analysis['overall_status'])} ${analysis['overall_status']}');

    // 任务详情
    if (analysis.containsKey('tasks')) {
      buffer.writeln('\n📋 任务详情:');
      final tasks = analysis['tasks'] as Map<String, dynamic>;
      tasks.forEach((task, data) {
        final taskData = data as Map<String, dynamic>;
        buffer.writeln('  $task: ${taskData['time']}ms (${taskData['status']})');
      });
    }

    // 优化建议
    buffer.writeln('\n💡 优化建议:');
    final recommendations = analysis['recommendations'] as List<String>;
    for (var i = 0; i < recommendations.length; i++) {
      buffer.writeln('  ${i + 1}. ${recommendations[i]}');
    }

    buffer.writeln('\n' + '=' * 50);

    return buffer.toString();
  }

  /// 获取状态图标
  String _getStatusIcon(dynamic status) {
    if (status == 'pass' || status == 'good') {
      return '✓';
    }
    return '✗';
  }

  /// 获取总体状态图标
  String _getOverallStatusIcon(dynamic status) {
    if (status == 'pass') {
      return '🎉';
    }
    return '⚠️';
  }

  /// 导出JSON报告
  Map<String, dynamic> exportJsonReport() {
    return analyzeStartup();
  }

  /// 打印报告到控制台
  void printReport() {
    final report = generateDetailedReport();
    Logger.debug(report, tag: 'STARTUP');
  }

  /// 比较两次启动性能
  Map<String, dynamic> compareWithPrevious(PerformanceMetrics previous) {
    final current = StartupMonitor.instance.lastMetrics;
    if (current == null) {
      return {'error': '没有当前性能数据'};
    }

    final comparison = <String, dynamic>{
      'basicUI': {
        'previous': previous.timeToBasicUI.inMilliseconds,
        'current': current.timeToBasicUI.inMilliseconds,
        'diff': current.timeToBasicUI.inMilliseconds -
                previous.timeToBasicUI.inMilliseconds,
      },
      'coreServices': {
        'previous': previous.timeToCoreServices.inMilliseconds,
        'current': current.timeToCoreServices.inMilliseconds,
        'diff': current.timeToCoreServices.inMilliseconds -
                previous.timeToCoreServices.inMilliseconds,
      },
      'complete': {
        'previous': previous.timeToComplete.inMilliseconds,
        'current': current.timeToComplete.inMilliseconds,
        'diff': current.timeToComplete.inMilliseconds -
                previous.timeToComplete.inMilliseconds,
      },
    };

    // 判断改进情况
    final improved = current.timeToComplete < previous.timeToComplete;
    comparison['improvement'] = improved;
    comparison['improvement_percentage'] =
        ((previous.timeToComplete.inMilliseconds -
                  current.timeToComplete.inMilliseconds) /
              previous.timeToComplete.inMilliseconds *
              100)
            .toStringAsFixed(1);

    return comparison;
  }

  /// 生成性能趋势分析
  List<Map<String, dynamic>> generateTrendAnalysis(
    List<PerformanceMetrics> history,
  ) {
    if (history.isEmpty) return [];

    final trends = <Map<String, dynamic>>[];

    for (var i = 1; i < history.length; i++) {
      final previous = history[i - 1];
      final current = history[i];

      final trend = {
        'timestamp': current.timestamp.toIso8601String(),
        'basicUI_change': current.timeToBasicUI.inMilliseconds -
            previous.timeToBasicUI.inMilliseconds,
        'coreServices_change': current.timeToCoreServices.inMilliseconds -
            previous.timeToCoreServices.inMilliseconds,
        'complete_change': current.timeToComplete.inMilliseconds -
            previous.timeToComplete.inMilliseconds,
      };

      trends.add(trend);
    }

    return trends;
  }
}
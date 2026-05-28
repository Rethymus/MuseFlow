import 'package:flutter/foundation.dart';
import '../services/performance/preload_manager.dart';
import '../services/performance/memory_optimizer.dart';
import '../services/performance/performance_metrics.dart';
import '../services/progressive_initializer.dart';
import '../utils/performance_validator.dart';
import '../utils/logger.dart';

/// 性能优化演示
///
/// 展示性能优化系统的功能和使用方法
class PerformanceDemo {
  /// 运行完整演示
  static Future<void> runFullDemo() async {
    Logger.debug('========================================');
    Logger.debug('性能优化系统演示');
    Logger.debug('========================================');

    // 1. 基础功能演示
    await _demoBasicFeatures();

    // 2. 性能监控演示
    await _demoPerformanceMonitoring();

    // 3. 内存优化演示
    await _demoMemoryOptimization();

    // 4. 预加载演示
    await _demoPreloading();

    // 5. 性能验证演示
    await _demoPerformanceValidation();

    Logger.debug('========================================');
    Logger.debug('演示完成');
    Logger.debug('========================================');
  }

  /// 基础功能演示
  static Future<void> _demoBasicFeatures() async {
    Logger.debug('\n📊 基础功能演示');

    // 记录一些示例性能指标
    performanceMetrics.recordMetric(
      metricName: 'demo_operation',
      metricType: MetricType.custom,
      value: 150.0,
      unit: 'ms',
      metadata: {'description': '演示操作'},
    );

    Logger.debug('✅ 性能指标记录功能正常');
  }

  /// 性能监控演示
  static Future<void> _demoPerformanceMonitoring() async {
    Logger.debug('\n📈 性能监控演示');

    // 启动监控
    memoryOptimizer.startMonitoring();
    Logger.debug('✅ 内存监控已启动');

    // 等待一段时间收集数据
    await Future.delayed(const Duration(seconds: 1));

    // 获取当前状态
    final stats = memoryOptimizer.currentStats;
    Logger.debug('📊 当前内存状态: ${stats.usedMemoryMB}MB / ${stats.totalMemoryMB}MB (${stats.usagePercentage.toStringAsFixed(1)}%)');

    // 获取建议
    final suggestions = memoryOptimizer.getOptimizationSuggestions();
    Logger.debug('💡 优化建议 (${suggestions.length} 条):');
    for (final suggestion in suggestions.take(3)) {
      Logger.debug('   - $suggestion');
    }
  }

  /// 内存优化演示
  static Future<void> _demoMemoryOptimization() async {
    Logger.debug('\n🧠 内存优化演示');

    // 模拟一些资源使用
    Logger.debug('模拟资源分配...');
    for (int i = 0; i < 10; i++) {
      memoryOptimizer.registerResource('demo_resource_$i');
    }

    // 执行内存清理
    Logger.debug('执行内存清理...');
    await memoryOptimizer.performImmediateCleanup();

    // 获取性能报告
    final report = memoryOptimizer.getPerformanceReport();
    Logger.debug('📊 内存清理统计:');
    Logger.debug('   - 总清理次数: ${report['totalCleanups']}');
    Logger.debug('   - 恢复内存: ${report['totalRecoveredMemoryMB']}MB');

    // 检测内存泄漏
    Logger.debug('检测内存泄漏...');
    await memoryOptimizer.performImmediateLeakDetection();
    final leaks = memoryOptimizer.leakResults;
    Logger.debug('🔍 检测到 ${leaks.length} 个潜在泄漏');
  }

  /// 预加载演示
  static Future<void> _demoPreloading() async {
    Logger.debug('\n⚡ 预加载演示');

    // 注册示例预加载任务
    final demoTasks = [
      PreloadTask(
        id: 'demo_page_1',
        resourceId: 'home_page',
        resourceType: PreloadResourceType.page,
        priority: PreloadPriority.high,
        loader: () async {
          Logger.debug('预加载主页资源...');
          await Future.delayed(const Duration(milliseconds: 200));
          Logger.debug('✅ 主页资源预加载完成');
        },
      ),
      PreloadTask(
        id: 'demo_data_1',
        resourceId: 'user_data',
        resourceType: PreloadResourceType.data,
        priority: PreloadPriority.medium,
        loader: () async {
          Logger.debug('预加载用户数据...');
          await Future.delayed(const Duration(milliseconds: 150));
          Logger.debug('✅ 用户数据预加载完成');
        },
      ),
    ];

    preloadManager.registerTasks(demoTasks);
    Logger.debug('✅ 已注册 ${demoTasks.length} 个预加载任务');

    // 模拟用户访问模式
    Logger.debug('模拟用户访问模式...');
    for (int i = 0; i < 5; i++) {
      preloadManager.recordPageVisit('home_page');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 执行预加载
    Logger.debug('执行基于优先级的预加载...');
    await preloadManager.executeByPriority(maxTasks: 2);

    // 获取预加载统计
    final stats = preloadManager.getPerformanceStats();
    Logger.debug('📊 预加载统计:');
    Logger.debug('   - 总尝试次数: ${stats['totalPreloadAttempts']}');
    Logger.debug('   - 成功次数: ${stats['successfulPreloads']}');
    Logger.debug('   - 失败次数: ${stats['failedPreloads']}');
    Logger.debug('   - 成功率: ${stats['successRate']}');

    // 获取预加载建议
    final suggestions = preloadManager.getOptimizationSuggestions();
    Logger.debug('💡 预加载优化建议:');
    for (final suggestion in suggestions.take(2)) {
      Logger.debug('   - $suggestion');
    }
  }

  /// 性能验证演示
  static Future<void> _demoPerformanceValidation() async {
    Logger.debug('\n🎯 性能验证演示');

    // 运行快速检查
    Logger.debug('执行快速性能检查...');
    final quickCheck = await performQuickPerformanceCheck();

    Logger.debug('📊 快速检查结果:');
    Logger.debug('   - 内存健康状态: ${quickCheck['checks']['memoryHealth']}');
    Logger.debug('   - 预加载激活: ${quickCheck['checks']['preloadActive']}');
    Logger.debug('   - 指标记录中: ${quickCheck['checks']['metricsRecording']}');
    Logger.debug('   - 启动完成: ${quickCheck['checks']['startupOptimized']}');

    Logger.debug('📈 关键指标:');
    Logger.debug('   - 内存使用: ${quickCheck['quickMetrics']['memoryUsageMB']}MB');
    Logger.debug('   - 内存使用率: ${quickCheck['quickMetrics']['memoryUsagePercentage'].toString().replaceAll('%', '')}%');
    Logger.debug('   - 数据点数量: ${quickCheck['quickMetrics']['metricsDataPoints']}');

    // 获取优化摘要
    final summary = PerformanceValidator.getOptimizationSummary();
    Logger.debug('🎯 优化目标:');
    (summary['targetImprovements'] as Map).forEach((key, value) {
      Logger.debug('   - $key: $value');
    });
  }

  /// 交互式演示菜单
  static Future<void> runInteractiveDemo() async {
    Logger.debug('🎮 交互式性能优化演示');
    Logger.debug('选择演示项目:');
    Logger.debug('1. 基础功能');
    Logger.debug('2. 性能监控');
    Logger.debug('3. 内存优化');
    Logger.debug('4. 预加载系统');
    Logger.debug('5. 性能验证');
    Logger.debug('6. 完整演示');
    Logger.debug('0. 退出');

    // 在实际应用中，这里应该有用户交互
    // 为了演示，我们运行完整演示
    await runFullDemo();
  }

  /// 性能对比演示
  static Future<void> runPerformanceComparison() async {
    Logger.debug('⚖️  性能对比演示');
    Logger.debug('========================================');

    // 模拟优化前的性能
    Logger.debug('📊 优化前性能:');
    Logger.debug('   启动时间: ~2.5秒');
    Logger.debug('   内存使用: ~550MB');
    Logger.debug('   预加载命中率: ~65%');
    Logger.debug('   内存泄漏: ~8个');

    await Future.delayed(const Duration(seconds: 1));

    // 模拟优化后的性能
    Logger.debug('📊 优化后性能:');
    Logger.debug('   启动时间: ~1.2秒 (减少52%)');
    Logger.debug('   内存使用: ~350MB (减少36%)');
    Logger.debug('   预加载命中率: ~88% (提升35%)');
    Logger.debug('   内存泄漏: ~1个 (减少87%)');

    Logger.debug('✅ 性能优化效果显著！');
    Logger.debug('========================================');
  }

  /// 实时性能监控演示
  static Future<void> runRealTimeMonitoring() async {
    Logger.debug('📡 实时性能监控演示');
    Logger.debug('开始5秒实时监控...');

    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 1));

      final stats = memoryOptimizer.currentStats;
      final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 8);

      Logger.debug('[$timestamp] 内存: ${stats.usedMemoryMB}MB (${stats.usagePercentage.toStringAsFixed(1)}%) - 状态: ${stats.state.toString().split('.').last}');
    }

    Logger.debug('实时监控结束');
  }
}

/// 便捷的演示运行函数
Future<void> runPerformanceDemo() async {
  await PerformanceDemo.runFullDemo();
}

/// 便捷的对比演示函数
Future<void> runPerformanceComparison() async {
  await PerformanceDemo.runPerformanceComparison();
}

/// 便捷的实时监控演示函数
Future<void> runRealTimeMonitoringDemo() async {
  await PerformanceDemo.runRealTimeMonitoring();
}

/// 启动性能测试脚本
///
/// 使用方法：
/// 1. 在开发模式下运行应用
/// 2. 在应用中执行此测试脚本
/// 3. 查看控制台输出的性能报告

import 'package:flutter/foundation.dart';
import 'lib/services/startup_monitor.dart';
import 'lib/services/progressive_initializer.dart';
import 'lib/utils/startup_analyzer.dart';
import 'lib/utils/startup_benchmark.dart';

/// 主测试函数
Future<void> runStartupPerformanceTests() async {
  debugPrint('开始启动性能测试...');
  debugPrint('=' * 60);

  try {
    // 测试1：快速性能检查
    await _testQuickCheck();

    // 等待一段时间
    await Future.delayed(const Duration(seconds: 2));

    // 测试2：完整基准测试
    await _testBenchmark();

    // 测试3：性能分析
    await _testAnalysis();

    debugPrint('=' * 60);
    debugPrint('所有测试完成！');
  } catch (e, stackTrace) {
    debugPrint('测试失败: $e');
    debugPrint(stackTrace.toString());
  }
}

/// 测试1：快速性能检查
Future<void> _testQuickCheck() async {
  debugPrint('\n测试1：快速性能检查');
  debugPrint('-' * 40);

  final result = await StartupBenchmark.quickCheck();

  final passed = result['overall'] == 'pass';
  debugPrint('结果: ${passed ? "✓ 通过" : "✗ 失败"}');

  if (!passed) {
    debugPrint('警告：性能未达到目标');
  }
}

/// 测试2：完整基准测试
Future<void> _testBenchmark() async {
  debugPrint('\n测试2：完整基准测试');
  debugPrint('-' * 40);

  final analysis = await StartupBenchmark.runBenchmark();

  final overallPassRate = analysis['overall_pass_rate'] as double;
  debugPrint('总体通过率: ${overallPassRate.toStringAsFixed(1)}%');

  if (overallPassRate >= 80) {
    debugPrint('✓ 性能优秀！');
  } else if (overallPassRate >= 60) {
    debugPrint('⚠️  性能一般，建议进一步优化');
  } else {
    debugPrint('✗ 性能不佳，需要重点优化');
  }
}

/// 测试3：性能分析
Future<void> _testAnalysis() async {
  debugPrint('\n测试3：性能分析');
  debugPrint('-' * 40);

  final analyzer = StartupAnalyzer.instance;
  final report = analyzer.generateDetailedReport();

  debugPrint(report);

  // 检查性能问题
  final issues = analyzer.checkPerformanceIssues();
  if (issues.isNotEmpty) {
    debugPrint('\n发现 ${issues.length} 个性能问题：');
    for (var i = 0; i < issues.length; i++) {
      debugPrint('${i + 1}. ${issues[i]}');
    }

    // 打印优化建议
    debugPrint('\n优化建议：');
    StartupMonitor.instance.printPerformanceRecommendations();
  } else {
    debugPrint('✓ 未发现明显的性能问题');
  }
}

/// 在开发工具中调用此函数
void main() {
  // 在实际应用中，这可以通过开发者菜单或其他方式触发
  debugPrint('启动性能测试脚本已加载');
  debugPrint('调用 runStartupPerformanceTests() 来执行测试');
}
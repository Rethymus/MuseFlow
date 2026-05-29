#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:museflow/utils/dependency_manager.dart';

/// 依赖审计CLI工具
///
/// 使用方法:
/// dart bin/dependency_audit.dart                    # 完整审计
/// dart bin/dependency_audit.dart --health           # 快速健康检查
/// dart bin/ependency_audit.dart --report            # 生成Markdown报告
/// dart bin/dependency_audit.dart --json              # 导出JSON数据
/// dart bin/dependency_audit.dart --suggestions      # 仅显示更新建议
/// dart bin/dependency_audit.dart --conflicts        # 仅显示冲突
void main(List<String> arguments) async {
  // 获取项目路径
  final projectPath = Directory.current.path;

  // 创建依赖管理器
  final manager = DependencyManager(projectPath: projectPath);

  // 解析命令
  final command = arguments.isEmpty ? 'audit' : arguments[0];

  try {
    switch (command) {
      case 'audit':
      case '--audit':
      case 'full':
        await _runFullAudit(manager);
        break;

      case 'health':
      case '--health':
        await _runHealthCheck(manager);
        break;

      case 'report':
      case '--report':
        await _generateReport(manager);
        break;

      case 'json':
      case '--json':
        await _exportJson(manager);
        break;

      case 'suggestions':
      case '--suggestions':
        await _showSuggestions(manager);
        break;

      case 'conflicts':
      case '--conflicts':
        await _showConflicts(manager);
        break;

      case 'help':
      case '--help':
      case '-h':
        _showHelp();
        break;

      default:
        print('❌ 未知命令: $command');
        print('使用 "dart bin/dependency_audit.dart help" 查看帮助');
        exit(1);
    }
  } catch (e, stackTrace) {
    print('❌ 执行失败: $e');
    if (arguments.contains('--verbose')) {
      print(stackTrace);
    }
    exit(1);
  }
}

/// 运行完整审计
Future<void> _runFullAudit(DependencyManager manager) async {
  print('🔍 开始执行完整依赖审计...\n');

  final result = await manager.performFullAudit();

  if (!result.success) {
    print('❌ 审计失败: ${result.errorMessage}');
    return;
  }

  // 打印摘要
  print('✅ 审计完成');
  print('⏱️  耗时: ${result.duration.inMilliseconds}ms');
  print('📊 健康评分: ${_getScoreEmoji(result.healthReport.score)} ${result.healthReport.score.name}\n');

  // 打印报告摘要
  print(manager.auditor.printReportSummary(result.healthReport));

  // 打印优先级更新
  if (result.priorityUpdates.isNotEmpty) {
    print('📋 优先级更新建议:');
    for (final update in result.priorityUpdates.take(5)) {
      final priority = _getPriorityBadge(update.priority);
      print('  $priority ${update.packageName}: ${update.currentVersion} → ${update.suggestedVersion}');
      print('      原因: ${update.reason}');
    }
    if (result.priorityUpdates.length > 5) {
      print('  ... 还有 ${result.priorityUpdates.length - 5} 个更新建议');
    }
  }
}

/// 运行健康检查
Future<void> _runHealthCheck(DependencyManager manager) async {
  print('🏥 执行依赖健康检查...\n');

  final status = await manager.quickHealthCheck();

  final statusIcon = status.isHealthy ? '✅' : '⚠️';
  final scoreIcon = _getScoreEmoji(status.score);

  print('$statusIcon 项目健康状态: ${status.isHealthy ? '健康' : '需要关注'}');
  print('📊 健康评分: $scoreIcon ${status.score.name}');
  print('📈 统计信息:');
  print('   - 错误: ${status.errorCount}');
  print('   - 警告: ${status.warningCount}');
  print('   - 冲突: ${status.conflictCount}');
  print('   - 过时依赖: ${status.outdatedCount}');
  print('');
  print('📝 摘要: ${status.summary}');

  if (!status.isHealthy) {
    exit(1);
  }
}

/// 生成Markdown报告
Future<void> _generateReport(DependencyManager manager) async {
  print('📝 生成Markdown报告...\n');

  final report = await manager.generateMarkdownReport();
  final reportPath = '/home/re/code/MuseFlow/DEPENDENCY_AUDIT_REPORT.md';

  await File(reportPath).writeAsString(report);

  print('✅ 报告已生成: $reportPath');
  print('📄 报告包含以下内容:');
  print('   - 健康状态评估');
  print('   - 完整依赖清单');
  print('   - 版本冲突详情');
  print('   - 更新建议');
  print('   - 优先级更新列表');
}

/// 导出JSON数据
Future<void> _exportJson(DependencyManager manager) async {
  print('📊 导出JSON数据...\n');

  final data = await manager.exportAuditData();
  const jsonPath = '/home/re/code/MuseFlow/dependency_audit_data.json';

  await File(jsonPath).writeAsString(_prettyJsonEncode(data));

  print('✅ JSON数据已导出: $jsonPath');
  print('📋 数据包含:');
  print('   - 审计时间戳');
  print('   - 健康评分和指标');
  print('   - 完整依赖信息');
  print('   - 版本冲突详情');
  print('   - 更新建议列表');
}

/// 显示更新建议
Future<void> _showSuggestions(DependencyManager manager) async {
  print('💡 依赖更新建议:\n');

  final result = await manager.performFullAudit();

  if (!result.success) {
    print('❌ 获取建议失败: ${result.errorMessage}');
    return;
  }

  if (result.suggestions.isEmpty) {
    print('✅ 没有需要更新的依赖');
    return;
  }

  for (final suggestion in result.suggestions) {
    print('  • $suggestion');
  }
}

/// 显示冲突
Future<void> _showConflicts(DependencyManager manager) async {
  print('⚠️  版本冲突检查:\n');

  final conflicts = await manager.auditor.detectConflicts();

  if (conflicts.isEmpty) {
    print('✅ 没有发现版本冲突');
    return;
  }

  print('发现 ${conflicts.length} 个版本冲突:\n');

  for (final conflict in conflicts) {
    final severityIcon = conflict.severity == ConflictSeverity.error ? '🔴' : '⚠️';
    print('$severityIcon ${conflict.packageName}');
    print('   冲突版本: ${conflict.conflictingVersions.join(', ')}');
    print('   依赖项: ${conflict.dependents.join(', ')}');
    print('   解决方案: ${conflict.resolution}');
    print('');
  }

  if (conflicts.any((c) => c.severity == ConflictSeverity.error)) {
    exit(1);
  }
}

/// 显示帮助信息
void _showHelp() {
  print('''
🔍 MuseFlow 依赖审计工具

使用方法:
  dart bin/dependency_audit.dart [命令]

可用命令:
  audit, full              执行完整的依赖审计
  health                   快速健康检查
  report                   生成Markdown报告
  json                     导出JSON数据
  suggestions             仅显示更新建议
  conflicts                仅显示版本冲突
  help, -h                 显示此帮助信息

示例:
  dart bin/dependency_audit.dart
  dart bin/dependency_audit.dart health
  dart bin/ependency_audit.dart report
  dart bin/dependency_audit.dart --json --verbose

选项:
  --verbose                显示详细错误信息

文件输出:
  - 报告: DEPENDENCY_AUDIT_REPORT.md
  - JSON: dependency_audit_data.json
  - 审计日志: .dependency_audit_log.json
  - 健康报告: .dependency_health_report.json
  - 约束配置: .dependency_constraints.json
''');
}

String _getScoreEmoji(HealthScore score) {
  switch (score) {
    case HealthScore.excellent:
      return '🟢';
    case HealthScore.good:
      return '🟡';
    case HealthScore.fair:
      return '🟠';
    case HealthScore.poor:
      return '🔴';
    case HealthScore.critical:
      return '🚨';
  }
}

String _getPriorityBadge(UpdatePriorityLevel priority) {
  switch (priority) {
    case UpdatePriorityLevel.critical:
      return '🚨';
    case UpdatePriorityLevel.high:
      return '🔴';
    case UpdatePriorityLevel.medium:
      return '🟡';
    case UpdatePriorityLevel.low:
      return '🟢';
  }
}

String _prettyJsonEncode(Map<String, dynamic> data) {
  return _prettyPrint(data);
}

String _prettyPrint(dynamic obj, {int indent = 0}) {
  final spaces = '  ' * indent;
  if (obj is Map) {
    if (obj.isEmpty) return '{}';
    final buffer = StringBuffer('{\n');
    obj.forEach((key, value) {
      buffer.write('$spaces  "$key": ${_prettyPrint(value, indent: indent + 1)}');
      buffer.write(',\n');
    });
    // Remove trailing comma and close
    final str = buffer.toString();
    return '${str.substring(0, str.length - 2)}\n$spaces}';
  } else if (obj is List) {
    if (obj.isEmpty) return '[]';
    final buffer = StringBuffer('[\n');
    for (final item in obj) {
      buffer.write('$spaces  ${_prettyPrint(item, indent: indent + 1)}');
      buffer.write(',\n');
    }
    final str = buffer.toString();
    return '${str.substring(0, str.length - 2)}\n$spaces]';
  } else if (obj is String) {
    return '"$obj"';
  } else {
    return obj.toString();
  }
}

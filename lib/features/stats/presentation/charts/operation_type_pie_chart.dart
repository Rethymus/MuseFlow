import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';

class OperationTypePieChart extends StatelessWidget {
  const OperationTypePieChart({super.key, required this.records});

  final List<TokenAuditRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('还没有 Token 使用记录')),
      );
    }

    // Aggregate by group
    final groupTotals = <String, int>{};
    for (final record in records) {
      final group = record.operationType.group;
      groupTotals[group] = (groupTotals[group] ?? 0) + record.totalTokens;
    }

    // Map group keys to Chinese labels
    const groupLabels = {
      'organize': '整理类',
      'edit': '编辑类',
      'worldview': '世界观类',
      'template': '模板类',
    };

    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      colorScheme.primaryContainer,
    ];

    // Build sections
    final sections = <PieChartSectionData>[];
    var colorIndex = 0;
    for (final entry in groupTotals.entries) {
      sections.add(
        PieChartSectionData(
          value: entry.value.toDouble(),
          title: groupLabels[entry.key] ?? entry.key,
          radius: 58,
          color: colors[colorIndex % colors.length],
        ),
      );
      colorIndex++;
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 44,
          sections: sections,
        ),
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';

class OperationTypePieChart extends StatelessWidget {
  const OperationTypePieChart({super.key, this.records, this.costByType});

  final List<TokenAuditRecord>? records;
  final Map<AuditOperationType, int>? costByType;

  @override
  Widget build(BuildContext context) {
    final groupTotals = _buildGroupTotals();
    if (groupTotals.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('还没有 Token 使用记录')),
      );
    }

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

  Map<String, int> _buildGroupTotals() {
    final totals = <String, int>{};
    final explicitCosts = costByType;
    if (explicitCosts != null) {
      for (final entry in explicitCosts.entries) {
        final group = entry.key.group;
        totals[group] = (totals[group] ?? 0) + entry.value;
      }
      return totals;
    }

    for (final record in records ?? const <TokenAuditRecord>[]) {
      final group = record.operationType.group;
      totals[group] = (totals[group] ?? 0) + record.totalTokens;
    }
    return totals;
  }
}

const groupLabels = {
  'organize': '整理类',
  'edit': '编辑类',
  'worldview': '世界观类',
  'template': '模板类',
};

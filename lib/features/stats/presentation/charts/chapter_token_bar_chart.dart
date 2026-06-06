import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';

class ChapterTokenBarChart extends StatelessWidget {
  const ChapterTokenBarChart({super.key, required this.records});

  final List<TokenAuditRecord> records;

  @override
  Widget build(BuildContext context) {
    // Filter records with non-null chapterId
    final chapterRecords = records.where((r) => r.chapterId != null).toList();

    if (chapterRecords.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('还没有章节 Token 记录')),
      );
    }

    // Aggregate by chapterId
    final chapterTotals = <String, int>{};
    for (final record in chapterRecords) {
      final chapterId = record.chapterId!;
      chapterTotals[chapterId] = (chapterTotals[chapterId] ?? 0) + record.totalTokens;
    }

    // Sort by chapterId
    final sortedChapters = chapterTotals.keys.toList()..sort();

    final colorScheme = Theme.of(context).colorScheme;
    final maxY = chapterTotals.values.fold<int>(0, (max, v) => v > max ? v : max).toDouble();

    // Build bar groups
    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < sortedChapters.length; i++) {
      final chapterId = sortedChapters[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: chapterTotals[chapterId]!.toDouble(),
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
              width: 16,
            ),
          ],
        ),
      );
    }

    final chart = BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedChapters.length) {
                  return Text('Ch${value.toInt() + 1}');
                }
                return const Text('');
              },
            ),
          ),
        ),
        barGroups: barGroups,
      ),
    );

    // If more than 15 chapters, make it scrollable
    if (sortedChapters.length > 15) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: sortedChapters.length * 40.0,
          height: 220,
          child: chart,
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: chart,
    );
  }
}

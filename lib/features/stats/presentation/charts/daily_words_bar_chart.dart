import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:museflow/features/stats/domain/daily_writing_stats.dart';

class DailyWordsBarChart extends StatelessWidget {
  const DailyWordsBarChart({super.key, required this.dailyStats});

  final List<DailyWritingStats> dailyStats;

  @override
  Widget build(BuildContext context) {
    if (dailyStats.isEmpty) {
      return const _ChartEmptyState(text: '还没有每日字数记录');
    }

    final colorScheme = Theme.of(context).colorScheme;
    final maxY = dailyStats
        .map((day) => day.totalUnits)
        .fold<int>(0, (max, value) => value > max ? value : max)
        .toDouble();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: [
            for (var i = 0; i < dailyStats.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: dailyStats[i].totalUnits.toDouble(),
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                    width: 12,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 220, child: Center(child: Text(text)));
  }
}

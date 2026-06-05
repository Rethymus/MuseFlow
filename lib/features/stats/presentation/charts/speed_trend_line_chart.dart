import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:museflow/features/stats/domain/daily_writing_stats.dart';

class SpeedTrendLineChart extends StatelessWidget {
  const SpeedTrendLineChart({super.key, required this.dailyStats});

  final List<DailyWritingStats> dailyStats;

  @override
  Widget build(BuildContext context) {
    if (dailyStats.isEmpty) {
      return const _ChartEmptyState(text: '还没有速度趋势');
    }

    final colorScheme = Theme.of(context).colorScheme;
    final points = <FlSpot>[
      for (var i = 0; i < dailyStats.length; i++)
        FlSpot(i.toDouble(), _speedFor(dailyStats[i])),
    ];
    final maxY = points.fold<double>(
      0,
      (max, spot) => spot.y > max ? spot.y : max,
    );

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: points,
              isCurved: true,
              color: colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  double _speedFor(DailyWritingStats day) {
    if (day.editSeconds <= 0) return day.totalUnits.toDouble();
    final minutes = day.editSeconds / 60;
    return day.totalUnits / minutes;
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

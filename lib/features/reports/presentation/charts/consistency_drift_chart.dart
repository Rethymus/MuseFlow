import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ConsistencyDriftChart extends StatelessWidget {
  const ConsistencyDriftChart({super.key, required this.driftScores});

  final List<double> driftScores;

  @override
  Widget build(BuildContext context) {
    if (driftScores.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('需要知识库实体和章节内容')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final scores = driftScores.take(10).toList(growable: false);
    final spots = [
      for (var index = 0; index < scores.length; index++)
        FlSpot(index.toDouble(), scores[index].clamp(0.0, 1.0)),
    ];

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 9,
          minY: 0,
          maxY: 1,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 0.25,
                reservedSize: 44,
                getTitlesWidget: (value, meta) => Text('${(value * 100).round()}%'),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index > 9 || value != index) return const Text('');
                  final start = index * 10 + 1;
                  final end = start + 9;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('$start-$end'),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

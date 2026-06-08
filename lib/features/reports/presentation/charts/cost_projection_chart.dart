import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:museflow/features/reports/domain/token_cost_report.dart';

class CostProjectionChart extends StatelessWidget {
  const CostProjectionChart({
    super.key,
    required this.report,
    required this.projection,
  });

  final TokenCostReport report;
  final TokenCostProjection projection;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final values = [
      (
        actual: report.totalInputTokens,
        projected: projection.estimatedInputTokens,
      ),
      (
        actual: report.totalOutputTokens,
        projected: projection.estimatedOutputTokens,
      ),
      (actual: report.totalCalls, projected: projection.estimatedCalls),
    ];
    final maxValue = values.fold<int>(
      0,
      (max, item) =>
          [max, item.actual, item.projected].reduce((a, b) => a > b ? a : b),
    );
    const labels = ['输入 Token', '输出 Token', 'API 调用'];

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxValue <= 0 ? 1 : maxValue * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const Text('');
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[index],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 8,
                barRods: [
                  BarChartRodData(
                    toY: values[i].actual.toDouble(),
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                    width: 24,
                  ),
                  BarChartRodData(
                    toY: values[i].projected.toDouble(),
                    color: colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(4),
                    width: 24,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

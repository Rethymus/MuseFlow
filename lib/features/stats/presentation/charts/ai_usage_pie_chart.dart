import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AIUsagePieChart extends StatelessWidget {
  const AIUsagePieChart({
    super.key,
    required this.humanUnits,
    required this.aiUnits,
  });

  final int humanUnits;
  final int aiUnits;

  @override
  Widget build(BuildContext context) {
    final total = humanUnits + aiUnits;
    if (total == 0) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('还没有 AI 使用记录')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 44,
          sections: [
            PieChartSectionData(
              value: humanUnits.toDouble(),
              color: colorScheme.primary,
              title: '手写',
              radius: 58,
            ),
            PieChartSectionData(
              value: aiUnits.toDouble(),
              color: colorScheme.tertiary,
              title: 'AI',
              radius: 58,
            ),
          ],
        ),
      ),
    );
  }
}

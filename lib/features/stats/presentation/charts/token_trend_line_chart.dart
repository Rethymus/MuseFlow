import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';

class TokenTrendLineChart extends StatelessWidget {
  const TokenTrendLineChart({super.key, required this.records});

  final List<TokenAuditRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('还没有 Token 消耗趋势')),
      );
    }

    // Sort records by timestamp
    final sortedRecords = records.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate cumulative totals
    var cumulative = 0;
    final spots = <FlSpot>[];
    for (var i = 0; i < sortedRecords.length; i++) {
      cumulative += sortedRecords[i].totalTokens;
      spots.add(FlSpot(i.toDouble(), cumulative.toDouble()));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final maxY = spots.fold<double>(0, (max, spot) => spot.y > max ? spot.y : max);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
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
                  final index = value.toInt();
                  if (index >= 0 && index < sortedRecords.length) {
                    final date = sortedRecords[index].timestamp;
                    // Format date as MM/dd without intl package
                    final month = date.month.toString().padLeft(2, '0');
                    final day = date.day.toString().padLeft(2, '0');
                    return Text('$month/$day');
                  }
                  return const Text('');
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
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared fl_chart axis builders for the stats charts.
///
/// The default axis titles render raw doubles — fractional day indices on
/// the bottom (0.5, 1.5 …) and oversized numbers that wrap ("13400" →
/// "13 4 K") on the left. These helpers render integer day labels and
/// compact K-format counts instead.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Bottom axis for day-indexed series: integer labels (0, 1, 2 …) spaced
/// so at most ~15 ticks render regardless of series length.
AxisTitles bottomDayTitles(int count) {
  final interval = (count / 15).ceil().clamp(1, 7).toDouble();
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 24,
      interval: interval,
      getTitlesWidget: (value, meta) =>
          SideTitleWidget(meta: meta, child: Text('${value.round()}')),
    ),
  );
}

/// Left axis with compact labels (13400 → 13.4K) and enough reserved
/// width that the top label never wraps into the card title.
AxisTitles leftCompactTitles({double reservedSize = 40}) {
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: reservedSize,
      getTitlesWidget: (value, meta) =>
          SideTitleWidget(meta: meta, child: Text(_compact(value))),
    ),
  );
}

String _compact(double value) {
  if (value >= 1000) {
    final k = value / 1000;
    final label = k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
    return '${label}K';
  }
  // Non-integer tops (maxY * 1.2 padding) round to keep labels compact.
  return value.round().toString();
}

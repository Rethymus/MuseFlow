/// GitHub-style writing heatmap showing daily creation rhythm.
///
/// Per Phase 24 (EDIT-04): Visualizes daily writing activity as a grid
/// of colored cells, similar to GitHub's contribution graph. Each cell
/// represents one day, colored by word count intensity.
library;

import 'package:flutter/material.dart';
import 'package:museflow/features/stats/domain/daily_writing_stats.dart';

/// A writing heatmap widget that displays daily activity as colored cells.
///
/// Shows the last [weekCount] weeks of writing data. Each cell is colored
/// by word count intensity: empty days are transparent, low activity is light,
/// high activity is dark (using the theme's primary color).
class WritingHeatmap extends StatelessWidget {
  const WritingHeatmap({
    super.key,
    required this.dailyStats,
    this.weekCount = 15,
    this.cellSize = 14,
    this.cellSpacing = 3,
  });

  /// Daily writing data, keyed by date string (YYYY-MM-DD).
  final List<DailyWritingStats> dailyStats;

  /// Number of weeks to display (default: 15, ~3.5 months).
  final int weekCount;

  /// Size of each day cell in logical pixels.
  final double cellSize;

  /// Spacing between cells.
  final double cellSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Build a map from dateKey to totalUnits
    final dataMap = <String, int>{};
    for (final d in dailyStats) {
      dataMap[d.dateKey] = d.totalUnits;
    }

    // Calculate max for color scaling
    final maxVal = dataMap.isEmpty
        ? 1.0
        : dataMap.values
            .reduce((a, b) => a > b ? a : b)
            .toDouble();

    // Generate date range: from today going back weekCount weeks
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: weekCount * 7));

    // Build columns (weeks), each with 7 rows (days)
    // Align to day of week so the grid starts on the same weekday as today
    final startWeekday = startDate.weekday; // 1=Mon, 7=Sun

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels
        _MonthLabels(
          startDate: startDate,
          weekCount: weekCount,
          cellSize: cellSize,
          cellSpacing: cellSpacing,
        ),
        const SizedBox(height: 4),
        // Heatmap grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day-of-week labels
            _DayLabels(cellSize: cellSize, cellSpacing: cellSpacing),
            const SizedBox(width: 4),
            // Grid of cells
            Expanded(
              child: _HeatmapGrid(
                startDate: startDate,
                weekCount: weekCount,
                startWeekday: startWeekday,
                dataMap: dataMap,
                maxUnits: maxVal,
                cellSize: cellSize,
                cellSpacing: cellSpacing,
                primaryColor: colorScheme.primary,
                surfaceColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Legend
        _Legend(
          cellSize: cellSize,
          primaryColor: colorScheme.primary,
          surfaceColor: colorScheme.surfaceContainerHighest,
          labelStyle: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Grid of heatmap cells organized by week columns.
class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.startDate,
    required this.weekCount,
    required this.startWeekday,
    required this.dataMap,
    required this.maxUnits,
    required this.cellSize,
    required this.cellSpacing,
    required this.primaryColor,
    required this.surfaceColor,
  });

  final DateTime startDate;
  final int weekCount;
  final int startWeekday;
  final Map<String, int> dataMap;
  final double maxUnits;
  final double cellSize;
  final double cellSpacing;
  final Color primaryColor;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(weekCount + 1, (weekIndex) {
          return SizedBox(
            width: cellSize + cellSpacing,
            child: Column(
              children: List.generate(7, (dayIndex) {
                // Calculate the date for this cell
                final dayOffset = weekIndex * 7 + dayIndex - startWeekday;
                final date = startDate.add(Duration(days: dayOffset));
                final dateKey = _dateKey(date);

                // Skip cells before startDate
                if (date.isBefore(startDate)) {
                  return SizedBox(
                    height: cellSize + cellSpacing,
                  );
                }

                // Skip future dates
                if (date.isAfter(DateTime.now())) {
                  return SizedBox(
                    height: cellSize + cellSpacing,
                  );
                }

                final units = dataMap[dateKey] ?? 0;
                final level = _intensityLevel(units, maxUnits);

                return Padding(
                  padding: EdgeInsets.only(bottom: cellSpacing),
                  child: Tooltip(
                    message: '$_formatDate(date)\n$units 字',
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: _cellColor(level, primaryColor, surfaceColor),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

/// Month labels above the heatmap.
class _MonthLabels extends StatelessWidget {
  const _MonthLabels({
    required this.startDate,
    required this.weekCount,
    required this.cellSize,
    required this.cellSpacing,
  });

  final DateTime startDate;
  final int weekCount;
  final double cellSize;
  final double cellSpacing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    final columnWidth = cellSize + cellSpacing;
    const dayLabelWidth = 24.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: dayLabelWidth + 4),
        Expanded(
          child: SizedBox(
            height: 16,
            child: LayoutBuilder(builder: (context, _) {
              final months = <String>[];
              DateTime? lastMonth;

              for (int w = 0; w <= weekCount; w++) {
                final date = startDate.add(Duration(days: w * 7));
                if (lastMonth == null || date.month != lastMonth.month) {
                  months.add('${date.month}月');
                  lastMonth = date;
                } else {
                  months.add('');
                }
              }

              return Row(
                children: months.map((label) {
                  return SizedBox(
                    width: columnWidth,
                    child: Text(
                      label,
                      style: style,
                      overflow: TextOverflow.visible,
                    ),
                  );
                }).toList(),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Day-of-week labels (Mon, Wed, Fri) on the left side.
class _DayLabels extends StatelessWidget {
  const _DayLabels({required this.cellSize, required this.cellSpacing});

  final double cellSize;
  final double cellSpacing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    final rowHeight = cellSize + cellSpacing;

    return SizedBox(
      width: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(height: rowHeight * 0), // Sun (row 0) - no label
          Text('一', style: style), // Mon
          SizedBox(height: rowHeight * 0), // Tue
          Text('三', style: style), // Wed
          SizedBox(height: rowHeight * 0), // Thu
          Text('五', style: style), // Fri
          SizedBox(height: rowHeight * 0), // Sat
        ],
      ),
    );
  }
}

/// Color legend showing intensity scale.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.cellSize,
    required this.primaryColor,
    required this.surfaceColor,
    this.labelStyle,
  });

  final double cellSize;
  final Color primaryColor;
  final Color surfaceColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('少', style: labelStyle),
        const SizedBox(width: 4),
        for (int level = 0; level < 5; level++)
          Padding(
            padding: EdgeInsets.only(right: 2),
            child: Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _cellColor(level, primaryColor, surfaceColor),
              ),
            ),
          ),
        const SizedBox(width: 4),
        Text('多', style: labelStyle),
      ],
    );
  }
}

/// Converts intensity level (0-4) to a color.
Color _cellColor(int level, Color primary, Color surface) {
  return switch (level) {
    0 => surface.withValues(alpha: 0.3),
    1 => primary.withValues(alpha: 0.25),
    2 => primary.withValues(alpha: 0.5),
    3 => primary.withValues(alpha: 0.75),
    _ => primary,
  };
}

/// Calculates intensity level (0-4) from word count.
int _intensityLevel(int units, double maxUnits) {
  if (units == 0) return 0;
  if (maxUnits == 0) return 0;
  final ratio = units / maxUnits;
  if (ratio < 0.15) return 1;
  if (ratio < 0.35) return 2;
  if (ratio < 0.65) return 3;
  return 4;
}

/// Formats date as M月d日.
String _formatDate(DateTime date) {
  return '${date.month}月${date.day}日';
}

/// Converts DateTime to dateKey string (YYYY-MM-DD).
String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

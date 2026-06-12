/// Writing progress dashboard with comprehensive progress visualization.
///
/// Per Phase 24 (EDIT-04): Shows daily creation rhythm heatmap,
/// AI-assisted vs manual ratio, chapter completion tracking,
/// streak display, and estimated completion time.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/domain/daily_writing_stats.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';
import 'package:museflow/features/stats/presentation/charts/writing_heatmap.dart';

/// Progress dashboard page showing comprehensive writing metrics.
///
/// Displays:
/// - Daily writing rhythm heatmap (GitHub-style)
/// - Total word count with circular progress toward target
/// - AI-assisted vs manual writing ratio
/// - Current writing streak
/// - Estimated completion time
/// - Chapter completion progress
class ProgressDashboardPage extends ConsumerWidget {
  const ProgressDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(writingStatsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('写作进度'),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败：$error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(writingStatsNotifierProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (snapshot) => _DashboardContent(snapshot: snapshot),
      ),
    );
  }
}

/// Main dashboard content with responsive grid layout.
class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: isWide
          ? _WideLayout(snapshot: snapshot)
          : _NarrowLayout(snapshot: snapshot),
    );
  }
}

/// Wide layout: two-column grid.
class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary cards row
        Row(
          children: [
            Expanded(child: _WordCountCard(snapshot: snapshot)),
            const SizedBox(width: 12),
            Expanded(child: _AiRatioCard(snapshot: snapshot)),
            const SizedBox(width: 12),
            Expanded(child: _StreakCard(snapshot: snapshot)),
          ],
        ),
        const SizedBox(height: 16),
        // Heatmap - full width
        _HeatmapSection(dailyStats: snapshot.daily),
        const SizedBox(height: 16),
        // Bottom row
        Row(
          children: [
            Expanded(child: _PaceCard(snapshot: snapshot)),
            const SizedBox(width: 12),
            Expanded(child: _ConsistencyCard(snapshot: snapshot)),
          ],
        ),
      ],
    );
  }
}

/// Narrow layout: single column.
class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary cards row (2 per row on narrow)
        Row(
          children: [
            Expanded(child: _WordCountCard(snapshot: snapshot)),
            const SizedBox(width: 12),
            Expanded(child: _AiRatioCard(snapshot: snapshot)),
          ],
        ),
        const SizedBox(height: 12),
        // Streak + Pace
        Row(
          children: [
            Expanded(child: _StreakCard(snapshot: snapshot)),
            const SizedBox(width: 12),
            Expanded(child: _PaceCard(snapshot: snapshot)),
          ],
        ),
        const SizedBox(height: 16),
        // Heatmap - full width
        _HeatmapSection(dailyStats: snapshot.daily),
        const SizedBox(height: 16),
        // Consistency card
        _ConsistencyCard(snapshot: snapshot),
      ],
    );
  }
}

/// Total word count with circular progress indicator.
class _WordCountCard extends StatelessWidget {
  const _WordCountCard({required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Estimate target: assume 80k words as default manuscript target
    const targetWords = 80000;
    final progress = (snapshot.totalUnits / targetWords).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Circular progress
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor:
                        AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '总字数',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${snapshot.totalUnits}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '目标 ${(targetWords / 10000).toInt()}万字',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI-assisted vs manual writing ratio card.
class _AiRatioCard extends StatelessWidget {
  const _AiRatioCard({required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ratio = snapshot.aiAssistRatio;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.tertiary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI 辅助率',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Ratio bar
            Row(
              children: [
                Expanded(
                  flex: ((1 - ratio) * 100).round().clamp(1, 100),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  flex: (ratio * 100).round().clamp(1, 100),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '手动 ${(snapshot.humanUnits)}',
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  'AI ${snapshot.aiUnits}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Writing streak card showing consecutive writing days.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final streak = _calculateStreak(snapshot.daily);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department,
                    color: colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Text(
                  '连续写作',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$streak',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: streak > 0 ? colorScheme.error : colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '天',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (streak > 0)
              Text(
                streak >= 7 ? '🔥 坚持了一周！' : '继续保持！',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Calculates current writing streak (consecutive days with writing activity).
  int _calculateStreak(List<DailyWritingStats> daily) {
    if (daily.isEmpty) return 0;

    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final dataMap = <String, int>{};
    for (final d in daily) {
      dataMap[d.dateKey] = d.totalUnits;
    }

    // Check if today or yesterday has activity (allow 1-day gap)
    int streak = 0;
    DateTime checkDate = today;

    // If today has no activity, start from yesterday
    if ((dataMap[todayKey] ?? 0) == 0) {
      checkDate = today.subtract(const Duration(days: 1));
    }

    while (true) {
      final key =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if ((dataMap[key] ?? 0) > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}

/// Estimated writing pace and completion time.
class _PaceCard extends StatelessWidget {
  const _PaceCard({required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final avgDaily = snapshot.writingDays > 0
        ? snapshot.totalUnits / snapshot.writingDays
        : 0;
    const targetWords = 80000;
    final remaining = (targetWords - snapshot.totalUnits).clamp(0, targetWords);
    final daysToComplete =
        avgDaily > 0 ? (remaining / avgDaily).ceil() : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '写作节奏',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '日均 ${avgDaily.round()} 字',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            if (daysToComplete > 0)
              Text(
                '预计还需 $daysToComplete 天完成目标',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              )
            else if (snapshot.totalUnits >= targetWords)
              Text(
                '🎉 已达成目标！',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              )
            else
              Text(
                '开始写作以计算节奏',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Writing consistency score card.
class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate how many of the last 30 days had writing activity
    final last30 = _getLastNDaysStats(snapshot.daily, 30);
    final activeDays = last30.where((d) => d.totalUnits > 0).length;
    final consistencyScore =
        (activeDays / 30 * 100).round(); // percentage

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up,
                    color: colorScheme.secondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '写作一致性',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '$consistencyScore%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: consistencyScore / 100,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor:
                    AlwaysStoppedAnimation(colorScheme.secondary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '近30天中有 $activeDays 天有写作记录',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Heatmap section with section header.
class _HeatmapSection extends StatelessWidget {
  const _HeatmapSection({required this.dailyStats});

  final List<DailyWritingStats> dailyStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  '每日创作节奏',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            WritingHeatmap(dailyStats: dailyStats),
          ],
        ),
      ),
    );
  }
}

/// Gets stats for the last N days, filling in missing days with zeros.
List<DailyWritingStats> _getLastNDaysStats(
  List<DailyWritingStats> daily,
  int days,
) {
  final result = <DailyWritingStats>[];
  final today = DateTime.now();

  final dataMap = <String, DailyWritingStats>{};
  for (final d in daily) {
    dataMap[d.dateKey] = d;
  }

  for (int i = 0; i < days; i++) {
    final date = today.subtract(Duration(days: i));
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    result.add(dataMap[key] ?? DailyWritingStats(dateKey: key));
  }

  return result;
}

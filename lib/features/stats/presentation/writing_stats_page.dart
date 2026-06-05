import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';
import 'package:museflow/features/stats/presentation/charts/ai_usage_pie_chart.dart';
import 'package:museflow/features/stats/presentation/charts/daily_words_bar_chart.dart';
import 'package:museflow/features/stats/presentation/charts/speed_trend_line_chart.dart';
import 'package:museflow/features/stats/presentation/achievement_badge_section.dart';
import 'package:museflow/features/stats/presentation/stats_summary_card.dart';
import 'package:museflow/shared/constants/app_constants.dart';

class WritingStatsPage extends ConsumerWidget {
  const WritingStatsPage({super.key, this.debugSnapshot});

  final StatsSnapshot? debugSnapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (debugSnapshot != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('写作统计')),
        body: _StatsContent(snapshot: debugSnapshot!, useDebugBadges: true),
      );
    }

    final statsAsync = ref.watch(writingStatsNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('写作统计'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go(AppConstants.statsProject),
            icon: const Icon(Icons.article_outlined),
            label: const Text('当前作品'),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('统计加载失败：$error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(writingStatsNotifierProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (snapshot) => _StatsContent(snapshot: snapshot),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.snapshot, this.useDebugBadges = false});

  final StatsSnapshot snapshot;
  final bool useDebugBadges;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('写作统计', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('把创作过程变成可感知的轨迹。', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        if (snapshot.totalUnits == 0)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('开始写作后，这里会出现你的创作轨迹。'),
            ),
          ),
        _SummaryWrap(snapshot: snapshot),
        const SizedBox(height: 24),
        _ChartSection(
          title: '每日字数',
          child: DailyWordsBarChart(dailyStats: snapshot.daily),
        ),
        _ChartSection(
          title: '速度趋势',
          child: SpeedTrendLineChart(dailyStats: snapshot.daily),
        ),
        _ChartSection(
          title: 'AI 使用比例',
          child: AIUsagePieChart(
            humanUnits: snapshot.humanUnits,
            aiUnits: snapshot.aiUnits,
          ),
        ),
        AchievementBadgeSection(debugBadges: useDebugBadges ? const [] : null),
      ],
    );
  }
}

class _SummaryWrap extends StatelessWidget {
  const _SummaryWrap({required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final ratio = (snapshot.aiAssistRatio * 100).toStringAsFixed(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 720
            ? constraints.maxWidth
            : (constraints.maxWidth - 24) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: StatsSummaryCard(
                icon: Icons.edit_note_outlined,
                title: '总字数',
                value: '${snapshot.totalUnits}',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatsSummaryCard(
                icon: Icons.calendar_month_outlined,
                title: '写作天数',
                value: '${snapshot.writingDays}',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatsSummaryCard(
                icon: Icons.auto_awesome_outlined,
                title: 'AI辅助比例',
                value: '$ratio%',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatsSummaryCard(
                icon: Icons.history_outlined,
                title: '会话总数',
                value: '${snapshot.sessionCount}',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

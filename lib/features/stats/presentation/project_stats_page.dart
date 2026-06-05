import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';
import 'package:museflow/features/stats/presentation/charts/daily_words_bar_chart.dart';
import 'package:museflow/features/stats/presentation/stats_summary_card.dart';

class ProjectStatsPage extends ConsumerWidget {
  const ProjectStatsPage({super.key, this.debugSnapshot});

  final StatsSnapshot? debugSnapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (debugSnapshot != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('当前作品统计')),
        body: _ProjectStatsContent(snapshot: debugSnapshot!),
      );
    }

    final statsAsync = ref.watch(writingStatsNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('当前作品统计')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('统计加载失败：$error')),
        data: (snapshot) => _ProjectStatsContent(snapshot: snapshot),
      ),
    );
  }
}

class _ProjectStatsContent extends StatelessWidget {
  const _ProjectStatsContent({required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final project = snapshot.currentProject ?? snapshot;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('当前作品统计', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        _ProjectSummary(snapshot: project),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('章节字数分布', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('章节模型接入后将显示分章分布'),
                const SizedBox(height: 12),
                DailyWordsBarChart(dailyStats: snapshot.daily),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectSummary extends StatelessWidget {
  const _ProjectSummary({required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final ratio = (snapshot.aiAssistRatio * 100).toStringAsFixed(1);
    final minutes = (snapshot.editSeconds / 60).round();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 260,
          child: StatsSummaryCard(
            icon: Icons.article_outlined,
            title: '当前字数',
            value: '${snapshot.totalUnits}',
          ),
        ),
        SizedBox(
          width: 260,
          child: StatsSummaryCard(
            icon: Icons.auto_awesome_outlined,
            title: 'AI使用占比',
            value: '$ratio%',
            subtitle: '${snapshot.aiUnits} 字来自 AI 插入',
          ),
        ),
        SizedBox(
          width: 260,
          child: StatsSummaryCard(
            icon: Icons.timer_outlined,
            title: '编辑时长',
            value: '$minutes 分钟',
          ),
        ),
      ],
    );
  }
}

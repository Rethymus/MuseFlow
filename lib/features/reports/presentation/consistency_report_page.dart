import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/reports/application/report_export_service.dart';
import 'package:museflow/features/reports/domain/consistency_report.dart';
import 'package:museflow/features/reports/presentation/charts/consistency_drift_chart.dart';
import 'package:museflow/features/reports/presentation/consistency_flag_tile.dart';
import 'package:museflow/features/reports/providers.dart';
import 'package:museflow/features/stats/presentation/stats_summary_card.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';

class ConsistencyReportPage extends ConsumerWidget {
  const ConsistencyReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(consistencyReportProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库一致性分析'),
        actions: [
          IconButton(
            tooltip: '导出报告',
            icon: const Icon(Icons.download_outlined),
            onPressed: reportAsync.hasValue
                ? () => _exportReport(context, reportAsync.requireValue)
                : null,
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('报告生成失败: $error')),
        data: (report) => _ConsistencyReportContent(report: report),
      ),
    );
  }

  Future<void> _exportReport(
    BuildContext context,
    ConsistencyReport report,
  ) async {
    final markdown = const ReportExportService().buildConsistencyMarkdown(
      report,
    );
    const path = 'consistency-report.md';
    await ExportService.dartFileWriter(path, markdown);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('报告已导出至: consistency-report.md')),
    );
  }
}

class _ConsistencyReportContent extends StatelessWidget {
  const _ConsistencyReportContent({required this.report});

  final ConsistencyReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalFlags = [
      ...report.characterResults,
      ...report.settingResults,
    ].fold<int>(0, (sum, result) => sum + result.flags.length);
    final isEmpty =
        report.characterResults.isEmpty && report.settingResults.isEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('知识库一致性分析', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('100章后角色卡与设定集的衰减检测。', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatsSummaryCard(
              icon: Icons.verified_outlined,
              title: '整体一致性',
              value:
                  '${(report.overallConsistencyScore * 100).toStringAsFixed(0)}%',
            ),
            StatsSummaryCard(
              icon: Icons.person_search_outlined,
              title: '角色检查',
              value: report.characterResults.length.toString(),
            ),
            StatsSummaryCard(
              icon: Icons.public_outlined,
              title: '设定检查',
              value: report.settingResults.length.toString(),
            ),
            StatsSummaryCard(
              icon: Icons.report_problem_outlined,
              title: '一致性警报',
              value: totalFlags.toString(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('需要知识库实体和章节内容才能进行一致性分析。'),
            ),
          )
        else ...[
          _SectionCard(
            title: '一致性趋势（每10章）',
            child: ConsistencyDriftChart(driftScores: report.driftPerSegment),
          ),
          const SizedBox(height: 16),
          _NarrativeQualitySection(snapshot: report.narrativeQuality),
          const SizedBox(height: 16),
          _EntitySection(title: '角色一致性', results: report.characterResults),
          const SizedBox(height: 16),
          _EntitySection(title: '设定一致性', results: report.settingResults),
        ],
      ],
    );
  }
}

class _NarrativeQualitySection extends StatelessWidget {
  const _NarrativeQualitySection({required this.snapshot});

  final NarrativeQualitySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final signals = snapshot.signals.take(8).toList(growable: false);
    return _SectionCard(
      title: '叙事质量复查',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StatsSummaryCard(
                icon: Icons.landscape_outlined,
                title: '场景沉浸',
                value: _percent(snapshot.immersionScore),
              ),
              StatsSummaryCard(
                icon: Icons.record_voice_over_outlined,
                title: '人设锚点',
                value: _percent(snapshot.characterAnchoringScore),
              ),
              StatsSummaryCard(
                icon: Icons.auto_fix_off_outlined,
                title: '反AI味',
                value: _percent(snapshot.antiAiScentScore),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (signals.isEmpty)
            const Text('暂未发现需要优先复查的叙事质量信号。')
          else
            for (final signal in signals)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.manage_search_outlined,
                    color: _severityColor(context, signal.severity),
                  ),
                  title: Text('第${signal.chapterIndex + 1}章 · ${signal.title}'),
                  subtitle: Text(
                    '证据：${signal.evidence}\n建议：${signal.suggestion}',
                  ),
                  isThreeLine: true,
                ),
              ),
        ],
      ),
    );
  }

  String _percent(double score) => '${(score * 100).toStringAsFixed(0)}%';

  Color _severityColor(BuildContext context, DeviationSeverity severity) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (severity) {
      DeviationSeverity.clear => colorScheme.error,
      DeviationSeverity.medium => colorScheme.tertiary,
      DeviationSeverity.low => colorScheme.primary,
    };
  }
}

class _EntitySection extends StatelessWidget {
  const _EntitySection({required this.title, required this.results});

  final String title;
  final List<EntityConsistencyResult> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final result in results)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    title: Text(result.entityName),
                    subtitle: Text('出现章节：${result.chaptersWhereMentioned}'),
                    trailing: Text(
                      '${(result.consistencyScore * 100).toStringAsFixed(0)}%',
                    ),
                  ),
                  for (final flag in result.flags)
                    ConsistencyFlagTile(flag: flag),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

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

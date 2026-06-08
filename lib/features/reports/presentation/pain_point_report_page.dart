import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/reports/application/report_export_service.dart';
import 'package:museflow/features/reports/domain/pain_point_report.dart';
import 'package:museflow/features/reports/presentation/severity_indicator.dart';
import 'package:museflow/features/reports/providers.dart';
import 'package:museflow/features/stats/presentation/stats_summary_card.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';

class PainPointReportPage extends ConsumerWidget {
  const PainPointReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(painPointReportProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('痛点报告'),
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
        data: (report) => _PainPointReportContent(report: report),
      ),
    );
  }

  Future<void> _exportReport(
    BuildContext context,
    PainPointReport report,
  ) async {
    final markdown = const ReportExportService().buildPainPointMarkdown(report);
    const path = 'pain-point-report.md';
    await ExportService.dartFileWriter(path, markdown);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('报告已导出至: pain-point-report.md')),
    );
  }
}

class _PainPointReportContent extends StatelessWidget {
  const _PainPointReportContent({required this.report});

  final PainPointReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('痛点报告', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('功能缺陷、体验摩擦与缺失需求汇总。', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatsSummaryCard(
              icon: Icons.priority_high_outlined,
              title: '高严重度',
              value: report.totalHigh.toString(),
            ),
            StatsSummaryCard(
              icon: Icons.report_problem_outlined,
              title: '中严重度',
              value: report.totalMedium.toString(),
            ),
            StatsSummaryCard(
              icon: Icons.info_outline,
              title: '低严重度',
              value: report.totalLow.toString(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (report.issues.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('创作验证过程中未发现痛点。'),
            ),
          )
        else ...[
          _IssueSection(title: '功能缺陷', issues: _issuesFor('功能缺陷')),
          _IssueSection(title: '体验摩擦', issues: _issuesFor('体验摩擦')),
          _IssueSection(title: '缺失需求', issues: _issuesFor('缺失需求')),
        ],
      ],
    );
  }

  List<PainPointIssue> _issuesFor(String category) {
    return report.issues.where((issue) => issue.category == category).toList();
  }
}

class _IssueSection extends StatelessWidget {
  const _IssueSection({required this.title, required this.issues});

  final String title;
  final List<PainPointIssue> issues;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (issues.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('创作验证过程中未发现痛点。'),
              ),
            )
          else
            for (final issue in issues)
              Card(
                child: ListTile(
                  leading: SeverityIndicator(severity: issue.severity),
                  title: Text(issue.title),
                  subtitle: Text(
                    issue.requirement.isEmpty
                        ? issue.description
                        : issue.requirement,
                  ),
                  trailing: Text(issue.status),
                ),
              ),
        ],
      ),
    );
  }
}

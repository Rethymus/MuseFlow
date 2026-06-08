import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/reports/application/report_export_service.dart';
import 'package:museflow/features/reports/domain/token_cost_report.dart';
import 'package:museflow/features/reports/presentation/charts/cost_projection_chart.dart';
import 'package:museflow/features/reports/providers.dart';
import 'package:museflow/features/stats/presentation/charts/operation_type_pie_chart.dart';
import 'package:museflow/features/stats/presentation/stats_summary_card.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';

class TokenCostReportPage extends ConsumerWidget {
  const TokenCostReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(tokenCostReportProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token 消耗分析'),
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
        data: (report) => _TokenCostReportContent(report: report),
      ),
    );
  }

  Future<void> _exportReport(
    BuildContext context,
    TokenCostReport report,
  ) async {
    final markdown = const ReportExportService().buildTokenCostMarkdown(report);
    const path = 'token-cost-report.md';
    await ExportService.dartFileWriter(path, markdown);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('报告已导出至: token-cost-report.md')),
    );
  }
}

class _TokenCostReportContent extends StatelessWidget {
  const _TokenCostReportContent({required this.report});

  final TokenCostReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalTokens = report.totalInputTokens + report.totalOutputTokens;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Token 消耗分析', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('实际成本核算与长篇推算。', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatsSummaryCard(
              icon: Icons.input_outlined,
              title: '输入 Token',
              value: _formatNumber(report.totalInputTokens),
            ),
            StatsSummaryCard(
              icon: Icons.output_outlined,
              title: '输出 Token',
              value: _formatNumber(report.totalOutputTokens),
            ),
            StatsSummaryCard(
              icon: Icons.api_outlined,
              title: 'API 调用次数',
              value: _formatNumber(report.totalCalls),
            ),
            StatsSummaryCard(
              icon: Icons.article_outlined,
              title: '实际字数',
              value: _formatNumber(report.actualWordCount.round()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '按操作类型分布',
          child: OperationTypePieChart(costByType: report.costByType),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '50万字长篇推算',
          child: Column(
            children: [
              CostProjectionChart(
                report: report,
                projection: report.projection,
              ),
              _ProjectionRow(
                label: '预估总 Token',
                value: _formatNumber(
                  report.projection.estimatedInputTokens +
                      report.projection.estimatedOutputTokens,
                ),
              ),
              _ProjectionRow(
                label: '预估 API 调用',
                value: _formatNumber(report.projection.estimatedCalls),
              ),
              _ProjectionRow(
                label: '估算范围',
                value:
                    '${_formatNumber((report.projection.lowEstimateMultiplier * totalTokens).round())} ~ ${_formatNumber((report.projection.highEstimateMultiplier * totalTokens).round())}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '优化建议',
          child: Column(
            children: [
              for (final suggestion in report.optimizationSuggestions)
                ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(suggestion),
                ),
            ],
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

class _ProjectionRow extends StatelessWidget {
  const _ProjectionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

String _formatNumber(num value) {
  final text = value.round().toString();
  return text.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}

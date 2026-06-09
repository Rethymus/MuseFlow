import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
import 'package:museflow/features/stats/presentation/charts/chapter_token_bar_chart.dart';
import 'package:museflow/features/stats/presentation/charts/operation_type_pie_chart.dart';
import 'package:museflow/features/stats/presentation/charts/token_trend_line_chart.dart';
import 'package:museflow/features/stats/presentation/stats_summary_card.dart';

class TokenAuditPage extends ConsumerWidget {
  const TokenAuditPage({super.key, this.debugSnapshot});

  final TokenAuditSnapshot? debugSnapshot;

  /// Factory constructor for testing with a snapshot
  const TokenAuditPage.withSnapshot(TokenAuditSnapshot snapshot, {super.key})
    : debugSnapshot = snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (debugSnapshot != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Token 消耗总览')),
        body: _TokenAuditContent(snapshot: debugSnapshot!),
      );
    }

    final snapshotAsync = ref.watch(tokenAuditNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Token 消耗总览')),
      body: snapshotAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('统计加载失败：$error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(tokenAuditNotifierProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (snapshot) => _TokenAuditContent(snapshot: snapshot),
      ),
    );
  }
}

class _TokenAuditContent extends StatelessWidget {
  const _TokenAuditContent({required this.snapshot});

  final TokenAuditSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Token 消耗总览', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('追踪每次 AI 调用的 Token 用量与成本分布。', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        if (snapshot.totalCalls == 0)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('开始使用 AI 功能后，这里会出现消耗统计。'),
            ),
          )
        else ...[
          _SummaryCards(snapshot: snapshot),
          const SizedBox(height: 24),
          _ChartSection(
            title: '每章 Token 分布',
            child: ChapterTokenBarChart(records: snapshot.records),
          ),
          _ChartSection(
            title: '按操作类型分布',
            child: OperationTypePieChart(records: snapshot.records),
          ),
          _ChartSection(
            title: 'Token 消耗趋势',
            child: TokenTrendLineChart(records: snapshot.records),
          ),
        ],
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.snapshot});

  final TokenAuditSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final totalTokens = snapshot.totalInputTokens + snapshot.totalOutputTokens;

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
                icon: Icons.arrow_downward_outlined,
                title: '输入 Token',
                value: _formatNumber(snapshot.totalInputTokens),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatsSummaryCard(
                icon: Icons.arrow_upward_outlined,
                title: '输出 Token',
                value: _formatNumber(snapshot.totalOutputTokens),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatsSummaryCard(
                icon: Icons.swap_calls_outlined,
                title: 'API 调用次数',
                value: _formatNumber(snapshot.totalCalls),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatsSummaryCard(
                icon: Icons.confirmation_number_outlined,
                title: '总 Token',
                value: _formatNumber(totalTokens),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
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

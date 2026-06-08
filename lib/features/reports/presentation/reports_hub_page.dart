import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/features/reports/presentation/report_card.dart';
import 'package:museflow/shared/constants/app_constants.dart';

/// Hub page for the Analysis & Reports feature.
///
/// Displays 4 report cards (Token cost, Pain points, Anti-AI-scent,
/// KB consistency) that navigate to their respective detail pages.
/// Accessible from WritingStatsPage via the "分析报告" button.
class ReportsHubPage extends StatelessWidget {
  const ReportsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('分析报告')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('分析报告', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('百章创作验证的四维分析。', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          ReportCard(
            icon: Icons.analytics_outlined,
            title: 'Token 成本分析',
            description: '万字短篇实际成本与50万字长篇消耗推算',
            onTap: () => context.go(AppConstants.statsReportsTokenCost),
          ),
          const SizedBox(height: 12),
          ReportCard(
            icon: Icons.bug_report_outlined,
            title: '用户痛点报告',
            description: '功能缺陷 + 体验摩擦 + 缺失需求，按严重程度分类',
            onTap: () => context.go(AppConstants.statsReportsPainPoints),
          ),
          const SizedBox(height: 12),
          ReportCard(
            icon: Icons.visibility_outlined,
            title: '反AI味效果评估',
            description: '盲读测试评估 AI 生成内容的自然度',
            onTap: () => context.go(AppConstants.statsReportsAntiAiScent),
          ),
          const SizedBox(height: 12),
          ReportCard(
            icon: Icons.fact_check_outlined,
            title: '知识库一致性分析',
            description: '角色卡和设定集与实际内容的一致性对比',
            onTap: () => context.go(AppConstants.statsReportsConsistency),
          ),
        ],
      ),
    );
  }
}

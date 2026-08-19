import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/features/reports/presentation/report_card.dart';
import 'package:museflow/shared/constants/app_constants.dart';

/// Hub page for the Analysis & Reports feature.
///
/// Displays report cards (Token cost, Pain points, Anti-AI-scent,
/// KB consistency, Editorial review) that navigate to their detail pages.
/// Accessible from WritingStatsPage via the "分析报告" button.
class ReportsHubPage extends StatelessWidget {
  const ReportsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('分析报告', style: theme.textTheme.displayMedium)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('百章创作验证的四维分析。', style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 12),
          ReportCard(
            icon: CupertinoIcons.chart_bar,
            title: 'Token 成本分析',
            description: '万字短篇实际成本与50万字长篇消耗推算',
            onTap: () => context.go(AppConstants.statsReportsTokenCost),
          ),
          const SizedBox(height: 12),
          ReportCard(
            icon: CupertinoIcons.ant,
            title: '用户痛点报告',
            description: '功能缺陷 + 体验摩擦 + 缺失需求，按严重程度分类',
            onTap: () => context.go(AppConstants.statsReportsPainPoints),
          ),
          const SizedBox(height: 12),
          ReportCard(
            icon: CupertinoIcons.eye,
            title: '反AI味效果评估',
            description: '盲读测试评估 AI 生成内容的自然度',
            onTap: () => context.go(AppConstants.statsReportsAntiAiScent),
          ),
          const SizedBox(height: 12),
          ReportCard(
            icon: CupertinoIcons.checkmark_shield,
            title: '知识库一致性分析',
            description: '角色卡和设定集与实际内容的一致性对比',
            onTap: () => context.go(AppConstants.statsReportsConsistency),
          ),
          const SizedBox(height: 12),
          ReportCard(
            icon: CupertinoIcons.square_pencil,
            title: '编辑评审团',
            description: 'AI 从情节、人物、文笔、节奏四维给出建议性评审',
            onTap: () => context.go(AppConstants.statsReportsEditorialReview),
          ),
        ],
      ),
    );
  }
}

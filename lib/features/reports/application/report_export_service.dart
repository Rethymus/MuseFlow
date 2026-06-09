import 'package:museflow/features/reports/domain/blind_read_result.dart';
import 'package:museflow/features/reports/domain/consistency_report.dart';
import 'package:museflow/features/reports/domain/pain_point_report.dart';
import 'package:museflow/features/reports/domain/token_cost_report.dart';

/// Stateless service that converts report data models to Markdown strings.
///
/// Each report type has a dedicated `buildXxxMarkdown()` method.
/// Reports are generated on-demand per RESEARCH.md anti-pattern guidance
/// (no Hive caching). Uses StringBuffer pattern from ExportService.
class ReportExportService {
  const ReportExportService();

  /// Builds Markdown for the Token Cost Analysis report (REPORT-01).
  ///
  /// Sections: 实际消耗, 按操作类型分布, 50万字长篇推算, 优化建议.
  String buildTokenCostMarkdown(TokenCostReport report) {
    final buffer = StringBuffer();
    buffer.writeln('# Token 消耗分析报告');
    buffer.writeln();
    buffer.writeln('## 实际消耗');
    buffer.writeln();
    buffer.writeln('- 输入 Token: ${report.totalInputTokens}');
    buffer.writeln('- 输出 Token: ${report.totalOutputTokens}');
    buffer.writeln('- API 调用次数: ${report.totalCalls}');
    buffer.writeln('- 实际字数: ${report.actualWordCount.toInt()}');
    buffer.writeln();
    buffer.writeln('## 按操作类型分布');
    buffer.writeln();
    for (final entry in report.costByType.entries) {
      buffer.writeln('- ${entry.key.label}: ${entry.value} tokens');
    }
    buffer.writeln();
    buffer.writeln('## 按章节分布');
    buffer.writeln();
    for (final entry in report.costByChapter.entries) {
      buffer.writeln('- ${entry.key}: ${entry.value} tokens');
    }
    buffer.writeln();
    buffer.writeln('## 50万字长篇推算');
    buffer.writeln();
    buffer.writeln('- 目标字数: ${report.projection.targetWordCount.toInt()}');
    buffer.writeln('- 倍率: ${report.projection.multiplier.toStringAsFixed(2)}');
    buffer.writeln('- 预估输入 Token: ${report.projection.estimatedInputTokens}');
    buffer.writeln('- 预估输出 Token: ${report.projection.estimatedOutputTokens}');
    buffer.writeln('- 预估 API 调用: ${report.projection.estimatedCalls}');
    buffer.writeln(
      '- 估算范围: ${(report.projection.lowEstimateMultiplier * report.totalInputTokens).round()}'
      ' ~ ${(report.projection.highEstimateMultiplier * report.totalInputTokens).round()} tokens',
    );
    buffer.writeln();
    buffer.writeln('## 优化建议');
    buffer.writeln();
    for (final suggestion in report.optimizationSuggestions) {
      buffer.writeln('- $suggestion');
    }
    buffer.writeln();
    return buffer.toString();
  }

  /// Builds Markdown for the Pain Point report (REPORT-02).
  ///
  /// Sections: 功能缺陷, 体验摩擦, 缺失需求.
  String buildPainPointMarkdown(PainPointReport report) {
    final buffer = StringBuffer();
    buffer.writeln('# 痛点报告');
    buffer.writeln();
    buffer.writeln('## 概要');
    buffer.writeln();
    buffer.writeln('- 严重: ${report.totalHigh}');
    buffer.writeln('- 中等: ${report.totalMedium}');
    buffer.writeln('- 轻微: ${report.totalLow}');
    buffer.writeln();

    final categories = ['功能缺陷', '体验摩擦', '缺失需求'];
    for (final category in categories) {
      final categoryIssues = report.issues
          .where((i) => i.category == category)
          .toList();
      if (categoryIssues.isNotEmpty) {
        buffer.writeln('## $category');
        buffer.writeln();
        for (final issue in categoryIssues) {
          buffer.writeln('### ${issue.title} [${issue.severity}]');
          buffer.writeln();
          buffer.writeln('- ID: ${issue.id}');
          buffer.writeln('- 需求: ${issue.requirement}');
          buffer.writeln('- 状态: ${issue.status}');
          buffer.writeln('- 描述: ${issue.description}');
          buffer.writeln();
        }
      }
    }

    return buffer.toString();
  }

  /// Builds Markdown for the Anti-AI-Scent Evaluation report (REPORT-03).
  ///
  /// Contains verdict tally and score.
  String buildBlindReadMarkdown(BlindReadResult result) {
    final buffer = StringBuffer();
    buffer.writeln('# 反AI味评估报告');
    buffer.writeln();
    buffer.writeln('## 盲读测试结果');
    buffer.writeln();
    buffer.writeln('- 总段落数: ${result.excerpts.length}');
    buffer.writeln('- 已判断: ${result.totalJudged}');
    buffer.writeln('- 正确判断: ${result.correctCount}');
    buffer.writeln('- 辨识率: ${(result.score * 100).toStringAsFixed(1)}%');
    buffer.writeln();

    if (result.totalJudged > 0) {
      buffer.writeln('## 段落详情');
      buffer.writeln();
      var idx = 1;
      for (final excerpt in result.excerpts) {
        final verdictStr = excerpt.humanVerdict == null
            ? '未判断'
            : (excerpt.humanVerdict! ? 'AI 生成' : '人写的');
        buffer.writeln('$idx. 第${excerpt.chapterIndex}章 — $verdictStr');
        buffer.writeln('   > ${excerpt.text}');
        buffer.writeln();
        idx++;
      }
    }

    return buffer.toString();
  }

  /// Builds Markdown for the Knowledge Base Consistency report (REPORT-04).
  ///
  /// Contains entity scores and flag details.
  String buildConsistencyMarkdown(ConsistencyReport report) {
    final buffer = StringBuffer();
    buffer.writeln('# 知识库一致性分析报告');
    buffer.writeln();
    buffer.writeln('## 概要');
    buffer.writeln();
    buffer.writeln(
      '- 整体一致性: ${(report.overallConsistencyScore * 100).toStringAsFixed(1)}%',
    );
    buffer.writeln('- 角色检查: ${report.characterResults.length}');
    buffer.writeln('- 设定检查: ${report.settingResults.length}');
    buffer.writeln();

    void writeEntityResults(
      String sectionTitle,
      List<EntityConsistencyResult> results,
    ) {
      if (results.isEmpty) return;
      buffer.writeln('## $sectionTitle');
      buffer.writeln();
      for (final result in results) {
        buffer.writeln(
          '### ${result.entityName} (${(result.consistencyScore * 100).toStringAsFixed(1)}%)',
        );
        buffer.writeln();
        buffer.writeln('- 出现章节: ${result.chaptersWhereMentioned}');
        buffer.writeln('- 一致性警报: ${result.flags.length}');
        if (result.flags.isNotEmpty) {
          buffer.writeln();
          for (final flag in result.flags) {
            buffer.writeln(
              '- 第${flag.chapterIndex}章 [${flag.severity.name}] ${flag.field}: '
              '期望「${flag.expectedValue}」，实际「${flag.observedText}」',
            );
          }
        }
        buffer.writeln();
      }
    }

    writeEntityResults('角色一致性', report.characterResults);
    writeEntityResults('设定一致性', report.settingResults);

    if (report.driftPerSegment.isNotEmpty) {
      buffer.writeln('## 一致性趋势（每10章）');
      buffer.writeln();
      for (var i = 0; i < report.driftPerSegment.length; i++) {
        final start = i * 10 + 1;
        final end = (i + 1) * 10;
        buffer.writeln(
          '- 第$start-$end章: '
          '${(report.driftPerSegment[i] * 100).toStringAsFixed(1)}%',
        );
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}

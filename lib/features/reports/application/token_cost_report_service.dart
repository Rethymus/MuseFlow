import 'dart:math' as math;

import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/reports/domain/token_cost_report.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';

class TokenCostReportService {
  const TokenCostReportService({
    required this.auditRepository,
    required this.chapterRepository,
  });

  final TokenAuditRepository auditRepository;
  final ChapterRepository chapterRepository;

  Future<TokenCostReport> generate() async {
    final snapshot = await auditRepository.buildSnapshot();
    final costByType = <AuditOperationType, int>{};
    final costByChapter = <String, int>{};

    for (final record in snapshot.records) {
      costByType.update(
        record.operationType,
        (value) => value + record.totalTokens,
        ifAbsent: () => record.totalTokens,
      );

      final chapterId = record.chapterId;
      if (chapterId != null && chapterId.isNotEmpty) {
        costByChapter.update(
          chapterId,
          (value) => value + record.totalTokens,
          ifAbsent: () => record.totalTokens,
        );
      }
    }

    final actualWordCount = chapterRepository
        .getAll()
        .fold<int>(
          0,
          (sum, chapter) => sum + _countCharacters(chapter.documentContent),
        )
        .toDouble();
    final safeWordCount = math.max(actualWordCount, 1.0);
    final multiplier = 500000.0 / safeWordCount;

    return TokenCostReport(
      totalInputTokens: snapshot.totalInputTokens,
      totalOutputTokens: snapshot.totalOutputTokens,
      totalCalls: snapshot.totalCalls,
      actualWordCount: actualWordCount,
      costByType: Map.unmodifiable(costByType),
      costByChapter: Map.unmodifiable(costByChapter),
      projection: TokenCostProjection(
        targetWordCount: 500000.0,
        multiplier: multiplier,
        estimatedInputTokens: (snapshot.totalInputTokens * multiplier).round(),
        estimatedOutputTokens: (snapshot.totalOutputTokens * multiplier)
            .round(),
        estimatedCalls: (snapshot.totalCalls * multiplier).round(),
        lowEstimateMultiplier: multiplier * 0.8,
        highEstimateMultiplier: multiplier * 1.2,
      ),
      optimizationSuggestions: List.unmodifiable(
        _buildOptimizationSuggestions(snapshot, costByType, actualWordCount),
      ),
    );
  }

  int _countCharacters(String content) {
    return content.replaceAll(RegExp(r'\s'), '').length;
  }

  List<String> _buildOptimizationSuggestions(
    TokenAuditSnapshot snapshot,
    Map<AuditOperationType, int> costByType,
    double actualWordCount,
  ) {
    if (snapshot.records.isEmpty) {
      return const ['暂无 Token 消耗记录，完成创作验证后可生成优化建议。'];
    }

    final suggestions = <String>[];
    final totalTokens = snapshot.totalInputTokens + snapshot.totalOutputTokens;
    final synthesisTokens = costByType[AuditOperationType.synthesis] ?? 0;

    if (snapshot.totalCalls > math.max(actualWordCount / 500, 1)) {
      suggestions.add('批量操作减少 API 调用开销，避免短文本频繁请求。');
    }
    if (synthesisTokens > totalTokens * 0.5) {
      suggestions.add('使用更便宜的模型进行草稿生成，将高质量模型留给精修。');
    }
    if (snapshot.totalInputTokens > snapshot.totalOutputTokens * 3) {
      suggestions.add('减少知识库注入上下文长度以降低输入 Token。');
    }

    suggestions.add('当前万字短篇 Token 消耗在合理范围内，可作为长篇预算基线。');
    if (suggestions.length == 1) {
      suggestions.add('持续记录不同操作类型的消耗，优先优化高占比流程。');
    }
    return suggestions;
  }
}

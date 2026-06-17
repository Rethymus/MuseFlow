// Real-API integration test for ChapterSummarizationService (MC-02 slice 1).
//
// Mirrors the journey-test pattern: reads GLM_API_KEY / GLM_BASE_URL / GLM_MODEL
// from the environment and skips when no key is set, so this never burns quota
// in CI. The canned unit contract lives in chapter_summarization_service_test.dart;
// this file proves the service produces a bounded, content-faithful summary
// against the real GLM endpoint — the "真实 API 验证" that slice 1 deferred.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/manuscript/application/chapter_summarization_service.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl =
      Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';
  final model = Platform.environment['GLM_MODEL'] ?? 'glm-4-flash';

  Chapter chapter() => Chapter(
        id: 'ch-real-summary',
        manuscriptId: 'ms-real',
        title: '第十七章 灵草谷之变',
        sortOrder: 17,
        status: '初稿',
        documentContent: _chapterContent,
        createdAt: DateTime(2026, 6, 18),
        updatedAt: DateTime(2026, 6, 18),
      );

  group('ChapterSummarizationService (real GLM API)', () {
    test(
      'summarize produces a bounded, content-faithful summary via real GLM',
      () async {
        final service = ChapterSummarizationService(
          openAIAdapter: OpenAIAdapter(),
          apiKey: apiKey!,
          baseUrl: baseUrl,
          model: model,
        );
        final src = chapter();
        final result = await service.summarize(src);

        // 1) Non-empty output.
        expect(result.summary, isNotEmpty);
        // 2) Bounded: prompt asks for ≤120 chars (soft); real LLMs pad (0ae
        //    lesson), so allow headroom but reject runaway over-generation.
        expect(
          result.summary.length,
          lessThan(250),
          reason: 'summary should stay bounded (soft 120, hard <250)',
        );
        // 3) Real compression: a summary must be substantially shorter than its
        //    source, else it isn't summarizing.
        final sourceNonBlank = src.documentContent.replaceAll(
          RegExp(r'\s'),
          '',
        ).length;
        expect(
          result.summary.length,
          lessThan(sourceNonBlank * 0.6),
          reason: 'summary (${result.summary.length}) must compress source ($sourceNonBlank)',
        );
        // 4) sourceWordCount matches the source's non-whitespace length exactly
        //    (used by slice-2 staleness detection — must be precise).
        expect(result.sourceWordCount, sourceNonBlank);
        // 5) Content-faithful: summary must reference the chapter's protagonist.
        //    Guards against empty/hallucinated output that passes length checks.
        expect(
          result.summary,
          contains('林风'),
          reason: 'summary must reflect the summarized chapter content',
        );
        // 6) Entity/metadata wiring.
        expect(result.chapterId, src.id);
        expect(result.manuscriptId, src.manuscriptId);

        debugPrint('[MC-02] Real GLM summary (${result.summary.length} chars, '
            'source $sourceNonBlank): ${result.summary}');
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}

/// Realistic multi-paragraph xianxia chapter (~370 non-whitespace chars) with
/// named characters, a plot beat, and a foreshadowing hook — rich enough that a
/// faithful summary is non-trivial and content-faithfulness is checkable.
const String _chapterContent = '''
林风在灵草谷深处采药时，无意间触动了藏在乱石下的一枚古玉。古玉骤然发烫，一道微光没入他的眉心，随即一段晦涩的功法口诀浮现在脑海。他还未来得及细看，谷中便起了异变——四周灵气如潮水般涌向古玉，惊动了在附近巡山的外门弟子赵天磊。

赵天磊见林风周身灵气翻涌，认定他偷学禁术，厉声要拿下他问罪。两人剑拔弩张之际，苏雪晴悄然现身，以长老令牌压下争执，却暗中递给林风一个警告的眼神。林风心知古玉之事绝不能泄露，只推说采药时误入禁地。

事后，林风独自盘坐，尝试按口诀运转灵气，竟隐隐感到丹田处有异样的温热。他不确定这是机缘还是祸端，但古玉上那个若隐若现的"虚"字，让他隐隐觉得，自己与清虚真人之间，或许藏着更深的关联。
''';

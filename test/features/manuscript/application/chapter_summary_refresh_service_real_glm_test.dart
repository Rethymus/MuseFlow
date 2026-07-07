// Real-API integration test for ChapterSummaryRefreshService (MC-02 slice 3 WRITE SIDE).
//
// Closes STATE "待真实API验证: refresh 触发链 (save→summarize→store→读 fresh)" HEADLESSLY.
// slice 1 (chapter_summarization_real_glm_test.dart) proves summarize(); this file
// proves the full refresh decision + persist + idempotency loop against real GLM —
// the gap left by the canned decision-tree tests (chapter_summary_refresh_service_test.dart,
// all fake-adapter), which STATE flagged as "awaiting real-API verification".
//
// STATE noted that verification "needs user browser/device" — true only for the UI
// wiring; the service-layer loop (summarize → put → read-back + idempotent re-call)
// is verifiable headlessly against the real endpoint, exactly like slice 1.
//
// Mirrors the slice-1 pattern: reads GLM_API_KEY / GLM_BASE_URL / GLM_MODEL from the
// environment and skips when no key is set, so this never burns quota in CI.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/manuscript/application/chapter_summarization_service.dart';
import 'package:museflow/features/manuscript/application/chapter_summary_refresh_service.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_summary_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl =
      Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';
  final model = Platform.environment['GLM_MODEL'] ?? 'glm-4-flash';

  late Box<dynamic> box;
  late ChapterSummaryRepository repository;

  setUp(() async {
    // Real GLM HTTP must NOT be mocked: use the network-safe Hive helper, NOT
    // setUpHiveTest (whose ensureInitialized installs flutter_test's
    // HttpOverrides mock that returns HTTP 400 for all real requests, masking
    // live API calls as provider errors). See hive_test_helper.dart doc.
    await setUpHiveForNetworkTest();
    box = await Hive.openBox<dynamic>('chapter_summaries_real');
    repository = ChapterSummaryRepository(box);
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  Chapter chapter() => Chapter(
    id: 'ch-real-refresh',
    manuscriptId: 'ms-real',
    title: '第十七章 灵草谷之变',
    sortOrder: 17,
    status: '初稿',
    documentContent: _chapterContent,
    createdAt: DateTime(2026, 6, 18),
    updatedAt: DateTime(2026, 6, 18),
  );

  ChapterSummaryRefreshService service() => ChapterSummaryRefreshService(
    summarizationService: ChapterSummarizationService(
      openAIAdapter: OpenAIAdapter(),
      apiKey: apiKey!,
      baseUrl: baseUrl,
      model: model,
    ),
    summaryRepository: repository,
  );

  group('ChapterSummaryRefreshService (real GLM API)', () {
    test(
      'T1: first refreshIfNeeded (no stored) -> real GLM summarize + persist + '
      'content-faithful + bounded + compressed; repository read-back matches',
      () async {
        final src = chapter();
        final sourceNonBlank = src.documentContent
            .replaceAll(RegExp(r'\s'), '')
            .length;

        // Precondition: nothing stored for this chapter yet.
        expect(repository.getByChapterId(src.id), isNull);

        final outcome = await service().refreshIfNeeded(
          src,
          now: DateTime(2026, 6, 18),
        );

        // 1) The service called the LLM and persisted a new summary.
        expect(outcome.refreshed, isTrue);
        expect(outcome.summary, isNotNull);

        // 2) Content-faithful: references the protagonist (guards hallucination).
        expect(outcome.summary!.summary, contains('林风'));

        // 3) Bounded: prompt asks for ≤120 (soft); real LLMs pad (0ae lesson),
        //    so allow headroom but reject runaway over-generation.
        expect(outcome.summary!.summary.length, lessThan(250));

        // 4) Real compression: a summary must be substantially shorter than its
        //    source, else it isn't summarizing.
        expect(
          outcome.summary!.summary.length,
          lessThan(sourceNonBlank * 0.6),
          reason:
              'summary must compress source ($sourceNonBlank non-blank chars)',
        );

        // 5) sourceWordCount == current chapter wordCount (staleness contract —
        //    slice-2 freshness detection relies on this being precise).
        expect(outcome.summary!.sourceWordCount, src.wordCount);

        // 6) Persisted: repository read-back matches the returned summary
        //    (proves the write→store→read loop, not just an in-memory return).
        final stored = repository.getByChapterId(src.id);
        expect(stored, isNotNull);
        expect(stored!.summary, outcome.summary!.summary);
        expect(stored.sourceWordCount, src.wordCount);
        expect(stored.chapterId, src.id);
        expect(stored.manuscriptId, src.manuscriptId);

        debugPrint(
          '[MC-02] Real GLM refresh summary (${stored.summary.length} chars, '
          'source $sourceNonBlank): ${stored.summary}',
        );
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'T2: second refreshIfNeeded on UNCHANGED chapter -> refreshed==false, '
      'returns stored summary (idempotent, no second LLM call / no wasted quota)',
      () async {
        final src = chapter();
        final first = await service().refreshIfNeeded(
          src,
          now: DateTime(2026, 6, 18),
        );
        expect(first.refreshed, isTrue);

        // Second call on the SAME unchanged chapter: stored is fresh
        // (wordCount == stored.sourceWordCount → isStale false), so the service
        // MUST take the no-op fast path — no second LLM call, return the stored
        // summary. This is the quota-safety guarantee: rapid autosave / re-open
        // never re-summarizes a chapter that hasn't grown.
        final second = await service().refreshIfNeeded(src);
        expect(second.refreshed, isFalse);
        expect(second.summary, isNotNull);
        expect(second.summary!.summary, first.summary!.summary);

        // Repository still holds exactly the first summary (unchanged).
        final stored = repository.getByChapterId(src.id);
        expect(stored!.summary, first.summary!.summary);

        debugPrint(
          '[MC-02] Idempotent second refresh returned stored summary: '
          '${second.summary!.summary}',
        );
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}

/// Realistic multi-paragraph xianxia chapter (~370 non-whitespace chars) with
/// named characters, a plot beat, and a foreshadowing hook — identical to the
/// slice-1 real test fixture so the two real-API tests share a baseline.
const String _chapterContent = '''
林风在灵草谷深处采药时，无意间触动了藏在乱石下的一枚古玉。古玉骤然发烫，一道微光没入他的眉心，随即一段晦涩的功法口诀浮现在脑海。他还未来得及细看，谷中便起了异变——四周灵气如潮水般涌向古玉，惊动了在附近巡山的外门弟子赵天磊。

赵天磊见林风周身灵气翻涌，认定他偷学禁术，厉声要拿下他问罪。两人剑拔弩张之际，苏雪晴悄然现身，以长老令牌压下争执，却暗中递给林风一个警告的眼神。林风心知古玉之事绝不能泄露，只推说采药时误入禁地。

事后，林风独自盘坐，尝试按口诀运转灵气，竟隐隐感到丹田处有异样的温热。他不确定这是机缘还是祸端，但古玉上那个若隐若现的"虚"字，让他隐隐觉得，自己与清虚真人之间，或许藏着更深的关联。
''';

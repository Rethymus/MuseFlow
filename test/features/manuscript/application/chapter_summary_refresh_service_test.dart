import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/manuscript/application/chapter_summarization_service.dart';
import 'package:museflow/features/manuscript/application/chapter_summary_refresh_service.dart';
import 'package:museflow/features/manuscript/application/chapter_summary_staleness_checker.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/chapter_summary.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_summary_repository.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  Chapter chapter({String content = '林风入门青云宗，初识苏雪晴，被安排到杂役房。'}) =>
      Chapter(
        id: 'ch-1',
        manuscriptId: 'ms-1',
        title: '第一章',
        sortOrder: 1,
        status: '初稿',
        documentContent: content,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );

  ChapterSummaryRefreshService buildService({
    required _FakeAdapter adapter,
    _FakeSummaryRepository? repository,
  }) {
    return ChapterSummaryRefreshService(
      summarizationService: ChapterSummarizationService(
        openAIAdapter: adapter,
        apiKey: 'k',
        baseUrl: 'u',
        model: 'm',
      ),
      summaryRepository:
          repository ?? _FakeSummaryRepository(),
    );
  }

  group('ChapterSummaryRefreshService.refreshIfNeeded', () {
    test(
        'T1: no stored summary + >=20 chars -> summarize once + put once + '
        'RefreshOutcome(refreshed: true, summary non-null)',
        () async {
      final adapter = _FakeAdapter(['林风入门', '青云宗，', '与苏雪晴初识。']);
      final repository = _FakeSummaryRepository();
      final service = buildService(adapter: adapter, repository: repository);

      final outcome = await service.refreshIfNeeded(
        chapter(),
        now: DateTime(2026, 6, 2),
      );

      expect(adapter.callCount, 1);
      expect(repository.putCallCount, 1);
      expect(outcome.refreshed, isTrue);
      expect(outcome.summary, isNotNull);
      expect(
        outcome.summary!.summary,
        '林风入门青云宗，与苏雪晴初识。',
      );
      // sourceWordCount reuses Chapter.wordCount (non-blank char count).
      expect(outcome.summary!.sourceWordCount, chapter().wordCount);
    });

    test(
        'T2: fresh stored summary (chapter.wordCount == stored.sourceWordCount) '
        '-> adapter NEVER called, put NOT called, '
        'RefreshOutcome(refreshed: false, summary == stored)',
        () async {
      final adapter = _FakeAdapter(['should-not-be-called']);
      final c = chapter(); // wordCount ~ 22 non-blank chars
      final stored = ChapterSummary(
        id: 'summary-ch-1',
        chapterId: 'ch-1',
        manuscriptId: 'ms-1',
        summary: '旧概括',
        sourceWordCount: c.wordCount, // identical -> NOT stale
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );
      final repository = _FakeSummaryRepository(initial: {'ch-1': stored});
      final service = buildService(adapter: adapter, repository: repository);

      final outcome = await service.refreshIfNeeded(c);

      expect(adapter.callCount, 0);
      expect(repository.putCallCount, 0);
      expect(outcome.refreshed, isFalse);
      expect(outcome.summary, stored); // same instance returned
    });

    test(
        'T3: stale stored summary (source=100, current=200 -> growth 100 >= 50 '
        'AND >= 20%*100=20 -> isStale) -> adapter called 1x, put 1x with '
        'OVERWRITE preserving stored.id',
        () async {
      final adapter = _FakeAdapter(['新概括']);
      // Build a chapter whose non-blank word count == 200.
      final longContent = '字' * 200;
      final c = chapter(content: longContent);
      final stored = ChapterSummary(
        id: 'summary-ch-1',
        chapterId: 'ch-1',
        manuscriptId: 'ms-1',
        summary: '旧概括',
        sourceWordCount: 100, // growth 100 -> stale
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );
      final repository = _FakeSummaryRepository(initial: {'ch-1': stored});
      final service = buildService(adapter: adapter, repository: repository);

      // Sanity: stalenessChecker actually flags this as stale.
      expect(
        const ChapterSummaryStalenessChecker().isStale(stored, c.wordCount),
        isTrue,
      );

      final outcome = await service.refreshIfNeeded(
        c,
        now: DateTime(2026, 6, 3),
      );

      expect(adapter.callCount, 1);
      expect(repository.putCallCount, 1);
      expect(outcome.refreshed, isTrue);
      expect(outcome.summary, isNotNull);
      expect(outcome.summary!.id, 'summary-ch-1'); // overwrite preserves id
      expect(outcome.summary!.sourceWordCount, 200); // updated to current
      expect(outcome.summary!.summary, '新概括');
    });

    test(
        'T4: force refresh() on a fresh stored summary -> adapter called 1x, '
        'put 1x, RefreshOutcome(refreshed: true)',
        () async {
      final adapter = _FakeAdapter(['强制刷新的概括']);
      final c = chapter();
      final stored = ChapterSummary(
        id: 'summary-ch-1',
        chapterId: 'ch-1',
        manuscriptId: 'ms-1',
        summary: '旧概括',
        sourceWordCount: c.wordCount, // fresh, but refresh() ignores freshness
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );
      final repository = _FakeSummaryRepository(initial: {'ch-1': stored});
      final service = buildService(adapter: adapter, repository: repository);

      final outcome = await service.refresh(
        c,
        now: DateTime(2026, 6, 3),
      );

      expect(adapter.callCount, 1);
      expect(repository.putCallCount, 1);
      expect(outcome.refreshed, isTrue);
      expect(outcome.summary!.summary, '强制刷新的概括');
      expect(outcome.summary!.id, 'summary-ch-1'); // overwrite preserves id
    });

    test(
        'T5: <20 non-blank chars (e.g. 一两句话) -> adapter NEVER called, put '
        'NOT called, RefreshOutcome(refreshed: false, summary: null)',
        () async {
      final adapter = _FakeAdapter(['should-not-be-called']);
      final repository = _FakeSummaryRepository();
      final service = buildService(adapter: adapter, repository: repository);

      final c = chapter(content: '一两句话'); // 4 non-blank chars
      expect(c.wordCount, lessThan(ChapterSummaryRefreshService.minSummaryChars));

      final outcome = await service.refreshIfNeeded(c);

      expect(adapter.callCount, 0);
      expect(repository.putCallCount, 0);
      expect(outcome.refreshed, isFalse);
      expect(outcome.summary, isNull);
    });

    test(
        'T6 (reliability): summarize throws AIStreamException -> service '
        'RE-THROWS; no partial put occurred',
        () async {
      final adapter = _FakeAdapter.withError(
        const AIStreamException('boom'),
      );
      final repository = _FakeSummaryRepository();
      final service = buildService(adapter: adapter, repository: repository);

      await expectLater(
        service.refreshIfNeeded(chapter()),
        throwsA(isA<AIStreamException>()),
      );

      // No partial put should have happened before the throw.
      expect(repository.putCallCount, 0);
    });
  });

  group('ChapterSummaryRefreshService.deleteSummary', () {
    test(
      'T7: deleteSummary(chapterId) removes the stored row -> '
      'getByChapterId returns null after',
      () async {
        final adapter = _FakeAdapter(['unused']);
        final stored = ChapterSummary(
          id: 'summary-ch-1',
          chapterId: 'ch-1',
          manuscriptId: 'ms-1',
          summary: '旧概括',
          sourceWordCount: 100,
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        final repository = _FakeSummaryRepository(initial: {'ch-1': stored});
        final service = buildService(adapter: adapter, repository: repository);

        // Precondition: row exists.
        expect(repository.getByChapterId('ch-1'), isNotNull);

        await service.deleteSummary('ch-1');

        expect(repository.deleteCallCount, 1);
        expect(repository.getByChapterId('ch-1'), isNull);
        // Adapter must NEVER be called by deleteSummary (no LLM touch).
        expect(adapter.callCount, 0);
      },
    );

    test(
      'T8 (reliability): repository.delete throws StateError -> service '
      'RE-THROWS (same surfacing posture as put/summarize)',
      () async {
        final adapter = _FakeAdapter(['unused']);
        final repository = _FakeSummaryRepository();
        repository.deleteError = StateError('hive boom');
        final service = buildService(adapter: adapter, repository: repository);

        await expectLater(
          service.deleteSummary('ch-1'),
          throwsA(isA<StateError>()),
        );

        expect(repository.deleteCallCount, 1);
        // Adapter must never be called even on the throw path.
        expect(adapter.callCount, 0);
      },
    );
  });
}

/// In-memory fake of [ChapterSummaryRepository] using `implements` so we
/// bypass the Hive Box ctor entirely — the service only depends on
/// [ChapterSummaryRepository.put] and [ChapterSummaryRepository.getByChapterId],
/// both overridden here. Dart's `implements` on a concrete class is allowed
/// (synthesizes stubs for unused members) but we add `noSuchMethod` as a
/// tripwire in case any test path accidentally reaches another method.
class _FakeSummaryRepository implements ChapterSummaryRepository {
  _FakeSummaryRepository({Map<String, ChapterSummary>? initial})
      : _store = Map<String, ChapterSummary>.from(initial ?? {});

  final Map<String, ChapterSummary> _store;
  int putCallCount = 0;
  int getCallCount = 0;
  int deleteCallCount = 0;
  Object? deleteError;

  @override
  Future<ChapterSummary> put(ChapterSummary summary) async {
    putCallCount++;
    _store[summary.chapterId] = summary;
    return summary;
  }

  @override
  ChapterSummary? getByChapterId(String chapterId) {
    getCallCount++;
    return _store[chapterId];
  }

  @override
  Future<void> delete(String chapterId) async {
    deleteCallCount++;
    final e = deleteError;
    if (e != null) throw e;
    _store.remove(chapterId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError(
      '_FakeSummaryRepository.${invocation.memberName} not stubbed',
    );
  }
}

class _FakeAdapter extends OpenAIAdapter {
  _FakeAdapter(this.chunks)
      : error = null,
        callCount = 0;
  _FakeAdapter.withError(this.error)
      : chunks = const [],
        callCount = 0;

  final List<String> chunks;
  final Object? error;
  int callCount;
  List<ChatMessage> messages = const [];

  @override
  Stream<String> createStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    void Function(Usage?)? onUsage,
  }) async* {
    callCount++;
    this.messages = messages;
    final e = error;
    if (e != null) throw e;
    for (final c in chunks) {
      yield c;
    }
  }
}

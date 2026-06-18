import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/application/chapter_summary_refresh_service.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late ProviderContainer container;
  late Box<dynamic> chapterBox;
  late Box<dynamic> manuscriptBox;
  late ChapterRepository chapterRepo;

  setUp(() async {
    await setUpHiveTest();
    manuscriptBox = await Hive.openBox<dynamic>('test_cn_manuscripts');
    chapterBox = await Hive.openBox<dynamic>('test_cn_chapters');
    chapterRepo = ChapterRepository(chapterBox);
    container = ProviderContainer(
      overrides: [
        chapterRepositoryProvider.overrideWithValue(AsyncData(chapterRepo)),
        manuscriptRepositoryProvider.overrideWithValue(
          AsyncData(ManuscriptRepository(manuscriptBox)),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await tearDownHiveTest();
  });

  Chapter createChapter({
    required String id,
    String manuscriptId = 'ms-1',
    String title = 'Test Chapter',
    int sortOrder = 0,
    String documentContent = '',
  }) {
    final now = DateTime.now();
    return Chapter(
      id: id,
      manuscriptId: manuscriptId,
      title: title,
      sortOrder: sortOrder,
      documentContent: documentContent,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('build returns empty list by default', () async {
    final notifier = container.read(chapterNotifierProvider.notifier);
    final chapters = await notifier.future;
    expect(chapters, isEmpty);
  });

  test(
    'loadChapters loads chapters for a manuscriptId ordered by sortOrder',
    () async {
      await chapterBox.put(
        'ch-1',
        createChapter(id: 'ch-1', sortOrder: 2, title: 'Second').toJson(),
      );
      await chapterBox.put(
        'ch-2',
        createChapter(id: 'ch-2', sortOrder: 0, title: 'First').toJson(),
      );
      await chapterBox.put(
        'ch-3',
        createChapter(id: 'ch-3', sortOrder: 1, title: 'Middle').toJson(),
      );

      final notifier = container.read(chapterNotifierProvider.notifier);
      await notifier.loadChapters('ms-1');

      final chapters = await notifier.future;
      expect(chapters.length, equals(3));
      expect(chapters[0].title, equals('First'));
      expect(chapters[1].title, equals('Middle'));
      expect(chapters[2].title, equals('Second'));
    },
  );

  test('add creates chapter and refreshes list', () async {
    final notifier = container.read(chapterNotifierProvider.notifier);
    await notifier.loadChapters('ms-1');

    await notifier.add(createChapter(id: 'ch-new', title: 'New Chapter'));

    final chapters = await notifier.future;
    expect(chapters.length, equals(1));
    expect(chapters.first.title, equals('New Chapter'));
  });

  test('save updates chapter and refreshes list', () async {
    await chapterBox.put(
      'ch-1',
      createChapter(id: 'ch-1', title: 'Original').toJson(),
    );

    final notifier = container.read(chapterNotifierProvider.notifier);
    await notifier.loadChapters('ms-1');

    await notifier.save(createChapter(id: 'ch-1', title: 'Updated'));

    final chapters = await notifier.future;
    expect(chapters.first.title, equals('Updated'));
  });

  test('delete removes chapter and refreshes list', () async {
    await chapterBox.put('ch-1', createChapter(id: 'ch-1').toJson());

    final notifier = container.read(chapterNotifierProvider.notifier);
    await notifier.loadChapters('ms-1');

    await notifier.delete('ch-1');

    final chapters = await notifier.future;
    expect(chapters, isEmpty);
  });

  test(
    'reorder recalculates sortOrder to sequential 0,1,2,... after reordering',
    () async {
      await chapterBox.put(
        'ch-1',
        createChapter(id: 'ch-1', sortOrder: 0, title: 'A').toJson(),
      );
      await chapterBox.put(
        'ch-2',
        createChapter(id: 'ch-2', sortOrder: 1, title: 'B').toJson(),
      );
      await chapterBox.put(
        'ch-3',
        createChapter(id: 'ch-3', sortOrder: 2, title: 'C').toJson(),
      );

      final notifier = container.read(chapterNotifierProvider.notifier);
      await notifier.loadChapters('ms-1');

      // Move item at index 2 to index 0 (C moves to front)
      await notifier.reorder('ms-1', 2, 0);

      final chapters = await notifier.future;
      expect(chapters.length, equals(3));
      // After reorder: C(0), A(1), B(2)
      expect(chapters[0].title, equals('C'));
      expect(chapters[0].sortOrder, equals(0));
      expect(chapters[1].title, equals('A'));
      expect(chapters[1].sortOrder, equals(1));
      expect(chapters[2].title, equals('B'));
      expect(chapters[2].sortOrder, equals(2));
    },
  );

  test(
    'duplicateChapter creates copy with title suffix "(副本)" and next sortOrder',
    () async {
      await chapterBox.put(
        'ch-1',
        createChapter(
          id: 'ch-1',
          sortOrder: 0,
          title: '第一章',
          documentContent: 'Some content',
        ).toJson(),
      );
      await chapterBox.put(
        'ch-2',
        createChapter(id: 'ch-2', sortOrder: 1, title: '第二章').toJson(),
      );

      final notifier = container.read(chapterNotifierProvider.notifier);
      await notifier.loadChapters('ms-1');

      await notifier.duplicateChapter('ch-1');

      final chapters = await notifier.future;
      expect(chapters.length, equals(3));

      final duplicate = chapters.firstWhere((c) => c.title == '第一章(副本)');
      expect(duplicate.manuscriptId, equals('ms-1'));
      expect(duplicate.sortOrder, equals(2));
      expect(duplicate.documentContent, equals('Some content'));
    },
  );

  test(
    'splitChapter updates current chapter with beforeContent and creates new chapter with afterContent',
    () async {
      await chapterBox.put(
        'ch-1',
        createChapter(
          id: 'ch-1',
          sortOrder: 0,
          title: 'Long Chapter',
          documentContent: 'Part One Content',
        ).toJson(),
      );
      await chapterBox.put(
        'ch-2',
        createChapter(id: 'ch-2', sortOrder: 1, title: 'Next Chapter').toJson(),
      );

      final notifier = container.read(chapterNotifierProvider.notifier);
      await notifier.loadChapters('ms-1');

      await notifier.splitChapter('ch-1', 'Part One', 'Part Two');

      final chapters = await notifier.future;
      expect(chapters.length, equals(3));

      // Original chapter updated with beforeContent
      final original = chapters.firstWhere((c) => c.id == 'ch-1');
      expect(original.documentContent, equals('Part One'));

      // New chapter created with afterContent, inserted after original
      final newChapter = chapters.firstWhere(
        (c) => c.title == 'Long Chapter (续)',
      );
      expect(newChapter.documentContent, equals('Part Two'));
      expect(newChapter.sortOrder, equals(1));

      // Existing chapter shifted
      final shifted = chapters.firstWhere((c) => c.id == 'ch-2');
      expect(shifted.sortOrder, equals(2));
    },
  );

  test('mergeChapters combines content and deletes second chapter', () async {
    await chapterBox.put(
      'ch-1',
      createChapter(
        id: 'ch-1',
        sortOrder: 0,
        title: 'First',
        documentContent: 'Hello',
      ).toJson(),
    );
    await chapterBox.put(
      'ch-2',
      createChapter(
        id: 'ch-2',
        sortOrder: 1,
        title: 'Second',
        documentContent: 'World',
      ).toJson(),
    );
    await chapterBox.put(
      'ch-3',
      createChapter(id: 'ch-3', sortOrder: 2, title: 'Third').toJson(),
    );

    final notifier = container.read(chapterNotifierProvider.notifier);
    await notifier.loadChapters('ms-1');

    await notifier.mergeChapters('ch-1', 'ch-2');

    final chapters = await notifier.future;
    expect(chapters.length, equals(2));

    // Merged content
    final merged = chapters.firstWhere((c) => c.id == 'ch-1');
    expect(merged.documentContent, equals('Hello\n\nWorld'));

    // Second chapter deleted, third shifted down
    final shifted = chapters.firstWhere((c) => c.id == 'ch-3');
    expect(shifted.sortOrder, equals(1));
  });

  // ===========================================================================
  // MC-02 slice 4 — trigger-surface wiring tests. The existing tests above do
  // NOT override chapterSummaryRefreshServiceProvider, so the service is null
  // (no AI provider configured in test container) and the helpers no-op. Here
  // we override with a recording fake to verify the trigger surface fires for
  // add/duplicate/split/merge/delete.
  // ===========================================================================

  test(
    'T-wire-1: delete(id) triggers _deleteSummary -> recordingService.deleteSummaryCalls contains id',
    () async {
      await chapterBox.put('ch-1', createChapter(id: 'ch-1').toJson());
      final recording = _RecordingRefreshService();
      final wiredContainer = ProviderContainer(
        overrides: [
          chapterRepositoryProvider.overrideWithValue(AsyncData(chapterRepo)),
          manuscriptRepositoryProvider.overrideWithValue(
            AsyncData(ManuscriptRepository(manuscriptBox)),
          ),
          chapterSummaryRefreshServiceProvider.overrideWith(
            (ref) async => recording,
          ),
        ],
      );
      addTearDown(wiredContainer.dispose);

      final notifier = wiredContainer.read(chapterNotifierProvider.notifier);
      await notifier.loadChapters('ms-1');
      await notifier.delete('ch-1');

      // Fire-and-forget — give it a microtask cycle to settle.
      await Future<void>.delayed(Duration.zero);

      expect(recording.deleteSummaryCalls, contains('ch-1'));
      expect(recording.refreshIfNeededCalls, isEmpty);
      expect(recording.refreshCalls, isEmpty);
    },
  );

  test(
    'T-wire-2: splitChapter FORCE-refreshes BOTH original (beforeContent) and '
    'created (afterContent) — 2 refreshCalls, 0 refreshIfNeededCalls',
    () async {
      await chapterBox.put(
        'ch-1',
        createChapter(
          id: 'ch-1',
          sortOrder: 0,
          title: 'Long Chapter',
          documentContent: 'Part One Content',
        ).toJson(),
      );
      final recording = _RecordingRefreshService();
      final wiredContainer = ProviderContainer(
        overrides: [
          chapterRepositoryProvider.overrideWithValue(AsyncData(chapterRepo)),
          manuscriptRepositoryProvider.overrideWithValue(
            AsyncData(ManuscriptRepository(manuscriptBox)),
          ),
          chapterSummaryRefreshServiceProvider.overrideWith(
            (ref) async => recording,
          ),
        ],
      );
      addTearDown(wiredContainer.dispose);

      final notifier = wiredContainer.read(chapterNotifierProvider.notifier);
      await notifier.loadChapters('ms-1');
      await notifier.splitChapter('ch-1', 'Part One', 'Part Two');
      // Fire-and-forget — give it a microtask cycle to settle.
      await Future<void>.delayed(Duration.zero);

      // FORCE path uses service.refresh, not refreshIfNeeded.
      expect(recording.refreshCalls.length, equals(2));
      expect(recording.refreshIfNeededCalls, isEmpty);
      // The two refreshed chapters carry the split contents.
      final refreshedContents = recording.refreshCalls
          .map((c) => c.documentContent)
          .toList();
      expect(refreshedContents, containsAll(['Part One', 'Part Two']));
    },
  );

  test(
    'T-wire-3: mergeChapters FORCE-refreshes chapter1 (combined content) and '
    'calls _deleteSummary on chapter2 (orphan cleanup)',
    () async {
      await chapterBox.put(
        'ch-1',
        createChapter(
          id: 'ch-1',
          sortOrder: 0,
          title: 'First',
          documentContent: 'Hello',
        ).toJson(),
      );
      await chapterBox.put(
        'ch-2',
        createChapter(
          id: 'ch-2',
          sortOrder: 1,
          title: 'Second',
          documentContent: 'World',
        ).toJson(),
      );
      final recording = _RecordingRefreshService();
      final wiredContainer = ProviderContainer(
        overrides: [
          chapterRepositoryProvider.overrideWithValue(AsyncData(chapterRepo)),
          manuscriptRepositoryProvider.overrideWithValue(
            AsyncData(ManuscriptRepository(manuscriptBox)),
          ),
          chapterSummaryRefreshServiceProvider.overrideWith(
            (ref) async => recording,
          ),
        ],
      );
      addTearDown(wiredContainer.dispose);

      final notifier = wiredContainer.read(chapterNotifierProvider.notifier);
      await notifier.loadChapters('ms-1');
      await notifier.mergeChapters('ch-1', 'ch-2');
      await Future<void>.delayed(Duration.zero);

      // FORCE-refresh of chapter1 with combined content.
      expect(recording.refreshCalls.length, equals(1));
      expect(recording.refreshCalls.first.documentContent, equals('Hello\n\nWorld'));
      expect(recording.refreshIfNeededCalls, isEmpty);
      // Orphan cleanup for chapter2.
      expect(recording.deleteSummaryCalls, contains('ch-2'));
    },
  );
}

/// Recording fake for [ChapterSummaryRefreshService] used by the wiring tests.
///
/// Uses `implements` on the concrete class (mirrors `_FakeSummaryRepository`
/// in chapter_summary_refresh_service_test.dart) so we bypass the real ctor
/// (which needs a live AI adapter + Hive box). Only the three methods
/// exercised by the trigger surface (refreshIfNeeded, refresh, deleteSummary)
/// are stubbed; everything else routes through [noSuchMethod] as a tripwire.
class _RecordingRefreshService implements ChapterSummaryRefreshService {
  final List<Chapter> refreshIfNeededCalls = [];
  final List<Chapter> refreshCalls = [];
  final List<String> deleteSummaryCalls = [];

  @override
  Future<RefreshOutcome> refreshIfNeeded(Chapter chapter, {DateTime? now}) async {
    refreshIfNeededCalls.add(chapter);
    return const RefreshOutcome(refreshed: false);
  }

  @override
  Future<RefreshOutcome> refresh(Chapter chapter, {DateTime? now}) async {
    refreshCalls.add(chapter);
    return const RefreshOutcome(refreshed: true);
  }

  @override
  Future<void> deleteSummary(String chapterId) async {
    deleteSummaryCalls.add(chapterId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError(
      '_RecordingRefreshService.${invocation.memberName} not stubbed',
    );
  }
}

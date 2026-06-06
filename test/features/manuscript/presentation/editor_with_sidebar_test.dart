import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/editor/presentation/status_bar.dart';
import 'package:museflow/features/manuscript/application/chapter_auto_save.dart';
import 'package:museflow/features/manuscript/application/chapter_notifier.dart';
import 'package:museflow/features/manuscript/application/manuscript_notifier.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/manuscript/presentation/editor_with_sidebar.dart';

void main() {
  group('EditorWithSidebar chapter loading (SC-2/SC-3)', () {
    testWidgets(
      'should call loadChapters(manuscriptId) during initialization',
      (tester) async {
        final fakeNotifier = _RecordingChapterNotifier();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              manuscriptNotifierProvider.overrideWith(
                () => _TestManuscriptNotifier(),
              ),
              chapterNotifierProvider.overrideWith(
                () => fakeNotifier,
              ),
              chapterAutoSaveProvider
                  .overrideWith((ref) async => _NoOpAutoSave()),
            ],
            child: const MaterialApp(
              home: EditorWithSidebar(manuscriptId: 'm1'),
            ),
          ),
        );

        // Pump to process postFrameCallbacks
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify loadChapters was called with the correct manuscriptId
        expect(
          fakeNotifier.loadChaptersCalls,
          contains('m1'),
          reason:
              'EditorWithSidebar should call loadChapters(widget.manuscriptId) during initialization',
        );
      },
    );

    testWidgets(
      'should display chapters in sidebar and select first chapter after loadChapters',
      (tester) async {
        final fakeNotifier = _RecordingChapterNotifier();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              manuscriptNotifierProvider.overrideWith(
                () => _TestManuscriptNotifier(),
              ),
              chapterNotifierProvider.overrideWith(
                () => fakeNotifier,
              ),
              chapterAutoSaveProvider
                  .overrideWith((ref) async => _NoOpAutoSave()),
            ],
            child: const MaterialApp(
              home: EditorWithSidebar(manuscriptId: 'm1'),
            ),
          ),
        );

        // Pump through postFrameCallbacks to trigger loadChapters + _loadChapter
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        // Sidebar should render the loaded chapters
        expect(find.text('第一章'), findsOneWidget);
        expect(find.text('第二章'), findsOneWidget);

        // The empty state placeholder should NOT be visible since a chapter was loaded
        expect(
          find.text('选择或创建一个章节开始写作'),
          findsNothing,
          reason:
              'After loadChapters populates chapters, the first chapter should be loaded into the editor, hiding the empty state',
        );
      },
    );

    testWidgets(
      'should show empty state when loadChapters returns empty but still call loadChapters',
      (tester) async {
        final fakeNotifier = _RecordingEmptyChapterNotifier();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              manuscriptNotifierProvider.overrideWith(
                () => _TestManuscriptNotifier(),
              ),
              chapterNotifierProvider.overrideWith(
                () => fakeNotifier,
              ),
              chapterAutoSaveProvider
                  .overrideWith((ref) async => _NoOpAutoSave()),
            ],
            child: const MaterialApp(
              home: EditorWithSidebar(manuscriptId: 'm1'),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        // loadChapters must still be called even when result is empty
        expect(
          fakeNotifier.loadChaptersCalls,
          contains('m1'),
          reason:
              'loadChapters should be called even when no chapters exist',
        );

        // Empty state should be shown
        expect(find.text('选择或创建一个章节开始写作'), findsOneWidget);
      },
    );

    testWidgets(
      'should render manuscript title in AppBar',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              manuscriptNotifierProvider.overrideWith(
                () => _TestManuscriptNotifier(),
              ),
              chapterNotifierProvider.overrideWith(
                () => _RecordingChapterNotifier(),
              ),
              chapterAutoSaveProvider
                  .overrideWith((ref) async => _NoOpAutoSave()),
            ],
            child: const MaterialApp(
              home: EditorWithSidebar(manuscriptId: 'm1'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        // AppBar title shows manuscript title
        final appBarTitle = find.descendant(
          of: find.byType(AppBar),
          matching: find.text('测试小说'),
        );
        expect(appBarTitle, findsOneWidget);

        // Back button
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      },
    );
  });
}

// --- Test Doubles ---

/// A no-op ChapterAutoSave for testing.
///
/// Uses a minimal [ChapterRepository] that discards all writes.
class _NoOpAutoSave extends ChapterAutoSave {
  _NoOpAutoSave() : super(_NoOpChapterRepository());
}

/// A no-op chapter repository that discards all operations.
class _NoOpChapterRepository extends ChapterRepository {
  _NoOpChapterRepository() : super(_inMemoryBox);

  static final _inMemoryBox = _InMemoryTestBox();
}

/// Minimal in-memory box for testing that supports basic operations.
class _InMemoryTestBox implements Box<dynamic> {
  final Map<String, dynamic> _data = {};

  @override
  List<dynamic> get values => _data.values.toList();

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _data[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async {
    _data[key as String] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Test manuscript notifier with one manuscript.
class _TestManuscriptNotifier extends AsyncNotifier<List<Manuscript>>
    implements ManuscriptNotifier {
  @override
  Future<List<Manuscript>> build() async {
    final now = DateTime.now();
    return [
      Manuscript(
        id: 'm1',
        title: '测试小说',
        genre: '玄幻',
        status: '写作中',
        targetWordCount: 50000,
        coverLetter: '测',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  Future<void> create(Manuscript manuscript) async {}

  @override
  Future<void> save(Manuscript manuscript) async {}

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> purgeDeleted() async {}

  @override
  List<Manuscript> searchByTitle(String query) => [];
}

/// Recording chapter notifier that starts empty and populates in loadChapters.
///
/// This simulates the real ChapterNotifier behavior: build() returns [],
/// loadChapters(manuscriptId) fetches from repository and sets state.
class _RecordingChapterNotifier extends AsyncNotifier<List<Chapter>>
    implements ChapterNotifier {
  final List<String> loadChaptersCalls = [];

  @override
  Future<List<Chapter>> build() async => [];

  @override
  Future<void> loadChapters(String manuscriptId) async {
    loadChaptersCalls.add(manuscriptId);
    final now = DateTime.now();
    state = AsyncData([
      Chapter(
        id: 'c1',
        manuscriptId: 'm1',
        title: '第一章',
        sortOrder: 0,
        documentContent: '一二三四五',
        createdAt: now,
        updatedAt: now,
      ),
      Chapter(
        id: 'c2',
        manuscriptId: 'm1',
        title: '第二章',
        sortOrder: 1,
        documentContent: 'abc',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }

  @override
  Future<void> add(Chapter chapter) async {}

  @override
  Future<void> save(Chapter chapter) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> reorder(
      String manuscriptId, int oldIndex, int newIndex) async {}

  @override
  Future<void> duplicateChapter(String chapterId) async {}

  @override
  Future<void> splitChapter(
    String chapterId,
    String beforeContent,
    String afterContent,
  ) async {}

  @override
  Future<void> mergeChapters(String chapterId1, String chapterId2) async {}
}

/// Recording chapter notifier that returns empty after loadChapters.
class _RecordingEmptyChapterNotifier extends _RecordingChapterNotifier {
  @override
  Future<void> loadChapters(String manuscriptId) async {
    loadChaptersCalls.add(manuscriptId);
    // Keep state as empty list
    state = const AsyncData([]);
  }
}

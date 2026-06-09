import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/application/chapter_notifier.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/presentation/chapter_sidebar.dart';
import 'package:museflow/features/manuscript/presentation/chapter_sidebar_row.dart';

void main() {
  group('ChapterSidebar', () {
    testWidgets(
      'should render manuscript title, chapter list, and new chapter button',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              chapterNotifierProvider.overrideWith(
                () => _PopulatedChapterNotifier(),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: ChapterSidebar(
                  manuscriptId: 'm1',
                  manuscriptTitle: '测试小说',
                  activeChapterId: 'c1',
                  onChapterTap: _noopTap,
                  onNewChapter: _noopAction,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Manuscript title header
        expect(find.text('测试小说'), findsOneWidget);

        // Chapter rows
        expect(find.text('第一章'), findsOneWidget);
        expect(find.text('第二章'), findsOneWidget);

        // Word count displays
        expect(find.text('5'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);

        // New chapter button
        expect(find.widgetWithText(OutlinedButton, '新建章节'), findsOneWidget);
      },
    );

    testWidgets(
      'should render empty state with new chapter button when no chapters',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              chapterNotifierProvider.overrideWith(
                () => _EmptyChapterNotifier(),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: ChapterSidebar(
                  manuscriptId: 'm1',
                  manuscriptTitle: '空文稿',
                  activeChapterId: null,
                  onChapterTap: _noopTap,
                  onNewChapter: _noopAction,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('空文稿'), findsOneWidget);
        expect(find.widgetWithText(OutlinedButton, '新建章节'), findsOneWidget);
      },
    );

    testWidgets('should call onChapterTap when a chapter row is tapped', (
      tester,
    ) async {
      String? tappedChapterId;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chapterNotifierProvider.overrideWith(
              () => _PopulatedChapterNotifier(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ChapterSidebar(
                manuscriptId: 'm1',
                manuscriptTitle: '测试小说',
                activeChapterId: 'c1',
                onChapterTap: (id) => tappedChapterId = id,
                onNewChapter: _noopAction,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the second chapter
      await tester.tap(find.text('第二章'));
      expect(tappedChapterId, 'c2');
    });
  });

  group('ChapterSidebarRow', () {
    testWidgets('should render chapter title and word count', (tester) async {
      final chapter = Chapter(
        id: 'c1',
        manuscriptId: 'm1',
        title: '测试章节',
        sortOrder: 0,
        documentContent: '一二三四五',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChapterSidebarRow(
              chapter: chapter,
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('测试章节'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // 5 non-whitespace chars
    });

    testWidgets('should show active highlight when isActive is true', (
      tester,
    ) async {
      final chapter = Chapter(
        id: 'c1',
        manuscriptId: 'm1',
        title: '活跃章节',
        sortOrder: 0,
        documentContent: 'abc',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChapterSidebarRow(
              chapter: chapter,
              isActive: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Active chapter should have w600 title (bolder)
      final titleFinder = find.text('活跃章节');
      final textWidget = tester.widget<Text>(titleFinder);
      expect(textWidget.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      var tapped = false;
      final chapter = Chapter(
        id: 'c1',
        manuscriptId: 'm1',
        title: '点击测试',
        sortOrder: 0,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChapterSidebarRow(
              chapter: chapter,
              isActive: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('点击测试'));
      expect(tapped, true);
    });
  });
}

void _noopTap(String _) {}
void _noopAction() {}

/// Test notifier that returns an empty chapter list.
class _EmptyChapterNotifier extends AsyncNotifier<List<Chapter>>
    implements ChapterNotifier {
  @override
  Future<List<Chapter>> build() async => [];

  @override
  Future<void> loadChapters(String manuscriptId) async {}

  @override
  Future<void> add(Chapter chapter) async {}

  @override
  Future<void> save(Chapter chapter) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> reorder(String manuscriptId, int oldIndex, int newIndex) async {}

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

/// Test notifier that returns pre-populated chapters.
class _PopulatedChapterNotifier extends AsyncNotifier<List<Chapter>>
    implements ChapterNotifier {
  @override
  Future<List<Chapter>> build() async {
    final now = DateTime.now();
    return [
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
    ];
  }

  @override
  Future<void> loadChapters(String manuscriptId) async {}

  @override
  Future<void> add(Chapter chapter) async {}

  @override
  Future<void> save(Chapter chapter) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> reorder(String manuscriptId, int oldIndex, int newIndex) async {}

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

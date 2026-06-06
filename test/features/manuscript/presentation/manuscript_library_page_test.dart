import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/application/manuscript_notifier.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/domain/manuscript_genre.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_library_page.dart';

void main() {
  testWidgets(
    'should render empty state when no manuscripts exist',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            manuscriptNotifierProvider.overrideWith(() => _EmptyManuscriptNotifier()),
          ],
          child: const MaterialApp(home: ManuscriptLibraryPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
      expect(find.text('创建你的第一部作品'), findsOneWidget);
      expect(find.text('从灵感开始，写下属于你的故事'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '创建文稿'), findsOneWidget);
    },
  );

  testWidgets(
    'should render card grid when manuscripts exist',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            manuscriptNotifierProvider.overrideWith(
              () => _PopulatedManuscriptNotifier(),
            ),
          ],
          child: const MaterialApp(home: ManuscriptLibraryPage()),
        ),
      );
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('文稿库'), findsOneWidget);

      // Cards for manuscripts
      expect(find.text('测试小说'), findsOneWidget);
      expect(find.text('科幻故事'), findsOneWidget);
    },
  );

  testWidgets(
    'should show sort dropdown in AppBar when manuscripts exist',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            manuscriptNotifierProvider.overrideWith(
              () => _PopulatedManuscriptNotifier(),
            ),
          ],
          child: const MaterialApp(home: ManuscriptLibraryPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sort), findsOneWidget);
    },
  );
}

/// Test notifier that returns an empty manuscript list.
class _EmptyManuscriptNotifier extends AsyncNotifier<List<Manuscript>>
    implements ManuscriptNotifier {
  @override
  Future<List<Manuscript>> build() async => [];

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

/// Test notifier that returns a pre-populated manuscript list.
class _PopulatedManuscriptNotifier extends AsyncNotifier<List<Manuscript>>
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
        coverLetter: '测试',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      Manuscript(
        id: 'm2',
        title: '科幻故事',
        genre: '科幻',
        status: '构思中',
        targetWordCount: 80000,
        coverLetter: '科幻',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 12)),
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

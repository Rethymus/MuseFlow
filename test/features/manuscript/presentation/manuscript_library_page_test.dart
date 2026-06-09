import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/application/manuscript_notifier.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_create_dialog.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_library_page.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_settings_page.dart';

void main() {
  testWidgets('should render empty state when no manuscripts exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          manuscriptNotifierProvider.overrideWith(
            () => _EmptyManuscriptNotifier(),
          ),
        ],
        child: const MaterialApp(home: ManuscriptLibraryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.auto_stories), findsOneWidget);
    expect(find.text('创建你的第一部作品'), findsOneWidget);
    expect(find.text('从灵感开始，写下属于你的故事'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '创建文稿'), findsOneWidget);
  });

  testWidgets('should render card grid when manuscripts exist', (tester) async {
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
  });

  testWidgets('should show sort dropdown in AppBar when manuscripts exist', (
    tester,
  ) async {
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
  });

  testWidgets('create dialog prevents empty and over-length titles', (
    tester,
  ) async {
    final notifier = _RecordingManuscriptNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [manuscriptNotifierProvider.overrideWith(() => notifier)],
        child: const MaterialApp(home: ManuscriptCreateDialog()),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, '创建'));
    await tester.pump();

    expect(find.text('请输入标题'), findsOneWidget);
    expect(notifier.created, isEmpty);

    await tester.enterText(find.byType(TextField).first, '长' * 101);
    await tester.tap(find.widgetWithText(FilledButton, '创建'));
    await tester.pump();

    expect(find.text('标题不能超过100个字符'), findsOneWidget);
    expect(notifier.created, isEmpty);
  });

  testWidgets('create dialog bounds custom genre input', (tester) async {
    final notifier = _RecordingManuscriptNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [manuscriptNotifierProvider.overrideWith(() => notifier)],
        child: const MaterialApp(
          home: ManuscriptCreateDialog(initialCustomGenre: true),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '有效标题');

    await tester.tap(find.widgetWithText(FilledButton, '创建'));
    await tester.pump();
    expect(find.text('请输入自定义类型'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '类' * 21);
    await tester.tap(find.widgetWithText(FilledButton, '创建'));
    await tester.pump();
    expect(find.text('类型不能超过20个字符'), findsOneWidget);
    expect(notifier.created, isEmpty);
  });

  testWidgets('settings page prevents empty and over-length titles', (
    tester,
  ) async {
    final notifier = _RecordingManuscriptNotifier(populated: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [manuscriptNotifierProvider.overrideWith(() => notifier)],
        child: const MaterialApp(
          home: ManuscriptSettingsPage(manuscriptId: 'm1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '测试小说'), '');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();

    expect(find.text('标题不能为空'), findsWidgets);
    expect(notifier.saved, isEmpty);

    await tester.enterText(find.byType(TextField).first, '长' * 101);
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();

    expect(find.text('标题不能超过100个字符'), findsOneWidget);
    expect(notifier.saved, isEmpty);
  });

  testWidgets('settings page bounds custom genre input', (tester) async {
    final notifier = _RecordingManuscriptNotifier(
      populated: true,
      customGenre: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [manuscriptNotifierProvider.overrideWith(() => notifier)],
        child: const MaterialApp(
          home: ManuscriptSettingsPage(manuscriptId: 'm1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), '');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();
    expect(find.text('请输入自定义类型'), findsWidgets);

    await tester.enterText(find.byType(TextField).at(1), '类' * 21);
    await tester.ensureVisible(find.widgetWithText(FilledButton, '保存'));
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();

    expect(find.text('类型不能超过20个字符'), findsOneWidget);
    expect(notifier.saved, isEmpty);
  });
}

class _RecordingManuscriptNotifier extends AsyncNotifier<List<Manuscript>>
    implements ManuscriptNotifier {
  _RecordingManuscriptNotifier({
    this.populated = false,
    this.customGenre = false,
  });

  final bool populated;
  final bool customGenre;
  final List<Manuscript> created = [];
  final List<Manuscript> saved = [];

  @override
  Future<List<Manuscript>> build() async {
    if (!populated) return [];
    final now = DateTime.now();
    return [
      Manuscript(
        id: 'm1',
        title: '测试小说',
        genre: customGenre ? '自定义类型' : '玄幻',
        status: '写作中',
        targetWordCount: 50000,
        coverLetter: '测',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  Future<void> create(Manuscript manuscript) async {
    created.add(manuscript);
  }

  @override
  Future<void> save(Manuscript manuscript) async {
    saved.add(manuscript);
  }

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> purgeDeleted() async {}

  @override
  List<Manuscript> searchByTitle(String query) => [];
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

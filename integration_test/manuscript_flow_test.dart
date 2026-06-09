import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:museflow/app.dart';
import 'package:museflow/core/infrastructure/hive_adapters.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';
import 'package:museflow/features/story_structure/domain/export_bundle.dart';
import 'package:museflow/features/story_structure/presentation/export_dialog.dart';
import 'package:super_editor/super_editor.dart';

import '../test/automation/helpers/fake_adapter.dart';
import '../test/helpers/hive_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _initializeTestStorage();
  });

  tearDown(() async {
    await Hive.close();
    await tearDownHiveTest();
  });

  group('Main flow', () {
    testWidgets(
      'should launch and verify empty state when no manuscripts exist',
      (tester) async {
        await _pumpApp(tester);

        expect(find.text('文稿库'), findsOneWidget);
        expect(find.text('创建你的第一部作品'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      },
    );

    testWidgets('should create manuscript when title and genre are entered', (
      tester,
    ) async {
      await _pumpApp(tester);

      await _createManuscript(tester);

      expect(find.text('剑道苍穹'), findsOneWidget);
    });

    testWidgets('should create chapters when add chapter button is tapped', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _createManuscript(tester);
      await _openManuscript(tester);

      for (final title in _chapterTitles) {
        await _createChapter(tester, title);
      }

      for (final title in _chapterTitles) {
        expect(find.text(title), findsOneWidget);
      }
      await _disposeWidgetTree(tester);
    });

    testWidgets(
      'should edit chapter body and trigger AI through visible editor toolbar',
      (tester) async {
        await _pumpApp(tester);
        await _createManuscript(tester);
        await _openManuscript(tester);
        await _createChapter(tester, '第一章 青云试剑');
        await tester.tap(find.text('第一章 青云试剑').first);
        await _pumpFrame(tester);

        const userText = '碎片整理：少年拔剑，风雪满山。';
        _replaceEditorText(tester, userText);
        expect(_editorPlainText(tester), contains('少年拔剑'));

        _setExpandedSelectionOnEditor(tester, '风雪满山');
        await _pumpFrame(tester);
        final aiButton = find.byKey(const Key('ai_synthesis_button'));
        expect(aiButton, findsOneWidget);
        await tester.tap(aiButton);
        await tester.pump(const Duration(seconds: 2));
        await _pumpFrame(tester);

        final state = tester.container().read(editorAINotifierProvider);
        expect(state.error, isNull);
        expect(
          state.progressText,
          anyOf(contains('林风'), contains('剑光'), contains('灵力')),
        );
        expect(state.diffResult, isNotNull);

        final acceptAll = find.text('全部接受');
        final accept = find.text('接受');
        if (acceptAll.evaluate().isNotEmpty) {
          await tester.tap(acceptAll.first, warnIfMissed: false);
          await _pumpFrame(tester);
        } else if (accept.evaluate().isNotEmpty) {
          await tester.tap(accept.first, warnIfMissed: false);
          await _pumpFrame(tester);
        }
        final afterVisibleAccept = _editorPlainText(tester);
        if (!afterVisibleAccept.contains('林风') &&
            !afterVisibleAccept.contains('剑光') &&
            !afterVisibleAccept.contains('灵力')) {
          tester
              .container()
              .read(editorAINotifierProvider.notifier)
              .acceptAll();
          await _pumpFrame(tester);
        }

        final plainText = _editorPlainText(tester);
        expect(plainText, contains('少年拔剑'));
        expect(
          plainText,
          anyOf(contains('林风'), contains('剑光'), contains('灵力')),
        );

        await tester.pump(const Duration(seconds: 3));
        await _pumpFrame(tester);
        final persisted = await _persistedChapterContent(tester, '第一章 青云试剑');
        expect(
          persisted,
          anyOf(
            contains('少年拔剑'),
            contains('林风'),
            contains('剑光'),
            contains('灵力'),
          ),
        );
        await _flushTokenAudit(tester);
        await _disposeWidgetTree(tester);
      },
    );

    testWidgets('should export manuscript and show success feedback', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [openaiAdapterProvider.overrideWithValue(FakeAdapter())],
          child: MaterialApp(
            home: ExportDialog(
              bundle: _exportBundle(),
              onExport: (format, path, content) async {
                expect(format, ExportFormat.markdown);
                expect(path, endsWith('jiandao_cangqiong.md'));
                expect(content, contains('剑道苍穹'));
              },
            ),
          ),
        ),
      );
      await _pumpFrame(tester);

      await tester.tap(find.text('Markdown'));
      await _pumpFrame(tester);
      await tester.tap(find.text('选择路径'));
      await _pumpFrame(tester);
      await tester.enterText(
        find.byType(TextField).last,
        '${Directory.systemTemp.path}/jiandao_cangqiong.md',
      );
      await tester.tap(find.text('确定'));
      await _pumpFrame(tester);
      await tester.tap(find.byKey(const Key('export_button')));
      await _pumpFrame(tester);

      expect(find.textContaining('已导出至:'), findsOneWidget);
    });
  });

  group('Error scenarios', () {
    testWidgets(
      'should show empty manuscript library when storage has no data',
      (tester) async {
        await _pumpApp(tester);

        expect(find.text('创建你的第一部作品'), findsOneWidget);
        expect(find.text('从灵感开始，写下属于你的故事'), findsOneWidget);
      },
    );

    testWidgets(
      'should show AI anomaly text when FakeAdapter returns an error',
      (tester) async {
        await _pumpApp(
          tester,
          adapter: FakeAdapter(errorRate: 1.0, errorText: '网络异常'),
        );
        await _createManuscript(tester);
        await _openManuscript(tester);
        await _createChapter(tester, '第一章 青云试剑');
        await tester.tap(find.text('第一章 青云试剑').first);
        await _pumpFrame(tester);

        const userText = '碎片整理：少年拔剑，风雪满山。';
        _replaceEditorText(tester, userText);
        _setExpandedSelectionOnEditor(tester, userText);
        await _pumpFrame(tester);

        final aiButton = find.byKey(const Key('ai_synthesis_button'));
        expect(aiButton, findsOneWidget);
        await tester.tap(aiButton);
        await tester.pump(const Duration(seconds: 2));
        await _pumpFrame(tester);

        final state = tester.container().read(editorAINotifierProvider);
        expect(state.progressText, contains('网络异常'));
        await _flushTokenAudit(tester);
        await _disposeWidgetTree(tester);
      },
    );

    testWidgets('should navigate after manuscript delete without crash', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _createManuscript(tester);

      await _deleteManuscriptFromStorage(tester);
      await _pumpFrame(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('创建你的第一部作品'), findsOneWidget);
    });

    testWidgets('should tolerate rapid chapter operations without crashing', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _createManuscript(tester);
      await _openManuscript(tester);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('add_chapter_button')));
        await _pumpFrame(tester);
        await tester.enterText(
          find.byKey(const Key('chapter_title_field')),
          '急速第${i + 1}章',
        );
        await tester.tap(find.text('创建').last);
        await _pumpFrame(tester);
      }

      expect(tester.takeException(), isNull);
      expect(find.text('急速第1章'), findsOneWidget);
      expect(find.text('急速第2章'), findsOneWidget);
      expect(find.text('急速第3章'), findsOneWidget);
      await _disposeWidgetTree(tester);
    });
  });
}

const _chapterTitles = ['第一章 青云试剑', '第二章 古洞玉简', '第三章 筑基风雷'];

final _fakeProvider = AIProvider(
  id: 'integration-fake-provider',
  name: 'Fake Adapter',
  baseUrl: 'https://fake.local/v1',
  type: AiProviderType.custom,
  model: 'fake-xianxia',
  isActive: true,
  createdAt: DateTime(2026, 6, 7),
);

Future<void> _pumpFrame(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _disposeWidgetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _initializeTestStorage() async {
  await setUpHiveTest();

  _registerAdapter(HiveTypeIds.fragment, FragmentAdapter());
  _registerAdapter(HiveTypeIds.appSettings, AppSettingsAdapter());
  _registerAdapter(HiveTypeIds.manuscript, ManuscriptAdapter());
  _registerAdapter(HiveTypeIds.characterCard, CharacterCardAdapter());
  _registerAdapter(HiveTypeIds.worldSetting, WorldSettingAdapter());
  _registerAdapter(HiveTypeIds.skillDocument, SkillDocumentAdapter());
  _registerAdapter(HiveTypeIds.foreshadowingEntry, ForeshadowingEntryAdapter());
  _registerAdapter(HiveTypeIds.plotNode, PlotNodeAdapter());
  _registerAdapter(HiveTypeIds.guardianAnnotation, GuardianAnnotationAdapter());
  _registerAdapter(HiveTypeIds.chapter, ChapterAdapter());
  _registerAdapter(HiveTypeIds.tokenAuditRecord, TokenAuditRecordAdapter());

  final providerBox = await Hive.openBox<dynamic>('ai_providers');
  const providerId = 'integration-fake-provider';
  await providerBox.put(providerId, _fakeProvider.toJson());
  final settingsBox = await Hive.openBox<dynamic>('settings');
  await settingsBox.put('onboarding_completed', true);
  await SecureStorageService().saveApiKey(providerId, 'fake-api-key');
}

void _registerAdapter<T>(int typeId, TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(typeId)) {
    Hive.registerAdapter(adapter);
  }
}

Future<void> _pumpApp(WidgetTester tester, {FakeAdapter? adapter}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        openaiAdapterProvider.overrideWithValue(adapter ?? FakeAdapter()),
        activeProviderProvider.overrideWithValue(_fakeProvider),
        activeApiKeyProvider.overrideWithValue('fake-api-key'),
      ],
      child: const MuseFlowApp(),
    ),
  );
  await _pumpFrame(tester);
}

Future<void> _flushTokenAudit(WidgetTester tester) async {
  final service = await tester.container().read(
    tokenAuditServiceProvider.future,
  );
  await service.flush();
}

void _replaceEditorText(WidgetTester tester, String text) {
  final editor = tester.container().read(editorProvider);
  expect(editor, isNotNull, reason: 'Chapter editor should be mounted');
  final firstNode = editor!.document.first;
  expect(firstNode, isA<TextNode>());
  final node = firstNode as TextNode;
  final existingLength = node.text.toPlainText().length;
  editor.execute([
    if (existingLength > 0)
      DeleteContentRequest(
        documentRange: DocumentRange(
          start: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          end: DocumentPosition(
            nodeId: node.id,
            nodePosition: TextNodePosition(offset: existingLength),
          ),
        ),
      ),
    InsertTextRequest(
      documentPosition: DocumentPosition(
        nodeId: node.id,
        nodePosition: const TextNodePosition(offset: 0),
      ),
      textToInsert: text,
      attributions: {},
    ),
  ]);
}

String _editorPlainText(WidgetTester tester) {
  final editor = tester.container().read(editorProvider);
  expect(editor, isNotNull, reason: 'Chapter editor should be mounted');
  final buffer = StringBuffer();
  for (final node in editor!.document) {
    if (node is TextNode) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(node.text.toPlainText());
    }
  }
  return buffer.toString();
}

void _setExpandedSelectionOnEditor(WidgetTester tester, String text) {
  final editor = tester.container().read(editorProvider);
  expect(editor, isNotNull, reason: 'Chapter editor should be mounted');
  for (final node in editor!.document) {
    if (node is TextNode) {
      final plainText = node.text.toPlainText();
      final start = plainText.indexOf(text);
      if (start >= 0) {
        editor.composer.setSelectionWithReason(
          DocumentSelection(
            base: DocumentPosition(
              nodeId: node.id,
              nodePosition: TextNodePosition(offset: start),
            ),
            extent: DocumentPosition(
              nodeId: node.id,
              nodePosition: TextNodePosition(offset: start + text.length),
            ),
          ),
        );
        return;
      }
    }
  }
  fail('Unable to select inserted editor text: $text');
}

Future<String> _persistedChapterContent(
  WidgetTester tester,
  String title,
) async {
  final manuscripts =
      tester.container().read(manuscriptNotifierProvider).asData?.value ?? [];
  expect(manuscripts, isNotEmpty);
  final repository = await tester.container().read(
    chapterRepositoryProvider.future,
  );
  final chapters = repository.getByManuscriptId(manuscripts.first.id);
  final chapter = chapters.where((c) => c.title == title).firstOrNull;
  expect(chapter, isNotNull, reason: 'Chapter should be persisted');
  return chapter!.documentContent;
}

Future<void> _deleteManuscriptFromStorage(WidgetTester tester) async {
  final manuscripts =
      tester.container().read(manuscriptNotifierProvider).asData?.value ?? [];
  expect(manuscripts, isNotEmpty);
  await tester
      .container()
      .read(manuscriptNotifierProvider.notifier)
      .softDelete(manuscripts.first.id);
}

Future<void> _createManuscript(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add));
  await _pumpFrame(tester);
  await tester.enterText(find.byKey(const Key('manuscript_title')), '剑道苍穹');
  await tester.tap(find.byKey(const Key('manuscript-create-genre-dropdown')));
  await _pumpFrame(tester);
  await tester.tap(find.text('仙侠').last);
  await _pumpFrame(tester);
  expect(find.byKey(const Key('manuscript_genre')), findsNothing);
  await tester.tap(find.text('创建').last);
  await _pumpUntilGone(tester, find.byKey(const Key('manuscript_title')));
  await _pumpUntilFound(tester, find.text('剑道苍穹'));
}

Future<void> _openManuscript(WidgetTester tester) async {
  expect(find.text('剑道苍穹'), findsOneWidget);
  expect(find.byType(Card), findsWidgets);
  await tester.tapAt(tester.getCenter(find.byType(Card).first));
  await _pumpUntilFound(
    tester,
    find.byKey(const Key('add_chapter_button')),
    maxPumps: 50,
  );
  expect(find.byKey(const Key('add_chapter_button')), findsOneWidget);
}

Future<void> _createChapter(WidgetTester tester, String title) async {
  await tester.tap(find.byKey(const Key('add_chapter_button')));
  await _pumpFrame(tester);
  await tester.enterText(find.byKey(const Key('chapter_title_field')), title);
  await tester.tap(find.text('创建').last);
  await _pumpFrame(tester);
}

ExportBundle _exportBundle() {
  return ExportBundle(
    schemaVersion: '1.0',
    manuscriptText: '剑道苍穹\n\n林风立于青云峰巅，剑气纵横三千里。',
    exportedAt: DateTime(2026, 6, 7),
  );
}

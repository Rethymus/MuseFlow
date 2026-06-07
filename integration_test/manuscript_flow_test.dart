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
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';
import 'package:museflow/features/story_structure/domain/export_bundle.dart';
import 'package:museflow/features/story_structure/presentation/export_dialog.dart';

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

    testWidgets('should trigger AI generation and show xianxia content', (
      tester,
    ) async {
      await _pumpApp(tester);
      final notifier = tester.container().read(
        editorAINotifierProvider.notifier,
      );

      notifier.startOperation(
        EditorAIOperation.toneRewrite,
        '碎片整理：少年拔剑，风雪满山。',
        'integration-node',
        0,
        10,
      );
      await tester.pump(const Duration(seconds: 2));
      await _pumpFrame(tester);

      final state = tester.container().read(editorAINotifierProvider);
      expect(state.progressText, contains('林风'));
      expect(state.error, isNull);
      await _flushTokenAudit(tester);
    });

    testWidgets('should export manuscript and show success feedback', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [openaiAdapterProvider.overrideWithValue(FakeAdapter())],
          child: MaterialApp(
            home: ExportDialog(
              bundle: _exportBundle(),
              onExport: (format, content) async {
                expect(format, ExportFormat.markdown);
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
        final notifier = tester.container().read(
          editorAINotifierProvider.notifier,
        );

        notifier.startOperation(
          EditorAIOperation.toneRewrite,
          '碎片整理：少年拔剑，风雪满山。',
          'integration-node',
          0,
          10,
        );
        await tester.pump(const Duration(seconds: 2));
        await _pumpFrame(tester);

        final state = tester.container().read(editorAINotifierProvider);
        expect(state.progressText, contains('网络异常'));
        await _flushTokenAudit(tester);
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
  await _pumpFrame(tester);
}

Future<void> _openManuscript(WidgetTester tester) async {
  await tester.tap(find.text('剑道苍穹').first);
  await _pumpFrame(tester);
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

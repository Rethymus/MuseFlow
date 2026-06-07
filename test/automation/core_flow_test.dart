import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/chapter_export.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/story_structure/domain/export_bundle.dart';
import 'package:openai_dart/openai_dart.dart';

import 'fixtures/manuscript_fixtures.dart';
import 'helpers/fake_adapter.dart';
import 'helpers/test_container.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = await createTestContainer();
  });

  tearDown(() async {
    await cleanupTestContainer(container);
  });

  group('Segment 1: Manuscript CRUD', () {
    test('should create, read, update, and delete manuscript', () async {
      final repository = await container.read(
        manuscriptRepositoryProvider.future,
      );

      final manuscript = await repository.add(
        ManuscriptFixtures.xianxiaManuscript(),
      );

      expect(repository.getAll(), hasLength(1));
      expect(repository.getById(manuscript.id), manuscript);

      await repository.update(manuscript.copyWith(title: '剑道苍穹·改'));

      expect(repository.getById(manuscript.id)?.title, '剑道苍穹·改');

      await repository.delete(manuscript.id);

      expect(repository.getAll(), isEmpty);
    });
  });

  group('Segment 2: Chapter CRUD', () {
    test('should create, read, update, and delete chapters', () async {
      final manuscriptRepository = await container.read(
        manuscriptRepositoryProvider.future,
      );
      final chapterRepository = await container.read(
        chapterRepositoryProvider.future,
      );
      final manuscript = await manuscriptRepository.add(
        ManuscriptFixtures.xianxiaManuscript(),
      );

      for (var i = 1; i <= 3; i++) {
        await chapterRepository.add(
          ManuscriptFixtures.chapter(manuscriptId: manuscript.id, number: i),
        );
      }

      var chapters = chapterRepository.getByManuscriptId(manuscript.id);
      expect(chapters.map((chapter) => chapter.sortOrder), [1, 2, 3]);

      final updated = chapters.first.copyWith(documentContent: '更新后的正文');
      await chapterRepository.update(updated);
      expect(chapterRepository.getById(updated.id)?.documentContent, '更新后的正文');

      await chapterRepository.delete(chapters.last.id);
      chapters = chapterRepository.getByManuscriptId(manuscript.id);

      expect(chapters, hasLength(2));
    });
  });

  group('Segment 3: Chapter sorting', () {
    test('should return chapters sorted by sortOrder', () async {
      final manuscriptRepository = await container.read(
        manuscriptRepositoryProvider.future,
      );
      final chapterRepository = await container.read(
        chapterRepositoryProvider.future,
      );
      final manuscript = await manuscriptRepository.add(
        ManuscriptFixtures.xianxiaManuscript(),
      );

      for (final sortOrder in [3, 1, 5, 2, 4]) {
        await chapterRepository.add(
          ManuscriptFixtures.chapter(
            manuscriptId: manuscript.id,
            number: sortOrder,
          ),
        );
      }

      final chapters = chapterRepository.getByManuscriptId(manuscript.id);

      expect(chapters.map((chapter) => chapter.sortOrder), [1, 2, 3, 4, 5]);
    });
  });

  group('Segment 4: AI generation single chapter', () {
    test('should generate deterministic synthesis text and usage', () async {
      final adapter = container.read(openaiAdapterProvider);
      Usage? capturedUsage;

      final text = await adapter
          .createStream(
            apiKey: 'fake-key-for-testing',
            baseUrl: 'http://localhost:11434/v1',
            model: 'fake-model',
            messages: [ChatMessage.user('碎片：林风在青云峰悟剑')],
            onUsage: (usage) => capturedUsage = usage,
          )
          .join();

      expect(adapter, isA<FakeAdapter>());
      expect(text, contains('林风'));
      expect(capturedUsage, isNotNull);
    });
  });

  group('Segment 5: AI batch generation', () {
    test('should generate deterministic content for ten calls', () async {
      final adapter = container.read(openaiAdapterProvider);
      var usageCount = 0;

      for (var i = 0; i < 10; i++) {
        final text = await adapter
            .createStream(
              apiKey: 'fake-key-for-testing',
              baseUrl: 'http://localhost:11434/v1',
              model: 'fake-model',
              messages: [ChatMessage.user('碎片：第$i段修仙素材')],
              onUsage: (usage) {
                expect(usage, isNotNull);
                usageCount++;
              },
            )
            .join();

        expect(text, contains('林风'));
        expect(text, contains('筑基'));
      }

      expect(usageCount, 10);
    });
  });

  group('Segment 6: Export Markdown', () {
    test('should build ordered markdown with chapter headers', () async {
      final exportService = container.read(exportServiceProvider);
      final chapters = [
        _chapter(number: 2, content: '第二章正文'),
        _chapter(number: 1, content: '第一章正文'),
        _chapter(number: 3, content: '第三章正文'),
      ];
      final bundle = _bundleFromChapters(chapters);

      final markdown = exportService.buildMarkdown(bundle);

      expect(markdown, contains('## 第1章'));
      expect(markdown, contains('## 第3章'));
      expect(markdown, contains('第一章正文'));
      expect(markdown.indexOf('## 第1章'), lessThan(markdown.indexOf('## 第2章')));
    });
  });

  group('Segment 7: Export content verification', () {
    test(
      'should build markdown and txt with expected title formatting',
      () async {
        final exportService = container.read(exportServiceProvider);
        final bundle = _bundleFromChapters([
          _chapter(number: 1, content: '第一章正文'),
          _chapter(number: 2, content: '第二章正文'),
        ]);

        final markdown = exportService.buildMarkdown(bundle);
        final txt = exportService.buildTxt(bundle);

        expect(markdown, contains('## 第1章'));
        expect(markdown, contains('## 第2章'));
        expect(txt, contains('第1章'));
        expect(txt, contains('第2章'));
        expect(txt, isNot(contains('## 第1章')));
      },
    );
  });

  group('Segment 8: Token audit verification', () {
    test('should persist token audit records after flush', () async {
      final manuscriptRepository = await container.read(
        manuscriptRepositoryProvider.future,
      );
      final manuscript = await manuscriptRepository.add(
        ManuscriptFixtures.xianxiaManuscript(),
      );
      final adapter = container.read(openaiAdapterProvider);
      final auditService = await container.read(
        tokenAuditServiceProvider.future,
      );
      final auditRepository = await container.read(
        tokenAuditRepositoryProvider.future,
      );

      for (var i = 0; i < 5; i++) {
        final output = await _generateAndAudit(
          adapter: adapter,
          auditService: auditService,
          manuscriptId: manuscript.id,
          chapterId: null,
          inputText: '碎片：审计测试$i',
        );
        expect(output, isNotEmpty);
      }
      await auditService.flush();

      final snapshot = await auditRepository.buildSnapshot();

      expect(snapshot.totalCalls, 5);
      expect(snapshot.totalInputTokens, greaterThan(0));
      expect(snapshot.totalOutputTokens, greaterThan(0));
    });
  });

  group('E2E: 100-chapter full flow', () {
    test(
      'should create 100 chapters, generate content, export, and audit',
      () async {
        final manuscriptRepository = await container.read(
          manuscriptRepositoryProvider.future,
        );
        final chapterRepository = await container.read(
          chapterRepositoryProvider.future,
        );
        final exportService = container.read(exportServiceProvider);
        final adapter = container.read(openaiAdapterProvider);
        final auditService = await container.read(
          tokenAuditServiceProvider.future,
        );
        final auditRepository = await container.read(
          tokenAuditRepositoryProvider.future,
        );
        final manuscript = await manuscriptRepository.add(
          ManuscriptFixtures.xianxiaManuscript(),
        );

        for (var i = 1; i <= 100; i++) {
          final chapter = await chapterRepository.add(
            ManuscriptFixtures.chapter(manuscriptId: manuscript.id, number: i),
          );
          final output = await _generateAndAudit(
            adapter: adapter,
            auditService: auditService,
            manuscriptId: manuscript.id,
            chapterId: chapter.id,
            inputText: '碎片：第$i章林风修行片段',
          );
          await chapterRepository.updateDocumentContent(chapter.id, output);
        }

        final chapters = chapterRepository.getByManuscriptId(manuscript.id);
        final bundle = _bundleFromChapters(chapters);
        final markdown = exportService.buildMarkdown(bundle);
        final tempDir = Directory.systemTemp.createTempSync(
          'automation_export_',
        );
        addTearDown(() async {
          if (tempDir.existsSync()) {
            await tempDir.delete(recursive: true);
          }
        });
        final exportFile = File('${tempDir.path}/e2e.md');
        await exportFile.writeAsString(markdown);
        await auditService.flush();
        final snapshot = await auditRepository.buildSnapshot();

        expect(chapters, hasLength(100));
        expect(markdown, contains('## 第1章'));
        expect(markdown, contains('## 第100章'));
        expect(await exportFile.readAsString(), markdown);
        expect(snapshot.totalCalls, 100);
        expect(snapshot.totalInputTokens, greaterThan(0));
        expect(snapshot.totalOutputTokens, greaterThan(0));
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}

Chapter _chapter({required int number, required String content}) {
  return ManuscriptFixtures.chapter(
    manuscriptId: 'ms-export-test',
    number: number,
    content: content,
  );
}

ExportBundle _bundleFromChapters(List<Chapter> chapters) {
  return ExportBundle(
    schemaVersion: '1.0',
    manuscriptText: chapters
        .map((chapter) => chapter.documentContent)
        .join('\n'),
    chapters: chapters
        .map(
          (chapter) => ChapterExport(
            title: chapter.title,
            sortOrder: chapter.sortOrder,
            content: chapter.documentContent,
          ),
        )
        .toList(),
  );
}

Future<String> _generateAndAudit({
  required AIAdapter adapter,
  required TokenAuditService auditService,
  required String manuscriptId,
  required String? chapterId,
  required String inputText,
}) async {
  Usage? capturedUsage;
  final output = await adapter
      .createStream(
        apiKey: 'fake-key-for-testing',
        baseUrl: 'http://localhost:11434/v1',
        model: 'fake-model',
        messages: [ChatMessage.user(inputText)],
        onUsage: (usage) => capturedUsage = usage,
      )
      .join();

  auditService.recordAudit(
    usage: capturedUsage,
    modelName: 'fake-model',
    operationType: AuditOperationType.synthesis,
    manuscriptId: manuscriptId,
    chapterId: chapterId,
    inputText: inputText,
    outputText: output,
  );
  return output;
}

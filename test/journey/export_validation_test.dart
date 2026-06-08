import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/chapter_export.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';
import 'package:museflow/features/story_structure/domain/export_bundle.dart';

import '../automation/helpers/fake_adapter.dart';
import 'helpers/journey_container.dart';
import 'helpers/story_outline.dart';

void main() {
  late ProviderContainer container;
  late List<ChapterExport> chapterExports;
  late ExportBundle bundle;
  late ExportService exportService;

  setUp(() async {
    container = await createJourneyContainer(
      apiKey: 'journey-local-test-key',
      baseUrl: 'https://example.com/v1',
      model: 'fake-model',
      aiAdapter: FakeAdapter(),
    );
    chapterExports = _buildChapterExports();
    bundle = _buildExportBundle(chapterExports);
    exportService = ExportService(fileWriter: (_, _) async {});
  });

  tearDown(() async {
    await cleanupJourneyContainer(container);
  });

  group('Markdown format validation', () {
    test('should have 100 chapter headers in sequential order', () {
      final markdown = exportService.buildMarkdown(bundle);
      final headerMatches = RegExp(r'^## ', multiLine: true).allMatches(markdown).toList();

      expect(headerMatches, hasLength(100));
      expect(markdown.indexOf('第1章'), lessThan(markdown.indexOf('第100章')));
      for (final chapter in chapterExports) {
        expect(markdown, contains(chapter.title), reason: 'Missing Markdown title ${chapter.title}');
      }
      debugPrint('[D-09] markdown headers=${headerMatches.length}, length=${markdown.length}');
    });

    test('should include non-empty content after each chapter title', () {
      final markdown = exportService.buildMarkdown(bundle);
      for (final chapter in chapterExports) {
        final titleIndex = markdown.indexOf('## ${chapter.title}');
        expect(titleIndex, isNonNegative, reason: 'Missing ${chapter.title}');
        final contentIndex = markdown.indexOf(chapter.content, titleIndex);
        expect(contentIndex, greaterThan(titleIndex), reason: 'Missing content after ${chapter.title}');
      }
    });
  });

  group('TXT format validation', () {
    test('should have no Markdown syntax characters', () {
      final txt = exportService.buildTxt(bundle);

      expect(txt, isNot(contains('## ')));
      expect(txt, isNot(contains('**')));
      expect(txt, isNot(contains('```')));
      expect(txt, contains('第1章'));
      expect(txt, contains('第100章'));
      debugPrint('[D-09] txt length=${txt.length}');
    });
  });

  group('JSON format validation', () {
    test('should produce parseable JSON with complete metadata', () {
      final json = exportService.buildJson(bundle);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final chapters = decoded['chapters'] as List<dynamic>;

      expect(chapters, hasLength(100));
      expect(decoded['schemaVersion'], '1.0');
      expect(decoded['exportedAt'], isNotNull);
      expect(DateTime.parse(decoded['exportedAt'] as String).isAfter(DateTime(2026, 6, 7)), isTrue);

      for (final chapter in chapters) {
        final chapterMap = chapter as Map<String, dynamic>;
        expect(chapterMap['title'], isA<String>());
        expect(chapterMap['title'] as String, isNotEmpty);
        expect(chapterMap['content'], isA<String>());
        expect(chapterMap['content'] as String, isNotEmpty);
        expect(chapterMap['sortOrder'], isA<int>());
      }
      expect((chapters.first as Map<String, dynamic>)['sortOrder'], 1);
      expect((chapters.last as Map<String, dynamic>)['sortOrder'], 100);
      debugPrint('[D-09] json chapters=${chapters.length}, length=${json.length}');
    });
  });

  group('Cross-format export validation', () {
    test('should preserve chapter content across Markdown, TXT, and JSON', () {
      final markdown = exportService.buildMarkdown(bundle);
      final txt = exportService.buildTxt(bundle);
      final decoded = jsonDecode(exportService.buildJson(bundle)) as Map<String, dynamic>;
      final jsonChapters = decoded['chapters'] as List<dynamic>;

      for (var i = 0; i < chapterExports.length; i++) {
        final chapter = chapterExports[i];
        final contentSample = chapter.content.substring(0, min(80, chapter.content.length));
        expect(markdown, contains(contentSample), reason: 'Markdown missing content for ${chapter.title}');
        expect(txt, contains(contentSample), reason: 'TXT missing content for ${chapter.title}');
        expect((jsonChapters[i] as Map<String, dynamic>)['content'], chapter.content);
      }
    });

    test('should keep file sizes in expected range per D-09', () {
      final markdown = exportService.buildMarkdown(bundle);
      final txt = exportService.buildTxt(bundle);
      final json = exportService.buildJson(bundle);
      final provider = container.read(activeProviderProvider);
      final manuscript = Manuscript(
        id: 'export-validation-journey',
        title: '剑道苍穹',
        genre: '修仙',
        createdAt: _fixedDate,
        updatedAt: _fixedDate,
      );
      final chapter = Chapter(
        id: 'export-validation-chapter-1',
        manuscriptId: manuscript.id,
        title: chapterExports.first.title,
        sortOrder: chapterExports.first.sortOrder,
        documentContent: chapterExports.first.content,
        createdAt: _fixedDate,
        updatedAt: _fixedDate,
      );

      expect(markdown.length, inInclusiveRange(30000, 50000));
      expect(txt.length, inInclusiveRange(30000, 50000));
      expect(json.length, greaterThan(30000));
      expect(json, isNotEmpty);
      expect(provider, isNotNull);
      expect(provider!.model, 'fake-model');
      expect(manuscript.title, '剑道苍穹');
      expect(chapter.documentContent, chapterExports.first.content);
      debugPrint('[D-09] sizes md=${markdown.length}, txt=${txt.length}, json=${json.length}');
    });
  });
}

final _fixedDate = DateTime(2026, 6, 8);

List<ChapterExport> _buildChapterExports() {
  return List.generate(100, (index) {
    final outline = StoryOutline.chapters[index];
    return ChapterExport(
      title: '第${index + 1}章 ${outline.substring(0, min(10, outline.length))}',
      sortOrder: index + 1,
      content: _expandChapterContent(outline, index + 1),
    );
  });
}

ExportBundle _buildExportBundle(List<ChapterExport> chapterExports) {
  return ExportBundle(
    schemaVersion: '1.0',
    exportedAt: _fixedDate,
    manuscriptText: chapterExports.map((chapter) => chapter.content).join('\n\n'),
    chapters: chapterExports,
    foreshadowingEntries: const [],
    characterCards: const [],
    worldSettings: const [],
    skillDocuments: const [],
  );
}

String _expandChapterContent(String outline, int chapterNumber) {
  return '$outline\n'
      '林风在这一章继续沿着自己的选择向前，记下战斗后的灵气波动、人物承诺与下一步目标。'
      '青云宗众人各有回应，伏笔仍然落在禁地、玉简、苏雪晴血脉与王磊余党的暗线之中。'
      '他整理清虚真人留下的提醒，将本章发生的取舍写成修炼札记，也为后续冲突埋下新的线索。'
      '白灵在旁侧感应灵潮变化，苏雪晴则把剑意收束成一句提醒：凡心不失，道途才不会偏离。'
      '他没有急着追求下一场胜利，而是把眼前的代价、同门的信任和未解的疑问逐一记清。'
      '第$chapterNumber章的内容保持非空且可跨格式核对。';
}

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/manuscript/domain/chapter_export.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';
import 'package:museflow/features/story_structure/domain/export_bundle.dart';

void main() {
  group('Chapter-aware ExportBundle', () {
    test('should serialize and deserialize with chapters field', () {
      final bundle = ExportBundle(
        schemaVersion: '1.0',
        manuscriptText: 'flat text',
        chapters: [
          const ChapterExport(title: '第一章', sortOrder: 0, content: '内容一'),
          const ChapterExport(title: '第二章', sortOrder: 1, content: '内容二'),
        ],
      );

      final json = bundle.toJson();
      expect(json['chapters'], isA<List>());
      expect((json['chapters'] as List).length, 2);
      expect(json['chapters'][0]['title'], '第一章');
      expect(json['chapters'][1]['title'], '第二章');

      final restored = ExportBundle.fromJson(json);
      expect(restored.chapters.length, 2);
      expect(restored.chapters[0].title, '第一章');
      expect(restored.chapters[1].content, '内容二');
    });

    test('should default chapters to empty list', () {
      const bundle = ExportBundle(
        schemaVersion: '1.0',
        manuscriptText: 'text',
      );
      expect(bundle.chapters, isEmpty);
    });

    test('should be backward compatible with JSON without chapters key', () {
      final json = {
        'schemaVersion': '1.0',
        'manuscriptText': 'legacy text',
      };
      final restored = ExportBundle.fromJson(json);
      expect(restored.chapters, isEmpty);
      expect(restored.manuscriptText, 'legacy text');
    });

    test('should include chapters in equality comparison', () {
      final a = ExportBundle(
        schemaVersion: '1.0',
        manuscriptText: 'text',
        chapters: [
          const ChapterExport(title: '第一章', sortOrder: 0, content: '内容'),
        ],
      );
      final b = ExportBundle(
        schemaVersion: '1.0',
        manuscriptText: 'text',
        chapters: [
          const ChapterExport(title: '第一章', sortOrder: 0, content: '内容'),
        ],
      );
      final c = ExportBundle(
        schemaVersion: '1.0',
        manuscriptText: 'text',
        chapters: [
          const ChapterExport(title: '第二章', sortOrder: 1, content: '其他'),
        ],
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('Chapter-aware ExportService', () {
    final service = ExportService(
      fileWriter: (_, _) async {},
    );

    test('should produce chapter headers in Markdown when chapters non-empty', () {
      final bundle = ExportBundle(
        schemaVersion: '1.0',
        manuscriptText: 'flat text',
        chapters: [
          const ChapterExport(title: '世界观铺垫', sortOrder: 1, content: '世界设定内容'),
          const ChapterExport(title: '角色登场', sortOrder: 0, content: '角色介绍内容'),
        ],
      );

      final md = service.buildMarkdown(bundle);

      // Should be sorted by sortOrder
      expect(md, contains('## 角色登场'));
      expect(md, contains('角色介绍内容'));
      expect(md, contains('## 世界观铺垫'));
      expect(md, contains('世界设定内容'));

      // Order: sortOrder 0 comes first
      expect(md.indexOf('角色登场'), lessThan(md.indexOf('世界观铺垫')));
    });

    test('should fall back to manuscriptText when chapters empty for Markdown', () {
      final bundle = ExportBundle(
        schemaVersion: '1.0',
        manuscriptText: '这是一段纯文本稿件。',
      );

      final md = service.buildMarkdown(bundle);
      expect(md, '这是一段纯文本稿件。');
    });

    test('should produce chapter-aware TXT with plain separators', () {
      final bundle = ExportBundle(
        schemaVersion: '1.0',
        manuscriptText: 'flat',
        chapters: [
          const ChapterExport(title: '第一篇', sortOrder: 0, content: '内容A'),
          const ChapterExport(title: '第二篇', sortOrder: 1, content: '内容B'),
        ],
      );

      final txt = service.buildTxt(bundle);

      expect(txt, contains('第一篇'));
      expect(txt, contains('内容A'));
      expect(txt, contains('第二篇'));
      expect(txt, contains('内容B'));
      // No Markdown headers in TXT
      expect(txt, isNot(contains('## ')));
    });

    test('should fall back to manuscriptText when chapters empty for TXT', () {
      final bundle = ExportBundle(
        schemaVersion: '1.0',
        manuscriptText: '纯文本内容。',
      );

      final txt = service.buildTxt(bundle);
      expect(txt, '纯文本内容。');
    });

    test('should include chapters in JSON export', () {
      final bundle = ExportBundle(
        schemaVersion: '1.0',
        manuscriptText: 'text',
        chapters: [
          const ChapterExport(title: '第一章', sortOrder: 0, content: '内容'),
        ],
      );

      final json = service.buildJson(bundle);
      expect(json, contains('"chapters"'));
      expect(json, contains('"第一章"'));
    });
  });
}

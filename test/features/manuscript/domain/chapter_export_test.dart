import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/manuscript/domain/chapter_export.dart';

void main() {
  group('ChapterExport', () {
    test('toJson produces map with title, sortOrder, content keys', () {
      const export = ChapterExport(
        title: 'Chapter One',
        sortOrder: 0,
        content: 'Chapter content here.',
      );

      final json = export.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['title'], 'Chapter One');
      expect(json['sortOrder'], 0);
      expect(json['content'], 'Chapter content here.');
      expect(json.length, 3);
    });

    test('fromJson creates ChapterExport from JSON map', () {
      final json = <String, dynamic>{
        'title': 'Test Chapter',
        'sortOrder': 5,
        'content': 'Some markdown content.',
      };

      final export = ChapterExport.fromJson(json);

      expect(export.title, 'Test Chapter');
      expect(export.sortOrder, 5);
      expect(export.content, 'Some markdown content.');
    });

    test('equality compares title, sortOrder, content', () {
      const e1 = ChapterExport(title: 'Chapter', sortOrder: 1, content: 'Text');
      const e2 = ChapterExport(title: 'Chapter', sortOrder: 1, content: 'Text');

      expect(e1, equals(e2));
      expect(e1.hashCode, equals(e2.hashCode));
    });

    test('inequality detects differences', () {
      const e1 = ChapterExport(
        title: 'Chapter A',
        sortOrder: 1,
        content: 'Text A',
      );
      const e2 = ChapterExport(
        title: 'Chapter B',
        sortOrder: 1,
        content: 'Text A',
      );
      const e3 = ChapterExport(
        title: 'Chapter A',
        sortOrder: 2,
        content: 'Text A',
      );
      const e4 = ChapterExport(
        title: 'Chapter A',
        sortOrder: 1,
        content: 'Text B',
      );

      expect(e1, isNot(equals(e2)));
      expect(e1, isNot(equals(e3)));
      expect(e1, isNot(equals(e4)));
    });

    test('fromJson(toJson()) roundtrip preserves all fields', () {
      const export = ChapterExport(
        title: 'Round Trip',
        sortOrder: 3,
        content: 'Content with special chars: 中文，标点！',
      );

      final roundtrip = ChapterExport.fromJson(export.toJson());

      expect(roundtrip.title, export.title);
      expect(roundtrip.sortOrder, export.sortOrder);
      expect(roundtrip.content, export.content);
    });
  });
}

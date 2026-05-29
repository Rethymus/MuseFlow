import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/models/note.dart';

/// Note模型测试
/// 验证Note对象的完整生命周期
void main() {
  group('Note模型测试', () {
    late Note note;

    setUp(() {
      // 创建测试用的Note对象
      note = Note(
        id: 'test-id-1',
        title: '测试标题',
        content: '测试内容',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
        tags: ['tag1', 'tag2'],
      );
    });

    test('Note基本属性验证', () {
      expect(note.id, 'test-id-1');
      expect(note.title, '测试标题');
      expect(note.content, '测试内容');
      expect(note.tags, ['tag1', 'tag2']);
    });

    test('Note时间戳验证', () {
      expect(note.createdAt, DateTime(2024, 1, 1));
      expect(note.updatedAt, DateTime(2024, 1, 2));
      expect(
        note.updatedAt.isAfter(note.createdAt) ||
            note.updatedAt.isAtSameMomentAs(note.createdAt),
        true,
      );
    });

    test('Note copyWith方法测试', () {
      final updatedNote = note.copyWith(
        title: '更新后的标题',
        content: '更新后的内容',
      );

      expect(updatedNote.id, note.id);
      expect(updatedNote.title, '更新后的标题');
      expect(updatedNote.content, '更新后的内容');
      expect(updatedNote.createdAt, note.createdAt);
      expect(updatedNote.tags, note.tags);
    });

    test('Note标签操作测试', () {
      final noteWithTags = note.copyWith(tags: ['tag1', 'tag2', 'tag3']);
      expect(noteWithTags.tags.length, 3);
      expect(noteWithTags.tags, contains('tag3'));
    });

    test('Note空值处理测试', () {
      final emptyNote = Note(
        id: 'empty-id',
        title: '',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(emptyNote.title, isEmpty);
      expect(emptyNote.content, isEmpty);
      expect(emptyNote.tags, isEmpty);
    });

    test('Note长内容处理测试', () {
      const longContent = 'A' * 10000;
      final longNote = note.copyWith(content: longContent);

      expect(longNote.content.length, 10000);
      expect(longNote.content, longContent);
    });

    test('Note标签列表测试', () {
      final noteWithTags = note.copyWith(
        tags: ['tag1', 'tag1', 'tag2', 'tag2'],
      );

      expect(noteWithTags.tags, isList);
      expect(noteWithTags.tags.length, 4);
    });
  });

  group('Note创建测试', () {
    test('创建基本Note', () {
      final note = Note(
        id: 'basic-note',
        title: '基本笔记',
        content: '这是内容',
        createdAt: DateTime(2024, 5, 28),
        updatedAt: DateTime(2024, 5, 28),
      );

      expect(note.id, 'basic-note');
      expect(note.title, '基本笔记');
      expect(note.content, '这是内容');
    });

    test('创建带标签的Note', () {
      final note = Note(
        id: 'tagged-note',
        title: '带标签笔记',
        content: '内容',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['fiction', 'novel', 'draft'],
      );

      expect(note.tags.length, 3);
      expect(note.tags, contains('fiction'));
    });

    test('默认空标签列表', () {
      final note = Note(
        id: 'no-tags',
        title: '无标签',
        content: '内容',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(note.tags, isEmpty);
      expect(note.tags, equals([]));
    });
  });

  group('Note边界条件测试', () {
    test('特殊字符处理', () {
      final specialNote = Note(
        id: 'special-1',
        title: '特殊字符: <>&"\'',
        content: '包含emoji: 🎉🚀⭐\n换行\n制表\t',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(specialNote.title, contains('特殊字符'));
      expect(specialNote.content, contains('🎉'));
      expect(specialNote.content, contains('\n'));
    });

    test('超长内容处理', () {
      const longContent = 'A' * 1000000; // 1MB内容
      final longNote = Note(
        id: 'long-1',
        title: '超长内容',
        content: longContent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(longNote.content.length, 1000000);
    });

    test('Unicode内容处理', () {
      final unicodeNote = Note(
        id: 'unicode-1',
        title: 'Unicode测试',
        content: '中文English日本語한국어العربيةemoji🎉',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(unicodeNote.content, contains('中文'));
      expect(unicodeNote.content, contains('English'));
      expect(unicodeNote.content, contains('🎉'));
    });
  });
}

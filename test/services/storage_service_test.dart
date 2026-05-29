import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/models/note.dart';
import 'package:museflow/services/storage_service.dart';

/// StorageService测试
/// 验证数据存储服务的核心功能
void main() {
  group('StorageService基础测试', () {
    test('StorageService初始化验证', () {
      // 验证服务可以创建实例
      expect(() => StorageService(), returnsNormally);
    });

    test('StorageService方法存在验证', () {
      final service = StorageService();

      // 验证所有关键方法存在
      expect(() => service.getAllNotes(), returnsNormally);
      expect(() => service.saveNote(Note(
        id: 'test',
        title: 'Test',
        content: 'Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )), returnsNormally);
      expect(() => service.deleteNote('test'), returnsNormally);
      expect(() => service.searchNotes('query'), returnsNormally);
    });
  });

  group('Note对象测试', () {
    test('创建Note对象', () {
      final note = Note(
        id: 'test-1',
        title: '测试笔记',
        content: '测试内容',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
        tags: ['tag1', 'tag2'],
        isEncrypted: false,
      );

      expect(note.id, 'test-1');
      expect(note.title, '测试笔记');
      expect(note.content, '测试内容');
      expect(note.tags, ['tag1', 'tag2']);
      expect(note.isEncrypted, false);
    });

    test('Note时间戳验证', () {
      final note = Note(
        id: 'test-2',
        title: '时间测试',
        content: '内容',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(note.createdAt, DateTime(2024, 1, 1));
      expect(note.updatedAt, DateTime(2024, 1, 2));
    });

    test('Note copyWith功能', () {
      final original = Note(
        id: 'test-3',
        title: '原标题',
        content: '原内容',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        title: '新标题',
        content: '新内容',
      );

      expect(updated.id, original.id);
      expect(updated.title, '新标题');
      expect(updated.content, '新内容');
    });
  });

  group('边界条件测试', () {
    test('空Note处理', () {
      final emptyNote = Note(
        id: '',
        title: '',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(emptyNote.title, isEmpty);
      expect(emptyNote.content, isEmpty);
    });

    test('长内容处理', () {
      final longContent = 'A' * 100000;
      final longNote = Note(
        id: 'long-1',
        title: '长内容测试',
        content: longContent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(longNote.content.length, 100000);
    });

    test('特殊字符处理', () {
      final specialNote = Note(
        id: 'special-1',
        title: '特殊字符: <>&"\'',
        content: '包含emoji: 🎉🚀⭐',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(specialNote.title, contains('特殊字符'));
      expect(specialNote.content, contains('🎉'));
    });
  });

  group('标签功能测试', () {
    test('Note标签操作', () {
      final note = Note(
        id: 'tag-test',
        title: '标签测试',
        content: '内容',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['writing', 'fiction', 'character'],
      );

      expect(note.tags.length, 3);
      expect(note.tags, contains('writing'));
      expect(note.tags, contains('fiction'));
    });

    test('空标签列表', () {
      final note = Note(
        id: 'no-tags',
        title: '无标签',
        content: '内容',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(note.tags, isEmpty);
    });
  });
}

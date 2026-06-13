import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/editor/application/editor_chapter_memory_context_builder.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  group('EditorChapterMemoryContextBuilder', () {
    late Box<dynamic> box;
    late ChapterRepository repository;

    setUp(() async {
      await setUpHiveTest();
      box = await Hive.openBox<dynamic>(
        'editor_chapter_memory_context_builder_test',
      );
      repository = ChapterRepository(box);
    });

    tearDown(() async {
      await tearDownHiveTest();
    });

    test(
      'builds bounded previous and next summaries for current chapter',
      () async {
        final builder = EditorChapterMemoryContextBuilder(
          chapterRepository: repository,
          summaryCharacterLimit: 18,
        );
        await repository.add(
          _chapter(id: 'c1', sortOrder: 1, text: '上一章林风在雨夜守住山门。'),
        );
        await repository.add(_chapter(id: 'c2', sortOrder: 2, text: '当前章节。'));
        await repository.add(
          _chapter(id: 'c3', sortOrder: 3, text: '下一章苏雪晴带来宗门试炼消息。'),
        );

        final context = builder.build(manuscriptId: 'm1', chapterId: 'c2');

        expect(context.previousChapterSummary, '上一章林风在雨夜守住山门。');
        expect(context.nextChapterSummary, '下一章苏雪晴带来宗门试炼消息。');
        expect(context.previousChapterMemoryWarning, isNull);
        expect(context.nextChapterMemoryWarning, isNull);
      },
    );

    test('returns empty context when chapter cannot be found', () async {
      final builder = EditorChapterMemoryContextBuilder(
        chapterRepository: repository,
      );
      await repository.add(_chapter(id: 'c1', sortOrder: 1, text: '正文'));

      final context = builder.build(manuscriptId: 'm1', chapterId: 'missing');

      expect(context.isEmpty, isTrue);
    });

    test(
      'generates warning when bounded summary misses later chapter facts',
      () async {
        final builder = EditorChapterMemoryContextBuilder(
          chapterRepository: repository,
          summaryCharacterLimit: 26,
        );
        await repository.add(
          _chapter(
            id: 'c1',
            sortOrder: 1,
            text: '林风雨夜守山。苏雪晴递来玉简，赵天磊暗中放出白灵，清虚真人宣布宗门试炼提前。',
          ),
        );
        await repository.add(_chapter(id: 'c2', sortOrder: 2, text: '当前章节。'));

        final context = builder.build(manuscriptId: 'm1', chapterId: 'c2');

        expect(context.previousChapterSummary, isNotNull);
        expect(context.previousChapterMemoryWarning, contains('上一章'));
        expect(context.previousChapterMemoryWarning, contains('截断上下文'));
        expect(context.previousChapterMemoryWarning, contains('缺少'));
        expect(context.previousChapterMemoryWarning, contains('请复查相邻章节'));
      },
    );

    group('chapterContextChain (LFIN-01)', () {
      test('should return null when current chapter is first', () async {
        final builder = EditorChapterMemoryContextBuilder(
          chapterRepository: repository,
        );
        await repository.add(_chapter(id: 'c1', sortOrder: 1, text: '第一章正文。'));

        final context = builder.build(manuscriptId: 'm1', chapterId: 'c1');

        expect(context.chapterContextChain, isNull);
      });

      test(
        'should build chain with one previous chapter at 220 chars',
        () async {
          final builder = EditorChapterMemoryContextBuilder(
            chapterRepository: repository,
          );
          await repository.add(
            _chapter(id: 'c1', sortOrder: 1, text: '上一章的内容。'),
          );
          await repository.add(_chapter(id: 'c2', sortOrder: 2, text: '当前章节。'));

          final context = builder.build(manuscriptId: 'm1', chapterId: 'c2');

          expect(context.chapterContextChain, isNotNull);
          expect(context.chapterContextChain, contains('紧邻前章'));
          expect(context.chapterContextChain, contains('上一章的内容'));
        },
      );

      test(
        'should build chain with decreasing detail for 3 previous chapters',
        () async {
          final builder = EditorChapterMemoryContextBuilder(
            chapterRepository: repository,
          );
          await repository.add(
            _chapter(
              id: 'c1',
              sortOrder: 1,
              text: '第一章的内容比较多，这里是前前章也就是N-3章的摘要内容。' * 3,
            ),
          );
          await repository.add(
            _chapter(
              id: 'c2',
              sortOrder: 2,
              text: '第二章的内容也是比较多的，这里N-2章的摘要也需要缩减。' * 3,
            ),
          );
          await repository.add(
            _chapter(id: 'c3', sortOrder: 3, text: '第三章紧邻前章的内容，可以保留更多细节。' * 3),
          );
          await repository.add(_chapter(id: 'c4', sortOrder: 4, text: '当前章节。'));

          final context = builder.build(manuscriptId: 'm1', chapterId: 'c4');

          expect(context.chapterContextChain, isNotNull);
          // N-3 (c1) should be truncated to ~80 chars
          expect(context.chapterContextChain, contains('前3章'));
          // N-2 (c2) should be truncated to ~150 chars
          expect(context.chapterContextChain, contains('前2章'));
          // N-1 (c3) should be truncated to ~220 chars
          expect(context.chapterContextChain, contains('紧邻前章'));
          // Chapter order: chain lists from closest to furthest
          final lines = context.chapterContextChain!.split('\n');
          expect(lines[0], contains('紧邻前章'));
          expect(lines.any((l) => l.contains('前2章')), isTrue);
          expect(lines.any((l) => l.contains('前3章')), isTrue);
        },
      );

      test('should truncate chapter text at decreasing limits', () async {
        final builder = EditorChapterMemoryContextBuilder(
          chapterRepository: repository,
        );
        // N-1: exactly 230 chars — should be truncated to 220 + "..."
        final longText = '这是非常长的章节内容' * 15; // ~195 chars per unit
        await repository.add(_chapter(id: 'c1', sortOrder: 1, text: longText));
        await repository.add(_chapter(id: 'c2', sortOrder: 2, text: '当前。'));

        final context = builder.build(manuscriptId: 'm1', chapterId: 'c2');

        expect(context.chapterContextChain, isNotNull);
        // The summary should be truncated at ~220 chars
        final summaryLine = context.chapterContextChain!.split('\n')[0];
        // Extract just the summary part after "紧邻前章摘要："
        final summaryPart = summaryLine.replaceFirst(RegExp(r'^紧邻前章摘要：'), '');
        expect(summaryPart.length, lessThanOrEqualTo(223)); // 220 + "..."
      });

      test('should skip empty chapters in the chain', () async {
        final builder = EditorChapterMemoryContextBuilder(
          chapterRepository: repository,
        );
        await repository.add(_chapter(id: 'c1', sortOrder: 1, text: ''));
        await repository.add(_chapter(id: 'c2', sortOrder: 2, text: '有内容的章节。'));
        await repository.add(_chapter(id: 'c3', sortOrder: 3, text: '当前。'));

        final context = builder.build(manuscriptId: 'm1', chapterId: 'c3');

        expect(context.chapterContextChain, isNotNull);
        // Empty c1 should be skipped, only c2 appears
        expect(context.chapterContextChain, contains('有内容的章节'));
        expect(context.chapterContextChain, isNot(contains('前2章')));
      });
    });
  });
}

Chapter _chapter({
  required String id,
  required int sortOrder,
  required String text,
}) {
  return Chapter(
    id: id,
    manuscriptId: 'm1',
    title: '第$sortOrder章',
    sortOrder: sortOrder,
    documentContent: text,
    createdAt: DateTime(2026, 1, sortOrder),
    updatedAt: DateTime(2026, 1, sortOrder),
  );
}

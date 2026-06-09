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

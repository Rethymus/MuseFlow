import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late Box<dynamic> box;
  late ChapterRepository repository;

  setUp(() async {
    await setUpHiveTest();
    box = await Hive.openBox<dynamic>('test_chapters');
    repository = ChapterRepository(box);
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  Chapter createChapter({
    String id = '',
    String manuscriptId = 'ms-1',
    String title = 'Test Chapter',
    int sortOrder = 0,
    String documentContent = '',
  }) {
    final now = DateTime.now();
    return Chapter(
      id: id,
      manuscriptId: manuscriptId,
      title: title,
      sortOrder: sortOrder,
      documentContent: documentContent,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('add creates chapter with uuid if id empty', () async {
    final chapter = createChapter(id: '');
    final result = await repository.add(chapter);

    expect(result.id, isNotEmpty);
    expect(result.title, equals('Test Chapter'));
    expect(result.createdAt, isNotNull);

    final stored = box.get(result.id);
    expect(stored, isNotNull);
  });

  test(
    'getByManuscriptId returns chapters filtered and sorted by sortOrder',
    () async {
      final msId = 'ms-filter';
      await repository.add(
        createChapter(
          id: 'ch-1',
          manuscriptId: msId,
          sortOrder: 2,
          title: 'Second',
        ),
      );
      await repository.add(
        createChapter(
          id: 'ch-2',
          manuscriptId: msId,
          sortOrder: 0,
          title: 'First',
        ),
      );
      await repository.add(
        createChapter(
          id: 'ch-3',
          manuscriptId: 'other-ms',
          sortOrder: 1,
          title: 'Other',
        ),
      );
      await repository.add(
        createChapter(
          id: 'ch-4',
          manuscriptId: msId,
          sortOrder: 1,
          title: 'Middle',
        ),
      );

      final results = repository.getByManuscriptId(msId);

      expect(results.length, equals(3));
      expect(results[0].title, equals('First'));
      expect(results[1].title, equals('Middle'));
      expect(results[2].title, equals('Second'));
    },
  );

  test(
    'updateDocumentContent updates only documentContent and updatedAt',
    () async {
      final now = DateTime.now();
      final chapter = Chapter(
        id: 'update-content',
        manuscriptId: 'ms-1',
        title: 'Original Title',
        sortOrder: 0,
        documentContent: 'old content',
        createdAt: now,
        updatedAt: now.subtract(const Duration(hours: 1)),
      );
      await box.put('update-content', chapter.toJson());

      await repository.updateDocumentContent(
        'update-content',
        'new markdown content',
      );

      final stored = repository.getById('update-content');
      expect(stored!.documentContent, equals('new markdown content'));
      expect(stored.title, equals('Original Title')); // unchanged
      expect(stored.sortOrder, equals(0)); // unchanged
      expect(
        stored.updatedAt.isAfter(now.subtract(const Duration(hours: 1))),
        isTrue,
      );
    },
  );

  test(
    'deleteByManuscriptId deletes all chapters with matching manuscriptId',
    () async {
      await repository.add(createChapter(id: 'ch-a', manuscriptId: 'ms-del'));
      await repository.add(createChapter(id: 'ch-b', manuscriptId: 'ms-del'));
      await repository.add(createChapter(id: 'ch-c', manuscriptId: 'ms-keep'));

      await repository.deleteByManuscriptId('ms-del');

      final keepResults = repository.getByManuscriptId('ms-keep');
      expect(keepResults.length, equals(1));

      final delResults = repository.getByManuscriptId('ms-del');
      expect(delResults, isEmpty);
    },
  );

  test('getById returns chapter when found', () async {
    final chapter = createChapter(id: 'find-me');
    await box.put('find-me', chapter.toJson());

    final result = repository.getById('find-me');
    expect(result, isNotNull);
    expect(result!.id, equals('find-me'));
  });

  test('update sets updatedAt and persists', () async {
    final chapter = createChapter(id: 'update-me');
    await box.put('update-me', chapter.toJson());

    final updated = chapter.copyWith(title: 'New Title');
    await repository.update(updated);

    final stored = repository.getById('update-me');
    expect(stored!.title, equals('New Title'));
  });

  test('delete removes chapter from box', () async {
    final chapter = createChapter(id: 'delete-me');
    await box.put('delete-me', chapter.toJson());

    await repository.delete('delete-me');

    expect(repository.getById('delete-me'), isNull);
  });
}

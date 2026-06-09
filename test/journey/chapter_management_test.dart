import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';

import 'helpers/journey_container.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = await createJourneyContainer(
      apiKey: 'test-key',
      baseUrl: 'https://example.com',
      model: 'test',
    );
  });

  tearDown(() async {
    await cleanupJourneyContainer(container);
  });

  /// Helper: Creates 30 chapters with sortOrder 1-30 and returns them.
  Future<List<Chapter>> create30Chapters(
    ChapterRepository repo,
    String manuscriptId,
  ) async {
    final chapters = <Chapter>[];
    for (var i = 1; i <= 30; i++) {
      final chapter = await repo.add(
        Chapter(
          id: '',
          manuscriptId: manuscriptId,
          title: '第$i章',
          sortOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      chapters.add(chapter);
    }
    return chapters;
  }

  group('Create 30 Chapters', () {
    test('should create 30 chapters with correct sortOrders', () async {
      final manuscriptRepo = await container.read(
        manuscriptRepositoryProvider.future,
      );
      final chapterRepo = await container.read(
        chapterRepositoryProvider.future,
      );

      final manuscript = await manuscriptRepo.add(
        Manuscript(
          id: 'ms-create30-test',
          title: '剑道苍穹',
          genre: '修仙',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      );

      await create30Chapters(chapterRepo, manuscript.id);

      final fetched = chapterRepo.getByManuscriptId(manuscript.id);
      expect(fetched, hasLength(30));

      // Verify sortOrders are 1 through 30
      final sortOrders = fetched.map((c) => c.sortOrder).toList();
      expect(sortOrders, List.generate(30, (i) => i + 1));
    });
  });

  group('Content Update', () {
    test('should persist document content update', () async {
      final manuscriptRepo = await container.read(
        manuscriptRepositoryProvider.future,
      );
      final chapterRepo = await container.read(
        chapterRepositoryProvider.future,
      );

      final manuscript = await manuscriptRepo.add(
        Manuscript(
          id: 'ms-content-test',
          title: '剑道苍穹',
          genre: '修仙',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      );

      final chapters = await create30Chapters(chapterRepo, manuscript.id);
      final firstChapter = chapters.first;

      const newContent = '第一章正文内容...林风踏入青云峰，感受到灵气的波动，心中既紧张又期待';
      await chapterRepo.updateDocumentContent(firstChapter.id, newContent);

      final updated = chapterRepo.getById(firstChapter.id);
      expect(updated, isNotNull);
      expect(updated!.documentContent, equals(newContent));
    });
  });

  group('Reorder', () {
    test('should correctly swap chapter sortOrders', () async {
      final manuscriptRepo = await container.read(
        manuscriptRepositoryProvider.future,
      );
      final chapterRepo = await container.read(
        chapterRepositoryProvider.future,
      );

      final manuscript = await manuscriptRepo.add(
        Manuscript(
          id: 'ms-reorder-test',
          title: '剑道苍穹',
          genre: '修仙',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      );

      await create30Chapters(chapterRepo, manuscript.id);
      final notifier = container.read(chapterNotifierProvider.notifier);
      await notifier.loadChapters(manuscript.id);

      await notifier.reorder(manuscript.id, 9, 4);

      final fetched = chapterRepo.getByManuscriptId(manuscript.id);
      expect(fetched, hasLength(30));
      expect(fetched[4].title, equals('第10章'));
      expect(fetched.map((c) => c.sortOrder), List.generate(30, (i) => i));
    });
  });

  group('Split', () {
    test(
      'should replace 1 chapter with 2, preserving content halves',
      () async {
        final manuscriptRepo = await container.read(
          manuscriptRepositoryProvider.future,
        );
        final chapterRepo = await container.read(
          chapterRepositoryProvider.future,
        );

        final manuscript = await manuscriptRepo.add(
          Manuscript(
            id: 'ms-split-test',
            title: '剑道苍穹',
            genre: '修仙',
            createdAt: fixedDate,
            updatedAt: fixedDate,
          ),
        );

        final chapters = await create30Chapters(chapterRepo, manuscript.id);
        final notifier = container.read(chapterNotifierProvider.notifier);
        await notifier.loadChapters(manuscript.id);

        final ch15 = chapters.firstWhere((c) => c.sortOrder == 15);
        await notifier.splitChapter(ch15.id, '第一段内容', '第二段内容');

        final fetched = chapterRepo.getByManuscriptId(manuscript.id);
        expect(
          fetched.length,
          equals(31),
          reason: '30 original chapters plus one inserted continuation',
        );
        expect(chapterRepo.getById(ch15.id)?.documentContent, equals('第一段内容'));
        expect(fetched[15].documentContent, equals('第二段内容'));
        expect(
          fetched.map((c) => c.sortOrder),
          List.generate(31, (i) => i + 1),
        );
      },
    );
  });

  group('Merge', () {
    test(
      'should combine 2 chapters into 1 with concatenated content',
      () async {
        final manuscriptRepo = await container.read(
          manuscriptRepositoryProvider.future,
        );
        final chapterRepo = await container.read(
          chapterRepositoryProvider.future,
        );

        final manuscript = await manuscriptRepo.add(
          Manuscript(
            id: 'ms-merge-test',
            title: '剑道苍穹',
            genre: '修仙',
            createdAt: fixedDate,
            updatedAt: fixedDate,
          ),
        );

        final chapters = await create30Chapters(chapterRepo, manuscript.id);
        final notifier = container.read(chapterNotifierProvider.notifier);
        await notifier.loadChapters(manuscript.id);

        final ch1 = chapters.firstWhere((c) => c.sortOrder == 1);
        final ch2 = chapters.firstWhere((c) => c.sortOrder == 2);
        await chapterRepo.updateDocumentContent(ch1.id, '第一章正文内容');
        await chapterRepo.updateDocumentContent(ch2.id, '第二章正文内容');

        await notifier.mergeChapters(ch1.id, ch2.id);

        final fetched = chapterRepo.getByManuscriptId(manuscript.id);
        expect(
          fetched.length,
          equals(29),
          reason: '30 chapters minus one merged-away chapter',
        );
        expect(chapterRepo.getById(ch2.id), isNull);

        final merged = chapterRepo.getById(ch1.id);
        expect(merged, isNotNull);
        expect(merged!.documentContent, equals('第一章正文内容\n\n第二章正文内容'));
        expect(fetched.map((c) => c.sortOrder), List.generate(29, (i) => i));
      },
    );
  });

  group('Copy', () {
    test(
      'should create new chapter with identical content and （副本） suffix',
      () async {
        final manuscriptRepo = await container.read(
          manuscriptRepositoryProvider.future,
        );
        final chapterRepo = await container.read(
          chapterRepositoryProvider.future,
        );

        final manuscript = await manuscriptRepo.add(
          Manuscript(
            id: 'ms-copy-test',
            title: '剑道苍穹',
            genre: '修仙',
            createdAt: fixedDate,
            updatedAt: fixedDate,
          ),
        );

        final chapters = await create30Chapters(chapterRepo, manuscript.id);
        final notifier = container.read(chapterNotifierProvider.notifier);
        await notifier.loadChapters(manuscript.id);

        final ch3 = chapters.firstWhere((c) => c.sortOrder == 3);
        await chapterRepo.updateDocumentContent(ch3.id, '第三章正文内容');
        final updatedCh3 = chapterRepo.getById(ch3.id)!;

        await notifier.duplicateChapter(updatedCh3.id);

        final fetched = chapterRepo.getByManuscriptId(manuscript.id);
        expect(fetched.length, equals(31), reason: '30 original + 1 copy = 31');

        final copied = fetched.last;
        expect(copied.documentContent, equals('第三章正文内容'));
        expect(copied.title, anyOf(contains('(副本)'), contains('（副本）')));
        expect(copied.id, isNot(equals(ch3.id)));
      },
    );
  });

  group('Delete', () {
    test('should remove chapter and return null on getById', () async {
      final manuscriptRepo = await container.read(
        manuscriptRepositoryProvider.future,
      );
      final chapterRepo = await container.read(
        chapterRepositoryProvider.future,
      );

      final manuscript = await manuscriptRepo.add(
        Manuscript(
          id: 'ms-delete-test',
          title: '剑道苍穹',
          genre: '修仙',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      );

      final chapters = await create30Chapters(chapterRepo, manuscript.id);
      final notifier = container.read(chapterNotifierProvider.notifier);
      await notifier.loadChapters(manuscript.id);

      final ch25 = chapters.firstWhere((c) => c.sortOrder == 25);
      await notifier.delete(ch25.id);

      final fetched = chapterRepo.getByManuscriptId(manuscript.id);
      expect(fetched.length, equals(29), reason: '30 - 1 (deleted) = 29');
      expect(chapterRepo.getById(ch25.id), isNull);
      expect(fetched.map((c) => c.sortOrder), List.generate(29, (i) => i));
    });
  });
}

// Fixed date for test consistency
final fixedDate = DateTime(2026, 6, 7);

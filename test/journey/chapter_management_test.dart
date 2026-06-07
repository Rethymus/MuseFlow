import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:uuid/uuid.dart';

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

      final fetched =
          chapterRepo.getByManuscriptId(manuscript.id);
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

      final chapters = await create30Chapters(chapterRepo, manuscript.id);

      // Get chapters at sortOrder 5, 10, 15
      final ch5 = chapters.firstWhere((c) => c.sortOrder == 5);
      final ch10 = chapters.firstWhere((c) => c.sortOrder == 10);
      final ch15 = chapters.firstWhere((c) => c.sortOrder == 15);

      // Swap: 5->15, 10->5, 15->10
      await chapterRepo.update(ch5.copyWith(sortOrder: 15));
      await chapterRepo.update(ch10.copyWith(sortOrder: 5));
      await chapterRepo.update(ch15.copyWith(sortOrder: 10));

      final fetched = chapterRepo.getByManuscriptId(manuscript.id);
      expect(fetched, hasLength(30));

      // Chapter now at sortOrder 5 should be the original chapter 10
      final atSort5 = fetched.firstWhere((c) => c.sortOrder == 5);
      expect(atSort5.id, equals(ch10.id));
      expect(atSort5.title, equals('第10章'));

      // Chapter now at sortOrder 15 should be the original chapter 5
      final atSort15 = fetched.firstWhere((c) => c.sortOrder == 15);
      expect(atSort15.id, equals(ch5.id));

      // Chapter now at sortOrder 10 should be the original chapter 15
      final atSort10 = fetched.firstWhere((c) => c.sortOrder == 10);
      expect(atSort10.id, equals(ch15.id));
    });
  });

  group('Split', () {
    test('should replace 1 chapter with 2, preserving content halves', () async {
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

      // Set content on chapter 15
      final ch15 = chapters.firstWhere((c) => c.sortOrder == 15);
      await chapterRepo.updateDocumentContent(
        ch15.id,
        '第一段内容\n---\n第二段内容',
      );

      // Split: create 2 new chapters at sortOrder 15 and 16
      const uuid = Uuid();
      final chapterA = await chapterRepo.add(
        Chapter(
          id: uuid.v4(),
          manuscriptId: manuscript.id,
          title: '第15章（上）',
          sortOrder: 15,
          documentContent: '第一段内容',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final chapterB = await chapterRepo.add(
        Chapter(
          id: uuid.v4(),
          manuscriptId: manuscript.id,
          title: '第15章（下）',
          sortOrder: 16,
          documentContent: '第二段内容',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Shift subsequent chapters' sortOrders by +1 (16->17, 17->18, ...)
      for (final ch in chapters.where((c) => c.sortOrder > 15)) {
        await chapterRepo.update(
          ch.copyWith(sortOrder: ch.sortOrder + 1),
        );
      }

      // Delete original chapter 15
      await chapterRepo.delete(ch15.id);

      final fetched = chapterRepo.getByManuscriptId(manuscript.id);
      expect(fetched.length, equals(31),
          reason: '30 - 1 (deleted) + 2 (split) = 31');

      // Verify split chapters exist with correct content
      expect(chapterRepo.getById(chapterA.id)?.documentContent,
          equals('第一段内容'));
      expect(chapterRepo.getById(chapterB.id)?.documentContent,
          equals('第二段内容'));
    });
  });

  group('Merge', () {
    test('should combine 2 chapters into 1 with concatenated content', () async {
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

      // Set content on chapters 1 and 2
      final ch1 = chapters.firstWhere((c) => c.sortOrder == 1);
      final ch2 = chapters.firstWhere((c) => c.sortOrder == 2);
      await chapterRepo.updateDocumentContent(ch1.id, '第一章正文内容');
      await chapterRepo.updateDocumentContent(ch2.id, '第二章正文内容');

      // Merge: create a new chapter at sortOrder 1
      const uuid = Uuid();
      final mergedChapter = await chapterRepo.add(
        Chapter(
          id: uuid.v4(),
          manuscriptId: manuscript.id,
          title: '第1-2章（合并）',
          sortOrder: 1,
          documentContent: '第一章正文内容\n第二章正文内容',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Delete both original chapters
      await chapterRepo.delete(ch1.id);
      await chapterRepo.delete(ch2.id);

      // Shift remaining chapters' sortOrders down by 1 (3->2, 4->3, ...)
      final remaining = chapterRepo.getByManuscriptId(manuscript.id);
      for (final ch in remaining.where(
          (c) => c.sortOrder > 1 && c.id != mergedChapter.id)) {
        await chapterRepo.update(
          ch.copyWith(sortOrder: ch.sortOrder - 1),
        );
      }

      final fetched = chapterRepo.getByManuscriptId(manuscript.id);
      expect(fetched.length, equals(29),
          reason: '30 - 2 (deleted) + 1 (merged) = 29');

      // Verify merged chapter has concatenated content
      final merged = chapterRepo.getById(mergedChapter.id);
      expect(merged, isNotNull);
      expect(merged!.documentContent, equals('第一章正文内容\n第二章正文内容'));
    });
  });

  group('Copy', () {
    test('should create new chapter with identical content and （副本） suffix',
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

      // Set content on chapter 3
      final ch3 = chapters.firstWhere((c) => c.sortOrder == 3);
      await chapterRepo.updateDocumentContent(ch3.id, '第三章正文内容');

      // Copy: create a new chapter with identical content but unique ID
      const uuid = Uuid();
      final copiedChapter = await chapterRepo.add(
        Chapter(
          id: uuid.v4(),
          manuscriptId: manuscript.id,
          title: '${ch3.title}（副本）',
          sortOrder: 31,
          documentContent: ch3.documentContent,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final fetched = chapterRepo.getByManuscriptId(manuscript.id);
      expect(fetched.length, equals(31),
          reason: '30 original + 1 copy = 31');

      // Verify copied chapter
      final copied = chapterRepo.getById(copiedChapter.id);
      expect(copied, isNotNull);
      expect(copied!.documentContent, equals(ch3.documentContent));
      expect(copied.title, contains('（副本）'));
      expect(copied.id, isNot(equals(ch3.id)));
    });
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

      // Delete chapter 25
      final ch25 = chapters.firstWhere((c) => c.sortOrder == 25);
      await chapterRepo.delete(ch25.id);

      final fetched = chapterRepo.getByManuscriptId(manuscript.id);
      expect(fetched.length, equals(29),
          reason: '30 - 1 (deleted) = 29');
      expect(chapterRepo.getById(ch25.id), isNull);
    });
  });
}

// Fixed date for test consistency
final fixedDate = DateTime(2026, 6, 7);

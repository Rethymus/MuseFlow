import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/manuscript/domain/chapter_summary.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_summary_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late Box<dynamic> box;
  late ChapterSummaryRepository repository;

  setUp(() async {
    await setUpHiveTest();
    box = await Hive.openBox<dynamic>('test_chapter_summaries');
    repository = ChapterSummaryRepository(box);
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  ChapterSummary createSummary({
    String chapterId = 'ch-1',
    String manuscriptId = 'ms-1',
    int sourceWordCount = 100,
    String summary = '概括内容',
  }) {
    return ChapterSummary(
      id: 'summary-$chapterId',
      chapterId: chapterId,
      manuscriptId: manuscriptId,
      summary: summary,
      sourceWordCount: sourceWordCount,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );
  }

  group('ChapterSummaryRepository', () {
    test(
      'put stores summary keyed by chapterId and getByChapterId retrieves it',
      () async {
        await repository.put(createSummary(chapterId: 'ch-1'));

        final retrieved = repository.getByChapterId('ch-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.chapterId, 'ch-1');
        expect(retrieved.summary, '概括内容');
        expect(retrieved.sourceWordCount, 100);
      },
    );

    test('getByChapterId returns null when no summary stored', () {
      expect(repository.getByChapterId('missing'), isNull);
    });

    test('getByManuscriptId filters by manuscript', () async {
      await repository.put(
        createSummary(chapterId: 'ch-1', manuscriptId: 'ms-1'),
      );
      await repository.put(
        createSummary(chapterId: 'ch-2', manuscriptId: 'ms-1'),
      );
      await repository.put(
        createSummary(chapterId: 'ch-3', manuscriptId: 'ms-2'),
      );

      final ms1 = repository.getByManuscriptId('ms-1');
      expect(ms1.length, 2);
      expect(ms1.every((s) => s.manuscriptId == 'ms-1'), isTrue);
    });

    test('put overwrites existing summary for same chapter (1:1 upsert)', () async {
      await repository.put(
        createSummary(chapterId: 'ch-1', sourceWordCount: 100, summary: '旧概括'),
      );
      await repository.put(
        createSummary(chapterId: 'ch-1', sourceWordCount: 200, summary: '新概括'),
      );

      final retrieved = repository.getByChapterId('ch-1');
      expect(retrieved!.sourceWordCount, 200);
      expect(retrieved.summary, '新概括');
      expect(repository.getByManuscriptId('ms-1').length, 1);
    });

    test('delete removes the summary', () async {
      await repository.put(createSummary(chapterId: 'ch-1'));
      await repository.delete('ch-1');

      expect(repository.getByChapterId('ch-1'), isNull);
    });
  });
}

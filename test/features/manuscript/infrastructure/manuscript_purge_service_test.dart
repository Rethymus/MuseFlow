import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_purge_service.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late Box<dynamic> manuscriptBox;
  late Box<dynamic> chapterBox;
  late ManuscriptRepository manuscriptRepo;
  late ChapterRepository chapterRepo;
  late ManuscriptPurgeService purgeService;

  setUp(() async {
    await setUpHiveTest();
    manuscriptBox = await Hive.openBox<dynamic>('test_purge_manuscripts');
    chapterBox = await Hive.openBox<dynamic>('test_purge_chapters');
    manuscriptRepo = ManuscriptRepository(manuscriptBox);
    chapterRepo = ChapterRepository(chapterBox);
    purgeService = ManuscriptPurgeService(
      manuscriptRepository: manuscriptRepo,
      chapterRepository: chapterRepo,
    );
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  test('purgeExpired deletes chapters then manuscripts older than 30 days', () async {
    final now = DateTime.now();
    final oldDate = now.subtract(const Duration(days: 31));
    final recentDate = now.subtract(const Duration(days: 5));

    // Old soft-deleted manuscript (should be purged)
    final oldManuscript = Manuscript(
      id: 'old-ms',
      title: 'Old',
      genre: '玄幻',
      createdAt: now,
      updatedAt: now,
      deletedAt: oldDate,
    );
    await manuscriptBox.put('old-ms', oldManuscript.toJson());

    // Add chapters belonging to old manuscript
    final oldChapter = Chapter(
      id: 'old-ch-1',
      manuscriptId: 'old-ms',
      title: 'Old Chapter',
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
    await chapterBox.put('old-ch-1', oldChapter.toJson());

    // Recent soft-deleted manuscript (should NOT be purged)
    final recentManuscript = Manuscript(
      id: 'recent-ms',
      title: 'Recent',
      genre: '科幻',
      createdAt: now,
      updatedAt: now,
      deletedAt: recentDate,
    );
    await manuscriptBox.put('recent-ms', recentManuscript.toJson());

    final recentChapter = Chapter(
      id: 'recent-ch-1',
      manuscriptId: 'recent-ms',
      title: 'Recent Chapter',
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
    await chapterBox.put('recent-ch-1', recentChapter.toJson());

    await purgeService.purgeExpired();

    // Old manuscript and chapter should be gone
    expect(manuscriptRepo.getById('old-ms'), isNull);
    expect(chapterRepo.getById('old-ch-1'), isNull);

    // Recent manuscript and chapter should still exist
    expect(manuscriptRepo.getById('recent-ms'), isNotNull);
    expect(chapterRepo.getById('recent-ch-1'), isNotNull);
  });

  test('purgeExpired with custom retention period', () async {
    final now = DateTime.now();
    final date8DaysAgo = now.subtract(const Duration(days: 8));

    final manuscript = Manuscript(
      id: 'custom-ms',
      title: 'Custom',
      genre: '玄幻',
      createdAt: now,
      updatedAt: now,
      deletedAt: date8DaysAgo,
    );
    await manuscriptBox.put('custom-ms', manuscript.toJson());

    // Default 30 days should NOT purge
    await purgeService.purgeExpired();
    expect(manuscriptRepo.getById('custom-ms'), isNotNull);

    // 7-day retention should purge
    await purgeService.purgeExpired(retention: const Duration(days: 7));
    expect(manuscriptRepo.getById('custom-ms'), isNull);
  });

  test('purgeExpired does not touch non-deleted manuscripts', () async {
    final now = DateTime.now();
    final active = Manuscript(
      id: 'active-ms',
      title: 'Active',
      genre: '玄幻',
      createdAt: now.subtract(const Duration(days: 100)),
      updatedAt: now.subtract(const Duration(days: 100)),
    );
    await manuscriptBox.put('active-ms', active.toJson());

    await purgeService.purgeExpired();

    expect(manuscriptRepo.getById('active-ms'), isNotNull);
  });
}

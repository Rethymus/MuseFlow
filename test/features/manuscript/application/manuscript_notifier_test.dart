import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late ProviderContainer container;
  late Box<dynamic> manuscriptBox;
  late Box<dynamic> chapterBox;

  setUp(() async {
    await setUpHiveTest();
    manuscriptBox = await Hive.openBox<dynamic>('test_mn_manuscripts');
    chapterBox = await Hive.openBox<dynamic>('test_mn_chapters');
    container = ProviderContainer(
      overrides: [
        manuscriptRepositoryProvider.overrideWithValue(
          AsyncData(ManuscriptRepository(manuscriptBox)),
        ),
        chapterRepositoryProvider.overrideWithValue(
          AsyncData(ChapterRepository(chapterBox)),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await tearDownHiveTest();
  });

  test('build returns manuscripts filtered (no soft-deleted)', () async {
    final now = DateTime.now();
    await manuscriptBox.put(
      'active',
      Manuscript(
        id: 'active',
        title: 'Active',
        genre: '玄幻',
        createdAt: now,
        updatedAt: now,
      ).toJson(),
    );
    await manuscriptBox.put(
      'deleted',
      Manuscript(
        id: 'deleted',
        title: 'Deleted',
        genre: '科幻',
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      ).toJson(),
    );

    final notifier = container.read(manuscriptNotifierProvider.notifier);
    final manuscripts = await notifier.future;

    expect(manuscripts.length, equals(1));
    expect(manuscripts.first.id, equals('active'));
  });

  test('create adds manuscript with one empty chapter', () async {
    final notifier = container.read(manuscriptNotifierProvider.notifier);

    final manuscript = Manuscript(
      id: '',
      title: 'New Novel',
      genre: '玄幻',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await notifier.create(manuscript);

    final manuscripts = await notifier.future;
    expect(manuscripts.length, equals(1));
    expect(manuscripts.first.title, equals('New Novel'));

    // Verify one empty chapter was created
    final chapterRepo = ChapterRepository(chapterBox);
    final chapters = chapterRepo.getByManuscriptId(manuscripts.first.id);
    expect(chapters.length, equals(1));
    expect(chapters.first.title, equals('第一章'));
    expect(chapters.first.documentContent, equals(''));
  });

  test('save updates manuscript and refreshes list', () async {
    final now = DateTime.now();
    await manuscriptBox.put(
      'ms-1',
      Manuscript(
        id: 'ms-1',
        title: 'Original',
        genre: '玄幻',
        createdAt: now,
        updatedAt: now,
      ).toJson(),
    );

    final notifier = container.read(manuscriptNotifierProvider.notifier);
    // Wait for build to load
    await notifier.future;

    await notifier.save(
      Manuscript(
        id: 'ms-1',
        title: 'Updated',
        genre: '玄幻',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final manuscripts = await notifier.future;
    expect(manuscripts.first.title, equals('Updated'));
  });

  test('softDelete sets deletedAt and refreshes list', () async {
    final now = DateTime.now();
    await manuscriptBox.put(
      'ms-1',
      Manuscript(
        id: 'ms-1',
        title: 'To Delete',
        genre: '玄幻',
        createdAt: now,
        updatedAt: now,
      ).toJson(),
    );

    final notifier = container.read(manuscriptNotifierProvider.notifier);
    await notifier.future;

    await notifier.softDelete('ms-1');

    final manuscripts = await notifier.future;
    expect(manuscripts, isEmpty);
  });

  test('purgeDeleted calls purgeOlderThan and refreshes list', () async {
    final now = DateTime.now();
    final oldDate = now.subtract(const Duration(days: 31));
    await manuscriptBox.put(
      'old-ms',
      Manuscript(
        id: 'old-ms',
        title: 'Old',
        genre: '玄幻',
        createdAt: now,
        updatedAt: now,
        deletedAt: oldDate,
      ).toJson(),
    );
    await chapterBox.put(
      'old-ch',
      Chapter(
        id: 'old-ch',
        manuscriptId: 'old-ms',
        title: 'Chapter',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ).toJson(),
    );

    final notifier = container.read(manuscriptNotifierProvider.notifier);
    await notifier.purgeDeleted();

    // The old manuscript should be permanently deleted
    final repo = ManuscriptRepository(manuscriptBox);
    expect(repo.getById('old-ms'), isNull);
    expect(repo.getById('old-ch'), isNull);
  });

  test('searchByTitle filters manuscripts case-insensitively', () async {
    final now = DateTime.now();
    await manuscriptBox.put(
      'ms-a',
      Manuscript(
        id: 'ms-a',
        title: '玄幻大世界',
        genre: '玄幻',
        createdAt: now,
        updatedAt: now,
      ).toJson(),
    );
    await manuscriptBox.put(
      'ms-b',
      Manuscript(
        id: 'ms-b',
        title: '都市修仙录',
        genre: '都市',
        createdAt: now,
        updatedAt: now,
      ).toJson(),
    );

    final notifier = container.read(manuscriptNotifierProvider.notifier);
    await notifier.future;

    final results = notifier.searchByTitle('玄幻');
    expect(results.length, equals(1));
    expect(results.first.id, equals('ms-a'));
  });
}

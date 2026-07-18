import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/manuscript/application/manuscript_backup_service.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';

void main() {
  late Directory tempDirectory;
  late ManuscriptRepository manuscriptRepository;
  late ChapterRepository chapterRepository;
  late ManuscriptBackupService service;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('museflow_backup_');
    Hive.init(tempDirectory.path);
    manuscriptRepository = ManuscriptRepository(
      await Hive.openBox<dynamic>('manuscripts'),
    );
    chapterRepository = ChapterRepository(
      await Hive.openBox<dynamic>('chapters'),
    );
    service = ManuscriptBackupService(
      manuscriptRepository: manuscriptRepository,
      chapterRepository: chapterRepository,
    );
  });

  tearDown(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test('exports and restores every active manuscript and chapter', () async {
    await _seed(manuscriptRepository, chapterRepository);

    final backup = service.exportJson();
    final decoded = jsonDecode(backup) as Map<String, dynamic>;
    expect(decoded['schema'], ManuscriptBackupService.schema);
    expect(decoded['manuscripts'], hasLength(1));
    expect(decoded['chapters'], hasLength(2));

    await Hive.close();
    final restoreDirectory = await Directory.systemTemp.createTemp(
      'museflow_restore_',
    );
    addTearDown(() async {
      await Hive.close();
      await restoreDirectory.delete(recursive: true);
    });
    Hive.init(restoreDirectory.path);
    final restoredManuscripts = ManuscriptRepository(
      await Hive.openBox<dynamic>('manuscripts'),
    );
    final restoredChapters = ChapterRepository(
      await Hive.openBox<dynamic>('chapters'),
    );
    final result = await ManuscriptBackupService(
      manuscriptRepository: restoredManuscripts,
      chapterRepository: restoredChapters,
    ).importJson(backup);

    expect(result.manuscriptCount, 1);
    expect(result.chapterCount, 2);
    expect(restoredManuscripts.getAll().single.title, '测试小说');
    expect(
      restoredChapters
          .getByManuscriptId('manuscript-1')
          .map((c) => c.documentContent),
      ['第1章正文', '第2章正文'],
    );
  });

  test('remaps collisions without overwriting existing work', () async {
    await _seed(manuscriptRepository, chapterRepository);
    final backup = service.exportJson();

    final result = await service.importJson(backup);

    expect(result.manuscriptCount, 1);
    expect(manuscriptRepository.getAll(), hasLength(2));
    final imported = manuscriptRepository.getAll().singleWhere(
      (item) => item.id != 'manuscript-1',
    );
    expect(imported.title, '测试小说（导入）');
    expect(chapterRepository.getByManuscriptId(imported.id), hasLength(2));
    expect(chapterRepository.getByManuscriptId('manuscript-1'), hasLength(2));
  });

  test('rejects malformed relationships before writing anything', () async {
    final now = DateTime.utc(2026, 7, 18).toIso8601String();
    final malformed = jsonEncode({
      'schema': ManuscriptBackupService.schema,
      'manuscripts': <Object>[],
      'chapters': [
        {
          'id': 'orphan',
          'manuscriptId': 'missing',
          'title': '孤立章节',
          'sortOrder': 0,
          'status': 'draft',
          'documentContent': '正文',
          'createdAt': now,
          'updatedAt': now,
        },
      ],
    });

    await expectLater(
      service.importJson(malformed),
      throwsA(isA<FormatException>()),
    );
    expect(manuscriptRepository.getAll(), isEmpty);
    expect(chapterRepository.getAll(), isEmpty);
  });
}

Future<void> _seed(
  ManuscriptRepository manuscripts,
  ChapterRepository chapters,
) async {
  final now = DateTime.utc(2026, 7, 18);
  await manuscripts.add(
    Manuscript(
      id: 'manuscript-1',
      title: '测试小说',
      genre: '奇幻',
      createdAt: now,
      updatedAt: now,
    ),
  );
  for (var index = 0; index < 2; index++) {
    await chapters.add(
      Chapter(
        id: 'chapter-${index + 1}',
        manuscriptId: 'manuscript-1',
        title: '第${index + 1}章',
        sortOrder: index,
        documentContent: '第${index + 1}章正文',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

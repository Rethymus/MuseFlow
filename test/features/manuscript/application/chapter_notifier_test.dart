import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';
import 'package:museflow/features/manuscript/application/chapter_notifier.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late ProviderContainer container;
  late Box<dynamic> chapterBox;
  late Box<dynamic> manuscriptBox;
  late ChapterRepository chapterRepo;

  setUp(() async {
    await setUpHiveTest();
    manuscriptBox = await Hive.openBox<dynamic>('test_cn_manuscripts');
    chapterBox = await Hive.openBox<dynamic>('test_cn_chapters');
    chapterRepo = ChapterRepository(chapterBox);
    container = ProviderContainer(
      overrides: [
        chapterRepositoryProvider
            .overrideWithValue(AsyncData(chapterRepo)),
        manuscriptRepositoryProvider.overrideWithValue(
          AsyncData(ManuscriptRepository(manuscriptBox)),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await tearDownHiveTest();
  });

  Chapter _createChapter({
    required String id,
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

  test('build returns empty list by default', () async {
    final notifier = container.read(chapterNotifierProvider.notifier);
    final chapters = await notifier.future;
    expect(chapters, isEmpty);
  });

  test('loadChapters loads chapters for a manuscriptId ordered by sortOrder', () async {
    await chapterBox.put('ch-1', _createChapter(id: 'ch-1', sortOrder: 2, title: 'Second').toJson());
    await chapterBox.put('ch-2', _createChapter(id: 'ch-2', sortOrder: 0, title: 'First').toJson());
    await chapterBox.put('ch-3', _createChapter(id: 'ch-3', sortOrder: 1, title: 'Middle').toJson());

    final notifier = container.read(chapterNotifierProvider.notifier);
    await notifier.loadChapters('ms-1');

    final chapters = await notifier.future;
    expect(chapters.length, equals(3));
    expect(chapters[0].title, equals('First'));
    expect(chapters[1].title, equals('Middle'));
    expect(chapters[2].title, equals('Second'));
  });

  test('add creates chapter and refreshes list', () async {
    final notifier = container.read(chapterNotifierProvider.notifier);
    await notifier.loadChapters('ms-1');

    await notifier.add(_createChapter(id: 'ch-new', title: 'New Chapter'));

    final chapters = await notifier.future;
    expect(chapters.length, equals(1));
    expect(chapters.first.title, equals('New Chapter'));
  });

  test('save updates chapter and refreshes list', () async {
    await chapterBox.put('ch-1', _createChapter(id: 'ch-1', title: 'Original').toJson());

    final notifier = container.read(chapterNotifierProvider.notifier);
    await notifier.loadChapters('ms-1');

    await notifier.save(_createChapter(id: 'ch-1', title: 'Updated'));

    final chapters = await notifier.future;
    expect(chapters.first.title, equals('Updated'));
  });

  test('delete removes chapter and refreshes list', () async {
    await chapterBox.put('ch-1', _createChapter(id: 'ch-1').toJson());

    final notifier = container.read(chapterNotifierProvider.notifier);
    await notifier.loadChapters('ms-1');

    await notifier.delete('ch-1');

    final chapters = await notifier.future;
    expect(chapters, isEmpty);
  });

  test('reorder recalculates sortOrder to sequential 0,1,2,... after reordering', () async {
    await chapterBox.put('ch-1', _createChapter(id: 'ch-1', sortOrder: 0, title: 'A').toJson());
    await chapterBox.put('ch-2', _createChapter(id: 'ch-2', sortOrder: 1, title: 'B').toJson());
    await chapterBox.put('ch-3', _createChapter(id: 'ch-3', sortOrder: 2, title: 'C').toJson());

    final notifier = container.read(chapterNotifierProvider.notifier);
    await notifier.loadChapters('ms-1');

    // Move item at index 2 to index 0 (C moves to front)
    await notifier.reorder('ms-1', 2, 0);

    final chapters = await notifier.future;
    expect(chapters.length, equals(3));
    // After reorder: C(0), A(1), B(2)
    expect(chapters[0].title, equals('C'));
    expect(chapters[0].sortOrder, equals(0));
    expect(chapters[1].title, equals('A'));
    expect(chapters[1].sortOrder, equals(1));
    expect(chapters[2].title, equals('B'));
    expect(chapters[2].sortOrder, equals(2));
  });

  test('duplicateChapter creates copy with title suffix "(副本)" and next sortOrder', () async {
    await chapterBox.put('ch-1', _createChapter(id: 'ch-1', sortOrder: 0, title: '第一章', documentContent: 'Some content').toJson());
    await chapterBox.put('ch-2', _createChapter(id: 'ch-2', sortOrder: 1, title: '第二章').toJson());

    final notifier = container.read(chapterNotifierProvider.notifier);
    await notifier.loadChapters('ms-1');

    await notifier.duplicateChapter('ch-1');

    final chapters = await notifier.future;
    expect(chapters.length, equals(3));

    final duplicate = chapters.firstWhere((c) => c.title == '第一章(副本)');
    expect(duplicate.manuscriptId, equals('ms-1'));
    expect(duplicate.sortOrder, equals(2));
    expect(duplicate.documentContent, equals('Some content'));
  });

  test('splitChapter updates current chapter with beforeContent and creates new chapter with afterContent', () async {
    await chapterBox.put('ch-1', _createChapter(id: 'ch-1', sortOrder: 0, title: 'Long Chapter', documentContent: 'Part One Content').toJson());
    await chapterBox.put('ch-2', _createChapter(id: 'ch-2', sortOrder: 1, title: 'Next Chapter').toJson());

    final notifier = container.read(chapterNotifierProvider.notifier);
    await notifier.loadChapters('ms-1');

    await notifier.splitChapter('ch-1', 'Part One', 'Part Two');

    final chapters = await notifier.future;
    expect(chapters.length, equals(3));

    // Original chapter updated with beforeContent
    final original = chapters.firstWhere((c) => c.id == 'ch-1');
    expect(original.documentContent, equals('Part One'));

    // New chapter created with afterContent, inserted after original
    final newChapter = chapters.firstWhere((c) => c.title == 'Long Chapter (续)');
    expect(newChapter.documentContent, equals('Part Two'));
    expect(newChapter.sortOrder, equals(1));

    // Existing chapter shifted
    final shifted = chapters.firstWhere((c) => c.id == 'ch-2');
    expect(shifted.sortOrder, equals(2));
  });

  test('mergeChapters combines content and deletes second chapter', () async {
    await chapterBox.put('ch-1', _createChapter(id: 'ch-1', sortOrder: 0, title: 'First', documentContent: 'Hello').toJson());
    await chapterBox.put('ch-2', _createChapter(id: 'ch-2', sortOrder: 1, title: 'Second', documentContent: 'World').toJson());
    await chapterBox.put('ch-3', _createChapter(id: 'ch-3', sortOrder: 2, title: 'Third').toJson());

    final notifier = container.read(chapterNotifierProvider.notifier);
    await notifier.loadChapters('ms-1');

    await notifier.mergeChapters('ch-1', 'ch-2');

    final chapters = await notifier.future;
    expect(chapters.length, equals(2));

    // Merged content
    final merged = chapters.firstWhere((c) => c.id == 'ch-1');
    expect(merged.documentContent, equals('Hello\n\nWorld'));

    // Second chapter deleted, third shifted down
    final shifted = chapters.firstWhere((c) => c.id == 'ch-3');
    expect(shifted.sortOrder, equals(1));
  });
}

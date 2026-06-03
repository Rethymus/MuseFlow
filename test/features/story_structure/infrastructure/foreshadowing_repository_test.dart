import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/infrastructure/foreshadowing_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late ForeshadowingRepository repository;
  late Box<dynamic> box;

  setUp(() async {
    await setUpHiveTest();
    box = await Hive.openBox<dynamic>('test_foreshadowing_entries');
    repository = ForeshadowingRepository(box);
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  ForeshadowingEntry _makeEntry({
    required String id,
    String title = 'Test Foreshadowing',
    ForeshadowingStatus status = ForeshadowingStatus.planted,
    int plantedChapter = 1,
  }) {
    return ForeshadowingEntry(
      id: id,
      title: title,
      mode: ForeshadowingMode.detailed,
      status: status,
      plantedChapter: plantedChapter,
      createdAt: DateTime(2026),
    );
  }

  group('ForeshadowingRepository', () {
    test('add should persist entry and return with id', () async {
      final entry = _makeEntry(id: 'e1');
      final saved = await repository.add(entry);

      expect(saved.id, 'e1');
      expect(saved.title, 'Test Foreshadowing');
    });

    test('getAll should return all persisted entries', () async {
      await repository.add(_makeEntry(id: 'e1'));
      await repository.add(_makeEntry(id: 'e2'));

      final all = repository.getAll();
      expect(all, hasLength(2));
      expect(all.map((e) => e.id), containsAll(['e1', 'e2']));
    });

    test('getById should return entry when exists', () async {
      await repository.add(_makeEntry(id: 'e1'));

      final found = repository.getById('e1');
      expect(found, isNotNull);
      expect(found!.id, 'e1');
    });

    test('getById should return null when not found', () {
      final found = repository.getById('nonexistent');
      expect(found, isNull);
    });

    test('update should modify existing entry', () async {
      await repository.add(_makeEntry(id: 'e1', title: 'Original'));

      final updated = _makeEntry(id: 'e1', title: 'Updated');
      await repository.update(updated);

      final found = repository.getById('e1');
      expect(found!.title, 'Updated');
      expect(found.updatedAt, isNotNull);
    });

    test('delete should remove entry', () async {
      await repository.add(_makeEntry(id: 'e1'));
      await repository.delete('e1');

      final found = repository.getById('e1');
      expect(found, isNull);
    });

    test('delete should not throw for nonexistent id', () async {
      // Should complete without error
      await repository.delete('nonexistent');
    });

    test('add should generate UUID when id is empty', () async {
      final entry = ForeshadowingEntry(
        id: '',
        title: 'Auto-ID',
        mode: ForeshadowingMode.simple,
        status: ForeshadowingStatus.planted,
        plantedChapter: 1,
        createdAt: DateTime(2026),
      );

      final saved = await repository.add(entry);
      expect(saved.id, isNotEmpty);
      expect(saved.id, isNot(equals('')));
    });

    test('entries should roundtrip through Hive storage', () async {
      final entry = ForeshadowingEntry(
        id: 'roundtrip',
        title: 'Complex entry',
        mode: ForeshadowingMode.detailed,
        status: ForeshadowingStatus.developing,
        plantedChapter: 3,
        targetResolutionChapter: 10,
        sourceExcerpt: 'A mysterious shadow appeared.',
        sourceLocation: const SourceLocation(
          nodeId: 'para5',
          startOffset: 12,
          endOffset: 42,
          chapter: 3,
        ),
        notes: 'Needs resolution by chapter 10',
        linkedPlotNodeIds: ['plot-a', 'plot-b'],
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 2, 1),
      );

      // add() sets createdAt to now, so compare saved result from add
      final saved = await repository.add(entry);
      final restored = repository.getById('roundtrip');

      expect(restored, isNotNull);
      expect(restored!.id, saved.id);
      expect(restored.title, saved.title);
      expect(restored.mode, saved.mode);
      expect(restored.status, saved.status);
      expect(restored.plantedChapter, saved.plantedChapter);
      expect(restored.targetResolutionChapter, saved.targetResolutionChapter);
      expect(restored.sourceExcerpt, saved.sourceExcerpt);
      expect(restored.sourceLocation, saved.sourceLocation);
      expect(restored.notes, saved.notes);
      expect(restored.linkedPlotNodeIds, saved.linkedPlotNodeIds);
    });
  });
}

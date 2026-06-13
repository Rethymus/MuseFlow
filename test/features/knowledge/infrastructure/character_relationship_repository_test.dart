/// Tests for CharacterRelationshipRepository.
///
/// Per Phase 21 (KNOW-02): Validates CRUD operations, querying by
/// character ID, and bidirectional relationship lookup.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/knowledge/domain/character_relationship.dart';
import 'package:museflow/features/knowledge/infrastructure/character_relationship_repository.dart';
import '../../../helpers/hive_test_helper.dart';

void main() {
  late CharacterRelationshipRepository repository;

  final rel1 = CharacterRelationship(
    id: 'rel-1',
    fromCharacterId: 'char-1',
    toCharacterId: 'char-2',
    type: RelationshipType.mentor,
    description: '师父',
    createdAt: DateTime(2026, 1, 1),
  );

  final rel2 = CharacterRelationship(
    id: 'rel-2',
    fromCharacterId: 'char-2',
    toCharacterId: 'char-3',
    type: RelationshipType.enemy,
    description: '宿敌',
    createdAt: DateTime(2026, 1, 2),
  );

  final rel3 = CharacterRelationship(
    id: 'rel-3',
    fromCharacterId: 'char-3',
    toCharacterId: 'char-1',
    type: RelationshipType.ally,
    createdAt: DateTime(2026, 1, 3),
  );

  setUp(() async {
    await setUpHiveTest();
    final box = await Hive.openBox<dynamic>('test_relationships');
    repository = CharacterRelationshipRepository(box);
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  group('getAll', () {
    test('should return empty list when box is empty', () {
      expect(repository.getAll(), isEmpty);
    });

    test('should return all stored relationships', () async {
      await repository.add(rel1);
      await repository.add(rel2);

      final result = repository.getAll();
      expect(result.length, 2);
      expect(result.map((r) => r.id), containsAll(['rel-1', 'rel-2']));
    });
  });

  group('getById', () {
    test('should return null for non-existent ID', () {
      expect(repository.getById('rel-99'), isNull);
    });

    test('should return relationship for existing ID', () async {
      await repository.add(rel1);
      final result = repository.getById('rel-1');
      expect(result, isNotNull);
      expect(result!.type, RelationshipType.mentor);
    });
  });

  group('getForCharacter', () {
    test(
      'should return relationships where character is source or target',
      () async {
        // char-1 is source in rel-1, target in rel-3
        await repository.add(rel1);
        await repository.add(rel2);
        await repository.add(rel3);

        final result = repository.getForCharacter('char-1');
        expect(result.length, 2);
        expect(result.map((r) => r.id), containsAll(['rel-1', 'rel-3']));
      },
    );

    test('should return empty for character with no relationships', () async {
      await repository.add(rel1);
      await repository.add(rel2);
      expect(repository.getForCharacter('char-99'), isEmpty);
    });
  });

  group('getBetween', () {
    test('should find relationship regardless of direction', () async {
      await repository.add(rel1);

      // Forward direction
      var result = repository.getBetween('char-1', 'char-2');
      expect(result, isNotNull);
      expect(result!.id, 'rel-1');

      // Reverse direction
      result = repository.getBetween('char-2', 'char-1');
      expect(result, isNotNull);
      expect(result!.id, 'rel-1');
    });

    test('should return null when no relationship exists', () async {
      await repository.add(rel1);
      expect(repository.getBetween('char-1', 'char-3'), isNull);
    });
  });

  group('add', () {
    test('should store relationship when ID does not exist', () async {
      await repository.add(rel1);
      expect(repository.getById('rel-1'), isNotNull);
    });

    test('should throw StateError when ID already exists', () async {
      await repository.add(rel1);
      expect(() => repository.add(rel1), throwsA(isA<StateError>()));
    });
  });

  group('update', () {
    test('should update existing relationship', () async {
      await repository.add(rel1);
      final updated = rel1.copyWith(type: RelationshipType.ally);
      await repository.update(updated);

      final result = repository.getById('rel-1');
      expect(result!.type, RelationshipType.ally);
    });

    test('should throw StateError when ID does not exist', () async {
      expect(() => repository.update(rel1), throwsA(isA<StateError>()));
    });
  });

  group('delete', () {
    test('should return true when relationship exists', () async {
      await repository.add(rel1);
      expect(await repository.delete('rel-1'), isTrue);
      expect(repository.getById('rel-1'), isNull);
    });

    test('should return false when relationship does not exist', () async {
      expect(await repository.delete('rel-99'), isFalse);
    });
  });

  group('deleteForCharacter', () {
    test('should delete all relationships for a character', () async {
      await repository.add(rel1);
      await repository.add(rel2);
      await repository.add(rel3);

      final count = await repository.deleteForCharacter('char-1');
      expect(count, 2);
      expect(repository.getAll().length, 1); // only rel-2 remains
    });

    test('should return zero for character with no relationships', () async {
      await repository.add(rel1);
      await repository.add(rel2);
      final count = await repository.deleteForCharacter('char-99');
      expect(count, 0);
    });
  });
}

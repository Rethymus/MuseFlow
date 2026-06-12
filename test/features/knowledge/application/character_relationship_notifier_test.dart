/// Tests for CharacterRelationshipNotifier.
///
/// Per Phase 21 (KNOW-02): Validates CRUD operations and
/// per-character querying through the notifier.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
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
    description: '师徒',
    createdAt: DateTime(2026, 1, 1),
  );

  final rel2 = CharacterRelationship(
    id: 'rel-2',
    fromCharacterId: 'char-2',
    toCharacterId: 'char-3',
    type: RelationshipType.enemy,
    createdAt: DateTime(2026, 1, 2),
  );

  final rel3 = CharacterRelationship(
    id: 'rel-3',
    fromCharacterId: 'char-1',
    toCharacterId: 'char-3',
    type: RelationshipType.ally,
    createdAt: DateTime(2026, 1, 3),
  );

  setUp(() async {
    await setUpHiveTest();
    final box = await Hive.openBox<dynamic>('test_rel_notifier');
    repository = CharacterRelationshipRepository(box);
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  group('CharacterRelationshipNotifier', () {
    test('should return empty list when no relationships exist', () async {
      final container = ProviderContainer(
        overrides: [
          characterRelationshipRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container
          .read(characterRelationshipNotifierProvider.notifier);
      await notifier.build();

      final state = container.read(characterRelationshipNotifierProvider);
      expect(state.asData?.value, isEmpty);
    });

    test('should add relationship and update state', () async {
      final container = ProviderContainer(
        overrides: [
          characterRelationshipRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container
          .read(characterRelationshipNotifierProvider.notifier);
      await notifier.add(rel1);

      // Invalidate self triggers rebuild
      container.invalidate(characterRelationshipNotifierProvider);
      await container.read(characterRelationshipNotifierProvider.future);

      final state = container.read(characterRelationshipNotifierProvider);
      expect(state.asData?.value.length, 1);
      expect(state.asData?.value.first.id, 'rel-1');
    });

    test('should save updated relationship', () async {
      final container = ProviderContainer(
        overrides: [
          characterRelationshipRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container
          .read(characterRelationshipNotifierProvider.notifier);
      await notifier.add(rel1);

      final updated = rel1.copyWith(type: RelationshipType.rival);
      await notifier.save(updated);

      expect(repository.getById('rel-1')!.type, RelationshipType.rival);
    });

    test('should delete relationship', () async {
      final container = ProviderContainer(
        overrides: [
          characterRelationshipRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container
          .read(characterRelationshipNotifierProvider.notifier);
      await notifier.add(rel1);
      await notifier.delete('rel-1');

      expect(repository.getById('rel-1'), isNull);
    });

    test('should query relationships for a character', () async {
      final container = ProviderContainer(
        overrides: [
          characterRelationshipRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container
          .read(characterRelationshipNotifierProvider.notifier);
      await notifier.add(rel1);
      await notifier.add(rel2);
      await notifier.add(rel3);

      // char-1 is in rel-1 (from) and rel-3 (from)
      container.invalidate(characterRelationshipNotifierProvider);
      await container.read(characterRelationshipNotifierProvider.future);

      final rels = notifier.getForCharacter('char-1');
      expect(rels.length, 2);
      expect(rels.map((r) => r.id), containsAll(['rel-1', 'rel-3']));
    });
  });
}

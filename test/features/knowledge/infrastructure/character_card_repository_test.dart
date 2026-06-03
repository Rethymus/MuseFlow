import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late Box<dynamic> box;
  late CharacterCardRepository repository;

  setUp(() async {
    await setUpHiveTest();
    box = await Hive.openBox<dynamic>('character_cards_test');
    repository = CharacterCardRepository(box);
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  group('CharacterCardRepository', () {
    final now = DateTime(2026, 1, 1);

    group('add', () {
      test('should add card and return it with generated ID', () async {
        final card = CharacterCard(
          id: '',
          name: '李逍遥',
          personality: '潇洒不羁',
          appearance: '剑眉星目',
          backstory: '仙灵岛长大',
          createdAt: now,
        );

        final result = await repository.add(card);

        expect(result.id, isNotEmpty);
        expect(result.name, equals('李逍遥'));
        expect(result.createdAt, isNotNull);
      });

      test('should preserve existing ID if provided', () async {
        final card = CharacterCard(
          id: 'custom-id',
          name: 'Test',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        );

        final result = await repository.add(card);

        expect(result.id, equals('custom-id'));
      });

      test('should persist card in box', () async {
        final card = CharacterCard(
          id: '',
          name: 'Persistent',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        );

        final added = await repository.add(card);
        final retrieved = repository.getById(added.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Persistent'));
      });
    });

    group('getAll', () {
      test('should return empty list when no cards', () {
        final result = repository.getAll();

        expect(result, isEmpty);
      });

      test('should return all added cards', () async {
        await repository.add(CharacterCard(
          id: '',
          name: 'Card1',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ));
        await repository.add(CharacterCard(
          id: '',
          name: 'Card2',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ));

        final result = repository.getAll();

        expect(result.length, equals(2));
        expect(result.map((c) => c.name), containsAll(['Card1', 'Card2']));
      });
    });

    group('getById', () {
      test('should return null for non-existent ID', () {
        final result = repository.getById('non-existent');

        expect(result, isNull);
      });

      test('should return card by ID', () async {
        final added = await repository.add(CharacterCard(
          id: '',
          name: 'FindMe',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ));

        final result = repository.getById(added.id);

        expect(result, isNotNull);
        expect(result!.name, equals('FindMe'));
      });
    });

    group('update', () {
      test('should update existing card and set updatedAt', () async {
        final added = await repository.add(CharacterCard(
          id: '',
          name: 'Original',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ));

        final updated = added.copyWith(name: 'Updated');
        await repository.update(updated);

        final result = repository.getById(added.id);
        expect(result!.name, equals('Updated'));
        expect(result.updatedAt, isNotNull);
      });

      test('should persist changes in box', () async {
        final added = await repository.add(CharacterCard(
          id: '',
          name: 'Original',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ));

        await repository.update(added.copyWith(name: 'Changed'));

        final result = repository.getById(added.id);
        expect(result!.name, equals('Changed'));
      });
    });

    group('delete', () {
      test('should remove card from box', () async {
        final added = await repository.add(CharacterCard(
          id: '',
          name: 'ToDelete',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ));

        await repository.delete(added.id);

        final result = repository.getById(added.id);
        expect(result, isNull);
      });

      test('should not throw when deleting non-existent ID', () async {
        // Should complete without error
        await repository.delete('non-existent');
      });
    });

    group('searchByName', () {
      test('should find cards by name substring (case-insensitive)', () async {
        await repository.add(CharacterCard(
          id: '',
          name: '李逍遥',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ));
        await repository.add(CharacterCard(
          id: '',
          name: '赵灵儿',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ));

        final result = repository.searchByName('逍遥');

        expect(result.length, equals(1));
        expect(result.first.name, equals('李逍遥'));
      });

      test('should find cards by alias substring', () async {
        await repository.add(CharacterCard(
          id: '',
          name: '李逍遥',
          personality: '',
          appearance: '',
          backstory: '',
          aliases: ['逍遥哥哥', '灵儿的心上人'],
          createdAt: now,
        ));

        final result = repository.searchByName('心上人');

        expect(result.length, equals(1));
        expect(result.first.name, equals('李逍遥'));
      });

      test('should return empty list when no match', () async {
        await repository.add(CharacterCard(
          id: '',
          name: '李逍遥',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ));

        final result = repository.searchByName('不存在');

        expect(result, isEmpty);
      });
    });
  });
}

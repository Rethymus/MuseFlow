import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/entity_type.dart';

void main() {
  group('CharacterCard', () {
    final now = DateTime(2026, 1, 1);
    final baseCard = CharacterCard(
      id: 'test-id',
      name: '李逍遥',
      personality: '潇洒不羁，重情重义',
      appearance: '剑眉星目，身披青衫',
      backstory: '从小在仙灵岛长大，师从酒剑仙',
      aliases: ['逍遥', '李大哥'],
      createdAt: now,
    );

    group('construction', () {
      test('should create CharacterCard with required fields', () {
        expect(baseCard.id, equals('test-id'));
        expect(baseCard.name, equals('李逍遥'));
        expect(baseCard.personality, equals('潇洒不羁，重情重义'));
        expect(baseCard.appearance, equals('剑眉星目，身披青衫'));
        expect(baseCard.backstory, equals('从小在仙灵岛长大，师从酒剑仙'));
        expect(baseCard.aliases, equals(['逍遥', '李大哥']));
        expect(baseCard.createdAt, equals(now));
        expect(baseCard.updatedAt, isNull);
      });

      test('should have default empty aliases', () {
        final card = CharacterCard(
          id: 'id',
          name: 'Test',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        );
        expect(card.aliases, isEmpty);
      });
    });

    group('copyWith', () {
      test('should produce new instance with updated fields', () {
        final updated = baseCard.copyWith(name: '赵灵儿', updatedAt: now);

        expect(updated.name, equals('赵灵儿'));
        expect(updated.id, equals(baseCard.id));
        expect(updated.personality, equals(baseCard.personality));
        expect(updated.updatedAt, equals(now));
        expect(identical(updated, baseCard), isFalse);
      });

      test('should preserve unchanged fields', () {
        final updated = baseCard.copyWith(name: 'New Name');

        expect(updated.id, equals(baseCard.id));
        expect(updated.personality, equals(baseCard.personality));
        expect(updated.appearance, equals(baseCard.appearance));
        expect(updated.backstory, equals(baseCard.backstory));
        expect(updated.aliases, equals(baseCard.aliases));
        expect(updated.createdAt, equals(baseCard.createdAt));
      });
    });

    group('fromJson/toJson', () {
      test('should roundtrip through JSON serialization', () {
        final json = baseCard.toJson();
        final restored = CharacterCard.fromJson(json);

        expect(restored, equals(baseCard));
        expect(restored.hashCode, equals(baseCard.hashCode));
      });

      test('should handle null updatedAt', () {
        final json = baseCard.toJson();
        expect(json['updatedAt'], isNull);

        final restored = CharacterCard.fromJson(json);
        expect(restored.updatedAt, isNull);
      });

      test('should handle non-null updatedAt', () {
        final withUpdate = baseCard.copyWith(updatedAt: now);
        final json = withUpdate.toJson();
        final restored = CharacterCard.fromJson(json);

        expect(restored.updatedAt, equals(now));
      });
    });

    group('lastVerifiedChapter (MC-01 staleness)', () {
      test('defaults to null when not provided', () {
        expect(baseCard.lastVerifiedChapter, isNull);
      });

      test('persists through JSON round-trip', () {
        final card = baseCard.copyWith(lastVerifiedChapter: 42);
        final restored = CharacterCard.fromJson(card.toJson());
        expect(restored.lastVerifiedChapter, 42);
        expect(restored, equals(card));
      });

      test('legacy JSON without the key parses to null (backward-compat)', () {
        // Simulate a pre-MC-01 persisted card.
        final legacyJson = baseCard.toJson()..remove('lastVerifiedChapter');
        final restored = CharacterCard.fromJson(legacyJson);
        expect(restored.lastVerifiedChapter, isNull);
        expect(restored.name, baseCard.name);
      });

      test('participates in equality and hashCode', () {
        final a = baseCard.copyWith(lastVerifiedChapter: 5);
        final b = baseCard.copyWith(lastVerifiedChapter: 5);
        final c = baseCard.copyWith(lastVerifiedChapter: 6);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
        expect(a, isNot(equals(c)));
      });
    });

    group('allNames', () {
      test('should return name plus aliases', () {
        expect(baseCard.allNames, equals(['李逍遥', '逍遥', '李大哥']));
      });

      test('should return only name when no aliases', () {
        final card = CharacterCard(
          id: 'id',
          name: 'Test',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        );
        expect(card.allNames, equals(['Test']));
      });
    });

    group('KnowledgeEntity interface', () {
      test('should return name as displayName', () {
        expect(baseCard.displayName, equals('李逍遥'));
      });

      test('should return formatted context string', () {
        final context = baseCard.toContextString;
        expect(context, contains('李逍遥'));
        expect(context, contains('潇洒不羁，重情重义'));
        expect(context, contains('剑眉星目，身披青衫'));
        expect(context, contains('从小在仙灵岛长大，师从酒剑仙'));
      });

      test('should return character entity type', () {
        expect(baseCard.entityType, equals(EntityType.character));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final copy = CharacterCard(
          id: 'test-id',
          name: '李逍遥',
          personality: '潇洒不羁，重情重义',
          appearance: '剑眉星目，身披青衫',
          backstory: '从小在仙灵岛长大，师从酒剑仙',
          aliases: ['逍遥', '李大哥'],
          createdAt: now,
        );
        expect(copy, equals(baseCard));
      });

      test('should not be equal when fields differ', () {
        final different = baseCard.copyWith(name: 'Different');
        expect(different, isNot(equals(baseCard)));
      });
    });

    group('field validation', () {
      test('should reject name exceeding 100 characters', () {
        expect(
          () => CharacterCard(
            id: 'id',
            name: 'a' * 101,
            personality: '',
            appearance: '',
            backstory: '',
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });

      test('should accept name at exactly 100 characters', () {
        expect(
          () => CharacterCard(
            id: 'id',
            name: 'a' * 100,
            personality: '',
            appearance: '',
            backstory: '',
            createdAt: now,
          ),
          returnsNormally,
        );
      });

      test('should reject name containing control characters', () {
        expect(
          () => CharacterCard(
            id: 'id',
            name: 'Valid\nName',
            personality: '',
            appearance: '',
            backstory: '',
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });

      test('should reject alias containing control characters', () {
        expect(
          () => CharacterCard(
            id: 'id',
            name: 'Valid',
            personality: '',
            appearance: '',
            backstory: '',
            aliases: ['Bad\tAlias'],
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });

      test('should reject personality exceeding 5000 characters', () {
        expect(
          () => CharacterCard(
            id: 'id',
            name: 'Valid',
            personality: 'b' * 5001,
            appearance: '',
            backstory: '',
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });

      test('should reject appearance exceeding 5000 characters', () {
        expect(
          () => CharacterCard(
            id: 'id',
            name: 'Valid',
            personality: '',
            appearance: 'c' * 5001,
            backstory: '',
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });

      test('should reject backstory exceeding 5000 characters', () {
        expect(
          () => CharacterCard(
            id: 'id',
            name: 'Valid',
            personality: '',
            appearance: '',
            backstory: 'd' * 5001,
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });

      test('should reject aliases exceeding 20 items', () {
        expect(
          () => CharacterCard(
            id: 'id',
            name: 'Valid',
            personality: '',
            appearance: '',
            backstory: '',
            aliases: List.generate(21, (i) => 'alias$i'),
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });

      test('should reject alias item exceeding 50 characters', () {
        expect(
          () => CharacterCard(
            id: 'id',
            name: 'Valid',
            personality: '',
            appearance: '',
            backstory: '',
            aliases: ['a' * 51],
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });
    });
  });
}

/// Tests for CharacterRelationship domain model.
///
/// Per Phase 21 (KNOW-02): Validates the character relationship entity
/// including creation, serialization, and type validation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/domain/character_relationship.dart';

void main() {
  group('CharacterRelationship', () {
    test('should create with required fields', () {
      final rel = CharacterRelationship(
        id: 'rel-1',
        fromCharacterId: 'char-1',
        toCharacterId: 'char-2',
        type: RelationshipType.mentor,
        description: '师父与徒弟的关系',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(rel.id, 'rel-1');
      expect(rel.fromCharacterId, 'char-1');
      expect(rel.toCharacterId, 'char-2');
      expect(rel.type, RelationshipType.mentor);
      expect(rel.description, '师父与徒弟的关系');
      expect(rel.createdAt, DateTime(2026, 1, 1));
    });

    test('should support all relationship types', () {
      for (final type in RelationshipType.values) {
        final rel = CharacterRelationship(
          id: 'rel-$type',
          fromCharacterId: 'a',
          toCharacterId: 'b',
          type: type,
          createdAt: DateTime.now(),
        );
        expect(rel.type, type);
      }
    });

    test('should return Chinese label for type', () {
      expect(RelationshipType.mentor.label, '师徒');
      expect(RelationshipType.enemy.label, '敌对');
      expect(RelationshipType.family.label, '家族');
      expect(RelationshipType.lover.label, '恋人');
      expect(RelationshipType.rival.label, '对手');
      expect(RelationshipType.ally.label, '盟友');
      expect(RelationshipType.subordinate.label, '上下级');
      expect(RelationshipType.friend.label, '朋友');
    });

    test('should serialize to JSON', () {
      final rel = CharacterRelationship(
        id: 'rel-1',
        fromCharacterId: 'char-1',
        toCharacterId: 'char-2',
        type: RelationshipType.mentor,
        description: '师父',
        createdAt: DateTime(2026, 1, 15, 10, 30),
      );

      final json = rel.toJson();
      expect(json['id'], 'rel-1');
      expect(json['fromCharacterId'], 'char-1');
      expect(json['toCharacterId'], 'char-2');
      expect(json['type'], 'mentor');
      expect(json['description'], '师父');
      expect(json['createdAt'], '2026-01-15T10:30:00.000');
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'rel-1',
        'fromCharacterId': 'char-1',
        'toCharacterId': 'char-2',
        'type': 'lover',
        'description': '青梅竹马',
        'createdAt': '2026-01-15T10:30:00.000',
      };

      final rel = CharacterRelationship.fromJson(json);
      expect(rel.id, 'rel-1');
      expect(rel.fromCharacterId, 'char-1');
      expect(rel.toCharacterId, 'char-2');
      expect(rel.type, RelationshipType.lover);
      expect(rel.description, '青梅竹马');
    });

    test('should copyWith correctly', () {
      final rel = CharacterRelationship(
        id: 'rel-1',
        fromCharacterId: 'char-1',
        toCharacterId: 'char-2',
        type: RelationshipType.enemy,
        description: '宿敌',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = rel.copyWith(
        type: RelationshipType.ally,
        description: '化敌为友',
      );

      expect(updated.id, 'rel-1');
      expect(updated.type, RelationshipType.ally);
      expect(updated.description, '化敌为友');
      expect(updated.fromCharacterId, 'char-1');
    });

    test('should implement equality', () {
      final now = DateTime(2026, 1, 1);
      final a = CharacterRelationship(
        id: 'rel-1',
        fromCharacterId: 'a',
        toCharacterId: 'b',
        type: RelationshipType.friend,
        createdAt: now,
      );
      final b = CharacterRelationship(
        id: 'rel-1',
        fromCharacterId: 'a',
        toCharacterId: 'b',
        type: RelationshipType.friend,
        createdAt: now,
      );

      expect(a, equals(b));
    });

    test('should generate context string for AI prompt', () {
      final rel = CharacterRelationship(
        id: 'rel-1',
        fromCharacterId: 'char-1',
        toCharacterId: 'char-2',
        type: RelationshipType.mentor,
        description: '师父与徒弟',
        createdAt: DateTime.now(),
      );

      final context = rel.toContextString('林风', '苏雪晴');
      expect(context, contains('林风'));
      expect(context, contains('苏雪晴'));
      expect(context, contains('师徒'));
    });
  });
}

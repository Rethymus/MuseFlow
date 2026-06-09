import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/domain/entity_type.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';

void main() {
  group('WorldSetting', () {
    final now = DateTime(2026, 1, 1);
    final baseSetting = WorldSetting(
      id: 'test-id',
      name: '修仙界',
      description: '一个以灵气为根基的修仙世界',
      rules: '天地法则，因果循环',
      factions: '正道联盟、魔道、散修',
      geography: '东洲、西荒、南疆、北冥',
      techLevel: '古代仙侠',
      aliases: ['仙界', '九天'],
      createdAt: now,
    );

    group('construction', () {
      test('should create WorldSetting with required fields', () {
        expect(baseSetting.id, equals('test-id'));
        expect(baseSetting.name, equals('修仙界'));
        expect(baseSetting.description, equals('一个以灵气为根基的修仙世界'));
        expect(baseSetting.rules, equals('天地法则，因果循环'));
        expect(baseSetting.factions, equals('正道联盟、魔道、散修'));
        expect(baseSetting.geography, equals('东洲、西荒、南疆、北冥'));
        expect(baseSetting.techLevel, equals('古代仙侠'));
        expect(baseSetting.aliases, equals(['仙界', '九天']));
        expect(baseSetting.createdAt, equals(now));
        expect(baseSetting.updatedAt, isNull);
      });

      test('should have default empty aliases', () {
        final setting = WorldSetting(
          id: 'id',
          name: 'Test',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        );
        expect(setting.aliases, isEmpty);
      });
    });

    group('copyWith', () {
      test('should produce new instance with updated fields', () {
        final updated = baseSetting.copyWith(name: '新世界', updatedAt: now);

        expect(updated.name, equals('新世界'));
        expect(updated.id, equals(baseSetting.id));
        expect(updated.updatedAt, equals(now));
        expect(identical(updated, baseSetting), isFalse);
      });

      test('should preserve unchanged fields', () {
        final updated = baseSetting.copyWith(name: 'New Name');

        expect(updated.id, equals(baseSetting.id));
        expect(updated.description, equals(baseSetting.description));
        expect(updated.rules, equals(baseSetting.rules));
        expect(updated.factions, equals(baseSetting.factions));
        expect(updated.geography, equals(baseSetting.geography));
        expect(updated.techLevel, equals(baseSetting.techLevel));
        expect(updated.aliases, equals(baseSetting.aliases));
        expect(updated.createdAt, equals(baseSetting.createdAt));
      });
    });

    group('fromJson/toJson', () {
      test('should roundtrip through JSON serialization', () {
        final json = baseSetting.toJson();
        final restored = WorldSetting.fromJson(json);

        expect(restored, equals(baseSetting));
        expect(restored.hashCode, equals(baseSetting.hashCode));
      });

      test('should handle null updatedAt', () {
        final json = baseSetting.toJson();
        expect(json['updatedAt'], isNull);

        final restored = WorldSetting.fromJson(json);
        expect(restored.updatedAt, isNull);
      });

      test('should handle non-null updatedAt', () {
        final withUpdate = baseSetting.copyWith(updatedAt: now);
        final json = withUpdate.toJson();
        final restored = WorldSetting.fromJson(json);

        expect(restored.updatedAt, equals(now));
      });
    });

    group('allNames', () {
      test('should return name plus aliases', () {
        expect(baseSetting.allNames, equals(['修仙界', '仙界', '九天']));
      });

      test('should return only name when no aliases', () {
        final setting = WorldSetting(
          id: 'id',
          name: 'Test',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        );
        expect(setting.allNames, equals(['Test']));
      });
    });

    group('KnowledgeEntity interface', () {
      test('should return name as displayName', () {
        expect(baseSetting.displayName, equals('修仙界'));
      });

      test('should return formatted context string with all fields', () {
        final context = baseSetting.toContextString;
        expect(context, contains('修仙界'));
        expect(context, contains('天地法则，因果循环'));
        expect(context, contains('正道联盟、魔道、散修'));
        expect(context, contains('东洲、西荒、南疆、北冥'));
        expect(context, contains('古代仙侠'));
      });

      test('should return setting entity type', () {
        expect(baseSetting.entityType, equals(EntityType.setting));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final copy = WorldSetting(
          id: 'test-id',
          name: '修仙界',
          description: '一个以灵气为根基的修仙世界',
          rules: '天地法则，因果循环',
          factions: '正道联盟、魔道、散修',
          geography: '东洲、西荒、南疆、北冥',
          techLevel: '古代仙侠',
          aliases: ['仙界', '九天'],
          createdAt: now,
        );
        expect(copy, equals(baseSetting));
      });

      test('should not be equal when fields differ', () {
        final different = baseSetting.copyWith(name: 'Different');
        expect(different, isNot(equals(baseSetting)));
      });
    });

    group('field validation', () {
      test('should reject name exceeding 100 characters', () {
        expect(
          () => WorldSetting(
            id: 'id',
            name: 'a' * 101,
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });

      test('should accept name at exactly 100 characters', () {
        expect(
          () => WorldSetting(
            id: 'id',
            name: 'a' * 100,
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: now,
          ),
          returnsNormally,
        );
      });

      test('should reject name containing control characters', () {
        expect(
          () => WorldSetting(
            id: 'id',
            name: 'Valid\nName',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });

      test('should reject alias containing control characters', () {
        expect(
          () => WorldSetting(
            id: 'id',
            name: 'Valid',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            aliases: ['Bad\tAlias'],
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });

      test('should reject description exceeding 5000 characters', () {
        expect(
          () => WorldSetting(
            id: 'id',
            name: 'Valid',
            description: 'b' * 5001,
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });

      test('should reject aliases exceeding 20 items', () {
        expect(
          () => WorldSetting(
            id: 'id',
            name: 'Valid',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            aliases: List.generate(21, (i) => 'alias$i'),
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });

      test('should reject alias item exceeding 50 characters', () {
        expect(
          () => WorldSetting(
            id: 'id',
            name: 'Valid',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            aliases: ['a' * 51],
            createdAt: now,
          ),
          throwsArgumentError,
        );
      });
    });
  });
}

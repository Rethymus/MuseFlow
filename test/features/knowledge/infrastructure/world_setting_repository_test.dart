import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';

import '../../../../helpers/hive_test_helper.dart';

void main() {
  late Box<dynamic> box;
  late WorldSettingRepository repository;

  setUp(() async {
    await setUpHiveTest();
    box = await Hive.openBox<dynamic>('world_settings_test');
    repository = WorldSettingRepository(box);
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  group('WorldSettingRepository', () {
    final now = DateTime(2026, 1, 1);

    group('add', () {
      test('should add setting and return it with generated ID', () async {
        final setting = WorldSetting(
          id: '',
          name: '修仙界',
          description: '灵气为根基',
          rules: '天地法则',
          factions: '正道联盟',
          geography: '东洲',
          techLevel: '古代仙侠',
          createdAt: now,
        );

        final result = await repository.add(setting);

        expect(result.id, isNotEmpty);
        expect(result.name, equals('修仙界'));
        expect(result.createdAt, isNotNull);
      });

      test('should preserve existing ID if provided', () async {
        final setting = WorldSetting(
          id: 'custom-id',
          name: 'Test',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        );

        final result = await repository.add(setting);

        expect(result.id, equals('custom-id'));
      });

      test('should persist setting in box', () async {
        final setting = WorldSetting(
          id: '',
          name: 'Persistent',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        );

        final added = await repository.add(setting);
        final retrieved = repository.getById(added.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Persistent'));
      });
    });

    group('getAll', () {
      test('should return empty list when no settings', () {
        final result = repository.getAll();

        expect(result, isEmpty);
      });

      test('should return all added settings', () async {
        await repository.add(WorldSetting(
          id: '',
          name: 'Setting1',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        ));
        await repository.add(WorldSetting(
          id: '',
          name: 'Setting2',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        ));

        final result = repository.getAll();

        expect(result.length, equals(2));
        expect(result.map((s) => s.name), containsAll(['Setting1', 'Setting2']));
      });
    });

    group('getById', () {
      test('should return null for non-existent ID', () {
        final result = repository.getById('non-existent');

        expect(result, isNull);
      });

      test('should return setting by ID', () async {
        final added = await repository.add(WorldSetting(
          id: '',
          name: 'FindMe',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        ));

        final result = repository.getById(added.id);

        expect(result, isNotNull);
        expect(result!.name, equals('FindMe'));
      });
    });

    group('update', () {
      test('should update existing setting and set updatedAt', () async {
        final added = await repository.add(WorldSetting(
          id: '',
          name: 'Original',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        ));

        final updated = added.copyWith(name: 'Updated');
        await repository.update(updated);

        final result = repository.getById(added.id);
        expect(result!.name, equals('Updated'));
        expect(result.updatedAt, isNotNull);
      });
    });

    group('delete', () {
      test('should remove setting from box', () async {
        final added = await repository.add(WorldSetting(
          id: '',
          name: 'ToDelete',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        ));

        await repository.delete(added.id);

        final result = repository.getById(added.id);
        expect(result, isNull);
      });

      test('should not throw when deleting non-existent ID', () async {
        await repository.delete('non-existent');
      });
    });

    group('searchByName', () {
      test('should find settings by name substring', () async {
        await repository.add(WorldSetting(
          id: '',
          name: '修仙界',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        ));
        await repository.add(WorldSetting(
          id: '',
          name: '赛博朋克',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        ));

        final result = repository.searchByName('修仙');

        expect(result.length, equals(1));
        expect(result.first.name, equals('修仙界'));
      });

      test('should find settings by alias substring', () async {
        await repository.add(WorldSetting(
          id: '',
          name: '修仙界',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          aliases: ['仙界', '九天'],
          createdAt: now,
        ));

        final result = repository.searchByName('九天');

        expect(result.length, equals(1));
        expect(result.first.name, equals('修仙界'));
      });

      test('should return empty list when no match', () async {
        await repository.add(WorldSetting(
          id: '',
          name: '修仙界',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        ));

        final result = repository.searchByName('不存在');

        expect(result, isEmpty);
      });
    });
  });
}

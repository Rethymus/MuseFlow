import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = Directory.systemTemp.createTempSync('hive_notifier_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('WorldSettingNotifier', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    group('build', () {
      test('should load all settings from repository', () async {
        final box = await Hive.openBox<dynamic>('world_settings');
        final now = DateTime(2026, 1, 1);
        await box.put(
          '1',
          WorldSetting(
            id: '1',
            name: 'Setting1',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: now,
          ).toJson(),
        );
        await box.put(
          '2',
          WorldSetting(
            id: '2',
            name: 'Setting2',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: now,
          ).toJson(),
        );

        container = ProviderContainer();
        final notifier = container.read(worldSettingNotifierProvider.notifier);
        await notifier.future;

        final state = container.read(worldSettingNotifierProvider);
        expect(state.asData?.value, isNotNull);
        expect(state.asData!.value.length, equals(2));
        final names = state.asData!.value.map((s) => s.name).toList();
        expect(names, containsAll(['Setting1', 'Setting2']));
      });
    });

    group('add', () {
      test('should add setting and refresh state', () async {
        container = ProviderContainer();
        final notifier = container.read(worldSettingNotifierProvider.notifier);
        await notifier.future;

        final setting = WorldSetting(
          id: '',
          name: 'NewSetting',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: DateTime(2026, 1, 1),
        );

        await notifier.add(setting);
        await notifier.future;

        final state = container.read(worldSettingNotifierProvider);
        expect(state.asData?.value, isNotNull);
        expect(state.asData!.value.length, equals(1));
        expect(state.asData!.value.first.name, equals('NewSetting'));
      });
    });

    group('save', () {
      test('should update setting and refresh state', () async {
        final box = await Hive.openBox<dynamic>('world_settings');
        final now = DateTime(2026, 1, 1);
        final existing = WorldSetting(
          id: '1',
          name: 'Original',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: now,
        );
        await box.put('1', existing.toJson());

        container = ProviderContainer();
        final notifier = container.read(worldSettingNotifierProvider.notifier);
        await notifier.future;

        await notifier.save(existing.copyWith(name: 'Updated'));
        await notifier.future;

        final state = container.read(worldSettingNotifierProvider);
        expect(state.asData?.value, isNotNull);
        expect(state.asData!.value.first.name, equals('Updated'));
        expect(state.asData!.value.first.updatedAt, isNotNull);
      });
    });

    group('delete', () {
      test('should delete setting and refresh state', () async {
        final box = await Hive.openBox<dynamic>('world_settings');
        final now = DateTime(2026, 1, 1);
        await box.put(
          '1',
          WorldSetting(
            id: '1',
            name: 'ToDelete',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: now,
          ).toJson(),
        );

        container = ProviderContainer();
        final notifier = container.read(worldSettingNotifierProvider.notifier);
        await notifier.future;

        await notifier.delete('1');
        await notifier.future;

        final state = container.read(worldSettingNotifierProvider);
        expect(state.asData?.value, isNotNull);
        expect(state.asData!.value, isEmpty);
      });
    });

    group('searchByName', () {
      test('should filter current state by query', () async {
        final box = await Hive.openBox<dynamic>('world_settings');
        final now = DateTime(2026, 1, 1);
        await box.put(
          '1',
          WorldSetting(
            id: '1',
            name: '修仙界',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: now,
          ).toJson(),
        );
        await box.put(
          '2',
          WorldSetting(
            id: '2',
            name: '赛博朋克',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: now,
          ).toJson(),
        );

        container = ProviderContainer();
        final notifier = container.read(worldSettingNotifierProvider.notifier);
        await notifier.future;

        final results = notifier.searchByName('修仙');

        expect(results.length, equals(1));
        expect(results.first.name, equals('修仙界'));
      });
    });
  });
}

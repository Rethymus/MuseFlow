/// Tests for [creativityLevelProvider] / [CreativityLevelNotifier] (AA-03).
///
/// Validates that the provider reads the persisted creativity level from
/// [SettingsRepository] (defaulting to [CreativityLevel.balanced] when nothing
/// is persisted yet) and that [CreativityLevelNotifier.set] updates state and
/// persists the selection, so the choice survives a session restart.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/infrastructure/settings_repository.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/creativity_level.dart';

import '../../helpers/hive_test_helper.dart';

void main() {
  group('creativityLevelProvider AA-03', () {
    test('defaults to balanced when no preference is persisted', () async {
      await setUpHiveTest();
      addTearDown(tearDownHiveTest);

      final testBox = await Hive.openBox<dynamic>('test_settings');
      final settingsRepo = SettingsRepository(testBox);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            AsyncValue.data(settingsRepo),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(creativityLevelProvider), CreativityLevel.balanced);
    });

    test('reads a previously persisted level', () async {
      await setUpHiveTest();
      addTearDown(tearDownHiveTest);

      final testBox = await Hive.openBox<dynamic>('test_settings');
      final settingsRepo = SettingsRepository(testBox);
      // Pre-seed the persisted value as if a prior session saved "expressive".
      await settingsRepo.saveCreativityLevel(CreativityLevel.expressive);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            AsyncValue.data(settingsRepo),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(creativityLevelProvider), CreativityLevel.expressive);
    });

    test('set() updates state immediately and persists for the next session',
        () async {
      await setUpHiveTest();
      addTearDown(tearDownHiveTest);

      final testBox = await Hive.openBox<dynamic>('test_settings');
      final settingsRepo = SettingsRepository(testBox);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            AsyncValue.data(settingsRepo),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(creativityLevelProvider.notifier).set(
            CreativityLevel.conservative,
          );

      // State updated in-memory.
      expect(container.read(creativityLevelProvider), CreativityLevel.conservative);
      // Persisted: a fresh repository over the same box reads it back.
      final freshRepo = SettingsRepository(testBox);
      expect(freshRepo.getCreativityLevel(), CreativityLevel.conservative);
    });
  });
}

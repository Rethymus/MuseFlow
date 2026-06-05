import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/infrastructure/settings_repository.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/onboarding/domain/onboarding_progress.dart';
import 'package:museflow/features/onboarding/infrastructure/onboarding_progress_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  setUp(() async {
    await setUpHiveTest();
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  group('onboardingProgressProvider registration', () {
    test(
        'should create OnboardingProgressRepository when settingsRepositoryProvider resolves',
        () async {
      // Arrange: set up a ProviderContainer with a real Hive box
      // overriding settingsRepositoryProvider to use a test box.
      final testBox = await Hive.openBox<dynamic>('test_settings');
      final settingsRepo = SettingsRepository(testBox);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider
              .overrideWithValue(AsyncValue.data(settingsRepo)),
        ],
      );

      // Act: resolve the onboardingProgressProvider
      final onboardingRepo =
          await container.read(onboardingProgressProvider.future);

      // Assert: provider returns a working OnboardingProgressRepository
      expect(onboardingRepo, isA<OnboardingProgressRepository>());

      // Verify the repository is functional by exercising its methods
      expect(onboardingRepo.isCompleted(), isFalse);
      expect(onboardingRepo.getProgress(), equals(OnboardingProgress.initial()));

      await onboardingRepo.saveProgress(
        const OnboardingProgress(currentStep: 2, completedSteps: [0, 1]),
      );
      final progress = onboardingRepo.getProgress();
      expect(progress.currentStep, 2);
      expect(progress.completedSteps, [0, 1]);

      await onboardingRepo.markCompleted();
      expect(onboardingRepo.isCompleted(), isTrue);

      container.dispose();
    });

    test('should depend on settingsRepositoryProvider for box access',
        () async {
      // Arrange: use a test box with pre-existing data
      final testBox = await Hive.openBox<dynamic>('test_settings_dep');
      await testBox.put('onboarding_completed', true);
      final settingsRepo = SettingsRepository(testBox);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider
              .overrideWithValue(AsyncValue.data(settingsRepo)),
        ],
      );

      // Act: resolve the provider — it should use the same box
      final onboardingRepo =
          await container.read(onboardingProgressProvider.future);

      // Assert: the repository sees the data already in the settings box
      expect(onboardingRepo.isCompleted(), isTrue);

      container.dispose();
    });

    test(
        'should produce repository with working saveProgress getProgress markCompleted isCompleted',
        () async {
      // This test verifies the full contract: all four repository methods
      // work correctly when the repository is obtained through the provider.
      final testBox = await Hive.openBox<dynamic>('test_settings_methods');
      final settingsRepo = SettingsRepository(testBox);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider
              .overrideWithValue(AsyncValue.data(settingsRepo)),
        ],
      );

      final repo = await container.read(onboardingProgressProvider.future);

      // 1. saveProgress + getProgress roundtrip
      final progress = OnboardingProgress(
        currentStep: 3,
        completedSteps: [0, 1, 2],
        selectedTemplateId: 'scifi',
        worldName: 'Nexus Prime',
        characterName: 'Kira',
      );
      await repo.saveProgress(progress);
      final restored = repo.getProgress();
      expect(restored.currentStep, 3);
      expect(restored.completedSteps, [0, 1, 2]);
      expect(restored.selectedTemplateId, 'scifi');
      expect(restored.worldName, 'Nexus Prime');
      expect(restored.characterName, 'Kira');

      // 2. isCompleted returns false before markCompleted
      expect(repo.isCompleted(), isFalse);

      // 3. markCompleted sets the flag
      await repo.markCompleted();
      expect(repo.isCompleted(), isTrue);

      // 4. Progress data persists independently of completion flag
      final afterComplete = repo.getProgress();
      expect(afterComplete.currentStep, 3);

      container.dispose();
    });
  });
}

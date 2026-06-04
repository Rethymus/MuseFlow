import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/onboarding/domain/onboarding_progress.dart';
import 'package:museflow/features/onboarding/infrastructure/onboarding_progress_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late OnboardingProgressRepository repository;
  late Box<dynamic> box;

  setUp(() async {
    await setUpHiveTest();
    box = await Hive.openBox<dynamic>('test_settings');
    repository = OnboardingProgressRepository(box);
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  group('OnboardingProgress', () {
    test('should return initial state with default values', () {
      final progress = OnboardingProgress.initial();

      expect(progress.currentStep, 0);
      expect(progress.completedSteps, isEmpty);
      expect(progress.selectedTemplateId, isNull);
      expect(progress.worldName, isNull);
      expect(progress.characterName, isNull);
    });

    test('should create modified copy with copyWith', () {
      final initial = OnboardingProgress.initial();
      final modified = initial.copyWith(
        currentStep: 2,
        completedSteps: [0, 1],
        selectedTemplateId: 'fantasy',
        worldName: 'Aethermoor',
      );

      expect(modified.currentStep, 2);
      expect(modified.completedSteps, [0, 1]);
      expect(modified.selectedTemplateId, 'fantasy');
      expect(modified.worldName, 'Aethermoor');
      // Original unchanged (immutability)
      expect(initial.currentStep, 0);
      expect(initial.selectedTemplateId, isNull);
    });

    test('should serialize and deserialize via toJson/fromJson', () {
      final progress = OnboardingProgress(
        currentStep: 3,
        completedSteps: [0, 1, 2],
        selectedTemplateId: 'scifi',
        worldName: 'Nexus Prime',
        characterName: 'Kira',
      );

      final json = progress.toJson();
      final restored = OnboardingProgress.fromJson(json);

      expect(restored.currentStep, 3);
      expect(restored.completedSteps, [0, 1, 2]);
      expect(restored.selectedTemplateId, 'scifi');
      expect(restored.worldName, 'Nexus Prime');
      expect(restored.characterName, 'Kira');
    });

    test('should handle malformed JSON gracefully (T-08-02)', () {
      final malformed = <String, dynamic>{
        'currentStep': 'not_an_int',
        'completedSteps': 'not_a_list',
      };

      final result = OnboardingProgress.fromJson(malformed);

      // Should fall back to initial state, not throw
      expect(result.currentStep, 0);
      expect(result.completedSteps, isEmpty);
    });

    test('should handle null fields in JSON', () {
      final json = <String, dynamic>{
        'currentStep': 1,
      };

      final result = OnboardingProgress.fromJson(json);

      expect(result.currentStep, 1);
      expect(result.completedSteps, isEmpty);
      expect(result.selectedTemplateId, isNull);
      expect(result.worldName, isNull);
      expect(result.characterName, isNull);
    });

    test('should report step completion status', () {
      final progress = OnboardingProgress(completedSteps: [0, 2]);

      expect(progress.isStepCompleted(0), isTrue);
      expect(progress.isStepCompleted(1), isFalse);
      expect(progress.isStepCompleted(2), isTrue);
    });

    test('should report optional field presence', () {
      final empty = OnboardingProgress.initial();
      expect(empty.hasSelectedTemplate, isFalse);
      expect(empty.hasWorldName, isFalse);
      expect(empty.hasCharacterName, isFalse);

      final filled = OnboardingProgress(
        selectedTemplateId: 'fantasy',
        worldName: 'Realm',
        characterName: 'Hero',
      );
      expect(filled.hasSelectedTemplate, isTrue);
      expect(filled.hasWorldName, isTrue);
      expect(filled.hasCharacterName, isTrue);
    });

    test('should treat empty string as no world/character name', () {
      final progress = OnboardingProgress(
        worldName: '',
        characterName: '',
      );
      expect(progress.hasWorldName, isFalse);
      expect(progress.hasCharacterName, isFalse);
    });
  });

  group('OnboardingProgressRepository', () {
    test('should return initial progress when no data saved', () {
      final progress = repository.getProgress();

      expect(progress.currentStep, 0);
      expect(progress.completedSteps, isEmpty);
    });

    test('should save and retrieve progress roundtrip', () async {
      final progress = OnboardingProgress(
        currentStep: 2,
        completedSteps: [0, 1],
        selectedTemplateId: 'fantasy',
      );

      await repository.saveProgress(progress);
      final restored = repository.getProgress();

      expect(restored.currentStep, 2);
      expect(restored.completedSteps, [0, 1]);
      expect(restored.selectedTemplateId, 'fantasy');
    });

    test('should overwrite previous progress on save', () async {
      await repository.saveProgress(
        const OnboardingProgress(currentStep: 1),
      );
      await repository.saveProgress(
        const OnboardingProgress(currentStep: 3, completedSteps: [0, 1, 2]),
      );

      final restored = repository.getProgress();
      expect(restored.currentStep, 3);
      expect(restored.completedSteps, [0, 1, 2]);
    });

    test('should mark onboarding as completed', () async {
      expect(repository.isCompleted(), isFalse);

      await repository.markCompleted();

      expect(repository.isCompleted(), isTrue);
    });

    test('should return false for isCompleted on fresh box', () {
      expect(repository.isCompleted(), isFalse);
    });

    test('should return initial progress when box has non-Map data (T-08-03)',
        () async {
      await box.put('onboarding_progress', 'not_a_map');

      final progress = repository.getProgress();

      expect(progress.currentStep, 0);
      expect(progress.completedSteps, isEmpty);
    });

    test('should persist completion flag independently of progress', () async {
      await repository.saveProgress(
        const OnboardingProgress(currentStep: 4),
      );
      await repository.markCompleted();

      // Both should be readable independently
      expect(repository.isCompleted(), isTrue);
      expect(repository.getProgress().currentStep, 4);
    });
  });
}

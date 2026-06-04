import 'package:hive_ce/hive.dart';
import 'package:museflow/features/onboarding/domain/onboarding_progress.dart';

/// Repository for persisting onboarding wizard progress in the Hive settings box.
///
/// Manages two keys in the shared settings box:
/// - `onboarding_progress`: serialized [OnboardingProgress] JSON
/// - `onboarding_completed`: boolean flag set when wizard finishes
///
/// Per T-08-03: [getProgress] returns [OnboardingProgress.initial] if the
/// stored value is null or invalid, preventing null crashes in the redirect.
class OnboardingProgressRepository {
  final Box<dynamic> _box;

  static const String _progressKey = 'onboarding_progress';
  static const String _completedKey = 'onboarding_completed';

  OnboardingProgressRepository(this._box);

  /// Saves the current onboarding progress to the settings box.
  Future<void> saveProgress(OnboardingProgress progress) async {
    await _box.put(_progressKey, progress.toJson());
  }

  /// Reads the current onboarding progress from the settings box.
  ///
  /// Returns [OnboardingProgress.initial] if no progress has been saved
  /// or if the stored data is malformed (T-08-03 mitigation).
  OnboardingProgress getProgress() {
    final data = _box.get(_progressKey);
    if (data == null) return OnboardingProgress.initial();
    if (data is! Map<String, dynamic>) return OnboardingProgress.initial();
    return OnboardingProgress.fromJson(data);
  }

  /// Marks the onboarding wizard as completed.
  ///
  /// Once called, the redirect guard will no longer route to /onboarding.
  Future<void> markCompleted() async {
    await _box.put(_completedKey, true);
  }

  /// Whether the onboarding wizard has been completed.
  ///
  /// Returns false if the key has not been set (fresh install).
  bool isCompleted() {
    return _box.get(_completedKey, defaultValue: false) as bool;
  }
}

/// Immutable value object tracking onboarding wizard progress.
///
/// Persists the user's current step, completed steps, and optional
/// selections made during the onboarding wizard. Stored in the Hive
/// settings box via [OnboardingProgressRepository].
///
/// Use [copyWith] to create modified copies. Use [initial] for a fresh
/// default state.
class OnboardingProgress {
  /// The wizard step the user is currently on (0-based index).
  final int currentStep;

  /// Steps the user has already completed.
  final List<int> completedSteps;

  /// Template selected during onboarding (null until selected).
  final String? selectedTemplateId;

  /// World name entered during onboarding (null until entered).
  final String? worldName;

  /// Character name entered during onboarding (null until entered).
  final String? characterName;

  const OnboardingProgress({
    this.currentStep = 0,
    this.completedSteps = const [],
    this.selectedTemplateId,
    this.worldName,
    this.characterName,
  });

  /// Default initial state for a fresh install.
  factory OnboardingProgress.initial() => const OnboardingProgress();

  /// Whether the user has completed a specific step.
  bool isStepCompleted(int step) => completedSteps.contains(step);

  /// Whether a template has been selected.
  bool get hasSelectedTemplate => selectedTemplateId != null;

  /// Whether a world name has been entered.
  bool get hasWorldName => worldName != null && worldName!.isNotEmpty;

  /// Whether a character name has been entered.
  bool get hasCharacterName =>
      characterName != null && characterName!.isNotEmpty;

  OnboardingProgress copyWith({
    int? currentStep,
    List<int>? completedSteps,
    String? selectedTemplateId,
    String? worldName,
    String? characterName,
  }) {
    return OnboardingProgress(
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      worldName: worldName ?? this.worldName,
      characterName: characterName ?? this.characterName,
    );
  }

  /// Deserialize from JSON map stored in Hive.
  ///
  /// Per T-08-02: Returns [OnboardingProgress.initial] if JSON parsing fails,
  /// preventing malformed data from crashing the redirect callback.
  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    try {
      return OnboardingProgress(
        currentStep: json['currentStep'] as int? ?? 0,
        completedSteps:
            (json['completedSteps'] as List<dynamic>?)?.cast<int>() ?? const [],
        selectedTemplateId: json['selectedTemplateId'] as String?,
        worldName: json['worldName'] as String?,
        characterName: json['characterName'] as String?,
      );
    } catch (_) {
      // T-08-02 mitigation: default to initial state on parse error
      return OnboardingProgress.initial();
    }
  }

  /// Serialize to JSON map for Hive persistence.
  Map<String, dynamic> toJson() {
    return {
      'currentStep': currentStep,
      'completedSteps': completedSteps,
      if (selectedTemplateId != null) 'selectedTemplateId': selectedTemplateId,
      if (worldName != null) 'worldName': worldName,
      if (characterName != null) 'characterName': characterName,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingProgress &&
        other.currentStep == currentStep &&
        _listEquals(other.completedSteps, completedSteps) &&
        other.selectedTemplateId == selectedTemplateId &&
        other.worldName == worldName &&
        other.characterName == characterName;
  }

  @override
  int get hashCode => Object.hash(
    currentStep,
    Object.hashAll(completedSteps),
    selectedTemplateId,
    worldName,
    characterName,
  );

  @override
  String toString() =>
      'OnboardingProgress(currentStep: $currentStep, '
      'completedSteps: $completedSteps, '
      'selectedTemplateId: $selectedTemplateId, '
      'worldName: $worldName, characterName: $characterName)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

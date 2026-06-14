/// User-facing creativity dimension (AA-03).
///
/// Promotes the sampling temperature — previously buried in per-provider
/// configuration — into a user-selectable three-level "creativity" concept.
/// Per TempParaphraser (Huang et al., EMNLP 2025): higher sampling temperature
/// raises output diversity and reduces AI-text detection rate by up to 82.5%.
///
/// The three levels map to concrete temperature values chosen to stay within
/// the coherent-sampling band (≤ 1.0) while bracketing the AI-default 0.7:
///   - [conservative] 0.6 — tighter, more predictable prose.
///   - [balanced]    0.8 — the default; more diverse than the AI sweet spot.
///   - [expressive]  0.95 — maximal diversity, lowest machine-scent footprint.
///
/// When a [CreativityLevel] is attached to a [PromptContext], the generation
/// call sites use [temperature] to override the provider-configured default,
/// honoring the user's explicit creative intent.
library;

/// Three-level creativity mapping to sampling temperature.
enum CreativityLevel {
  /// Tighter, more predictable prose.
  conservative('保守', 0.6),

  /// The default — more diverse than the AI-default 0.7 sweet spot.
  balanced('平衡', 0.8),

  /// Maximal diversity; lowest machine-scent footprint.
  expressive('灵动', 0.95);

  const CreativityLevel(this.label, this.temperature);

  /// Chinese display label for the settings UI.
  final String label;

  /// Sampling temperature this level maps to (within coherent band ≤ 1.0).
  final double temperature;

  /// Deserialize from a persisted string name.
  ///
  /// Unknown / null values fall back to [balanced] so a corrupt or future
  /// persisted value never crashes deserialization.
  static CreativityLevel fromJson(String? value) {
    switch (value) {
      case 'conservative':
        return CreativityLevel.conservative;
      case 'expressive':
        return CreativityLevel.expressive;
      case 'balanced':
      default:
        return CreativityLevel.balanced;
    }
  }

  /// Serialize to a persisted string name.
  String toJson() => name;
}

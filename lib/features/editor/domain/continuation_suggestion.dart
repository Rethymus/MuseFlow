/// Guided continuation suggestion for plot direction selection.
///
/// Per LFIN-03: System offers 3 directional plot continuation suggestions
/// based on current story context; user selects a direction before AI
/// generates expanded content.
library;

/// A single plot continuation direction suggested by the AI.
///
/// Immutable value object representing one possible narrative direction.
class ContinuationSuggestion {
  /// Short label for this direction (e.g., "冲突升级", "人物深入").
  final String direction;

  /// One-paragraph description of what this direction would explore.
  final String summary;

  /// Key plot points this direction would develop (2-3 bullet points).
  final String keyPoints;

  const ContinuationSuggestion({
    required this.direction,
    required this.summary,
    required this.keyPoints,
  });

  @override
  bool operator ==(Object other) =>
      other is ContinuationSuggestion &&
      other.direction == direction &&
      other.summary == summary &&
      other.keyPoints == keyPoints;

  @override
  int get hashCode => Object.hash(direction, summary, keyPoints);

  @override
  String toString() =>
      'ContinuationSuggestion(direction: $direction, summary: $summary)';
}

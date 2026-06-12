/// A high-quality paragraph extracted from the author's writing.
///
/// Used by [FewShotMiddleware] to inject author style examples into AI
/// prompts. Each sample is scored by quality and tagged with per-dimension
/// metrics for ranking.
library;

import 'style_dimension.dart';

/// A scored paragraph sample from the author's existing chapters.
class StyleSample {
  /// The chapter ID where this paragraph was found.
  final String chapterId;

  /// Zero-based index of the paragraph within the chapter.
  final int paragraphIndex;

  /// The actual paragraph text.
  final String text;

  /// Overall quality score (higher is better).
  final double qualityScore;

  /// Per-dimension scores for this sample (0.0–1.0 each).
  final Map<StyleDimension, double> dimensionScores;

  const StyleSample({
    required this.chapterId,
    required this.paragraphIndex,
    required this.text,
    required this.qualityScore,
    this.dimensionScores = const {},
  });

  StyleSample copyWith({
    String? chapterId,
    int? paragraphIndex,
    String? text,
    double? qualityScore,
    Map<StyleDimension, double>? dimensionScores,
  }) {
    return StyleSample(
      chapterId: chapterId ?? this.chapterId,
      paragraphIndex: paragraphIndex ?? this.paragraphIndex,
      text: text ?? this.text,
      qualityScore: qualityScore ?? this.qualityScore,
      dimensionScores: dimensionScores ?? this.dimensionScores,
    );
  }

  factory StyleSample.fromJson(Map<String, dynamic> json) {
    final dimScores = <StyleDimension, double>{};
    final rawDims = json['dimensionScores'] as Map<String, dynamic>?;
    if (rawDims != null) {
      for (final entry in rawDims.entries) {
        final dim = StyleDimension.values.firstWhere(
          (d) => d.name == entry.key,
          orElse: () => StyleDimension.sentenceLength,
        );
        dimScores[dim] = (entry.value as num).toDouble();
      }
    }
    return StyleSample(
      chapterId: json['chapterId'] as String,
      paragraphIndex: json['paragraphIndex'] as int,
      text: json['text'] as String,
      qualityScore: (json['qualityScore'] as num).toDouble(),
      dimensionScores: dimScores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'paragraphIndex': paragraphIndex,
      'text': text,
      'qualityScore': qualityScore,
      'dimensionScores': dimensionScores.map(
        (key, value) => MapEntry(key.name, value),
      ),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is StyleSample &&
        other.chapterId == chapterId &&
        other.paragraphIndex == paragraphIndex &&
        other.text == text &&
        other.qualityScore == qualityScore;
  }

  @override
  int get hashCode => Object.hash(chapterId, paragraphIndex, text);
}

/// Style dimension enum for author style analysis.
///
/// Each dimension represents a measurable aspect of writing style.
/// Used in [AuthorStyleProfile] and UI display.
library;

/// A measurable dimension of author writing style.
enum StyleDimension {
  /// Sentence length distribution (avg, std dev, short/long ratios).
  sentenceLength('句式特征'),

  /// Rhythm and burstiness (sentence length variation).
  rhythm('节奏模式'),

  /// Vocabulary richness (unique CJK characters ratio).
  vocabulary('词汇特征'),

  /// Rhetoric habits (dialogue, description, action, metaphor ratios).
  rhetoric('修辞习惯'),

  /// Emotional tone (warmth, intensity).
  emotionalTone('情感基调');

  /// Chinese display label for this dimension.
  final String label;

  const StyleDimension(this.label);

  /// Returns a human-readable interpretation of a score for this dimension.
  ///
  /// [score] is normalized 0.0–1.0.
  String interpret(double score) {
    return switch (this) {
      StyleDimension.sentenceLength => _interpretSentenceLength(score),
      StyleDimension.rhythm => _interpretRhythm(score),
      StyleDimension.vocabulary => _interpretVocabulary(score),
      StyleDimension.rhetoric => _interpretRhetoric(score),
      StyleDimension.emotionalTone => _interpretTone(score),
    };
  }

  String _interpretSentenceLength(double score) {
    if (score < 0.3) return '偏好长句，文风厚重';
    if (score < 0.5) return '长短句交替，节奏自然';
    if (score < 0.7) return '句式适中，表达平衡';
    return '偏好短句，节奏明快';
  }

  String _interpretRhythm(double score) {
    if (score < 0.3) return '节奏变化丰富，极具个性';
    if (score < 0.5) return '句式长短错落，富有韵律';
    if (score < 0.7) return '节奏较为均匀，偶有变化';
    return '节奏过于整齐，偏向AI化';
  }

  String _interpretVocabulary(double score) {
    if (score < 0.2) return '词汇重复率高，变化少';
    if (score < 0.4) return '词汇朴实，用词精练';
    if (score < 0.6) return '词汇较为丰富，表达多样';
    return '词汇极其丰富，表达华丽';
  }

  String _interpretRhetoric(double score) {
    if (score < 0.3) return '描写手法单一，偏重叙述';
    if (score < 0.5) return '修辞适中，叙述为主';
    if (score < 0.7) return '修辞多样，描写细腻';
    return '修辞丰富，文学性强';
  }

  String _interpretTone(double score) {
    if (score < 0.3) return '情感克制，冷静客观';
    if (score < 0.5) return '情感温和，节奏平稳';
    if (score < 0.7) return '情感充沛，有感染力';
    return '情感浓烈，张力十足';
  }
}

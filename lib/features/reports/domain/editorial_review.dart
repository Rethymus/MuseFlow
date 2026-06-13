/// Editorial review domain model — CritiCS (EMNLP 2024) inspired 4-dimension
/// multi-perspective review.
///
/// Dimensions: 情节(plot) / 人物(character) / 文笔(prose) / 节奏(pacing).
/// Reviews are advisory only — they never rewrite prose (磨刀石 not 打字机).
library;

import 'dart:convert';

/// A single editorial review dimension.
enum ReviewDimension {
  plot('情节'),
  character('人物'),
  prose('文笔'),
  pacing('节奏');

  const ReviewDimension(this.label);

  /// Chinese display label.
  final String label;

  /// Matches a dimension by Chinese label or English enum name
  /// (case-insensitive). Returns null for unknown names.
  static ReviewDimension? fromName(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    for (final d in ReviewDimension.values) {
      if (d.name.toLowerCase() == trimmed.toLowerCase() ||
          d.label == trimmed) {
        return d;
      }
    }
    return null;
  }
}

/// One dimension's advisory critique.
class DimensionReview {
  final ReviewDimension dimension;
  final int score; // 0-100
  final String strengths;
  final String weaknesses;
  final String suggestions;

  const DimensionReview({
    required this.dimension,
    required this.score,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
  });

  DimensionReview copyWith({
    ReviewDimension? dimension,
    int? score,
    String? strengths,
    String? weaknesses,
    String? suggestions,
  }) {
    return DimensionReview(
      dimension: dimension ?? this.dimension,
      score: score ?? this.score,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  factory DimensionReview.fromJson(Map<String, dynamic> json) {
    final dim = ReviewDimension.fromName(json['dimension']?.toString());
    // Unknown dimension -> caller filters out (returns via tryParse null).
    if (dim == null) {
      throw FormatException('unknown dimension: ${json['dimension']}');
    }
    final rawScore = json['score'];
    final score = (rawScore is num ? rawScore.toInt() : 0).clamp(0, 100);
    return DimensionReview(
      dimension: dim,
      score: score,
      strengths: json['strengths']?.toString() ?? '',
      weaknesses: json['weaknesses']?.toString() ?? '',
      suggestions: json['suggestions']?.toString() ?? '',
    );
  }

  /// Tolerant parser — returns null for items with unknown dimensions
  /// instead of throwing, so partial arrays degrade gracefully.
  static DimensionReview? tryFromJson(Map<String, dynamic> json) {
    try {
      return DimensionReview.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DimensionReview &&
          other.dimension == dimension &&
          other.score == score &&
          other.strengths == strengths &&
          other.weaknesses == weaknesses &&
          other.suggestions == suggestions;

  @override
  int get hashCode => Object.hash(
    dimension,
    score,
    strengths,
    weaknesses,
    suggestions,
  );
}

/// Aggregate editorial review across all dimensions.
class EditorialReview {
  /// Per-dimension critiques (may be fewer than 4 if the LLM output was
  /// partial; empty when degraded).
  final List<DimensionReview> dimensions;

  /// Non-null when parsing failed — the review is unusable and the UI should
  /// surface [degradedReason] to the author.
  final String? degradedReason;

  const EditorialReview({required this.dimensions, this.degradedReason});

  /// Mean dimension score, rounded (0 when no dimensions).
  int get overallScore {
    if (dimensions.isEmpty) return 0;
    final sum = dimensions.fold<int>(0, (a, d) => a + d.score);
    return (sum / dimensions.length).round();
  }

  bool get isDegraded => degradedReason != null;

  factory EditorialReview.fromJson(Map<String, dynamic> json) {
    final dims = <DimensionReview>[];
    final raw = json['dimensions'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final parsed = DimensionReview.tryFromJson(
            Map<String, dynamic>.from(item),
          );
          if (parsed != null) dims.add(parsed);
        }
      }
    }
    return EditorialReview(dimensions: dims);
  }

  /// A degraded review indicating parsing/extraction failed.
  factory EditorialReview.degraded(String reason) =>
      EditorialReview(dimensions: const [], degradedReason: reason);

  /// Tolerant parser for raw LLM output. Strips ```json fences, isolates the
  /// first JSON object, and degrades gracefully on any failure.
  static EditorialReview parseFromLLM(String raw) {
    try {
      final stripped = raw.trim().replaceAll('```json', '').replaceAll(
        '```',
        '',
      );
      final start = stripped.indexOf('{');
      final end = stripped.lastIndexOf('}');
      if (start < 0 || end <= start) {
        return EditorialReview.degraded('未找到有效的 JSON 评审内容');
      }
      final jsonStr = stripped.substring(start, end + 1);
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        return EditorialReview.degraded('评审 JSON 结构不符合预期');
      }
      final review = EditorialReview.fromJson(decoded);
      if (review.dimensions.isEmpty) {
        return EditorialReview.degraded('未能解析出任何评审维度');
      }
      return review;
    } catch (e) {
      return EditorialReview.degraded('解析评审失败：$e');
    }
  }
}

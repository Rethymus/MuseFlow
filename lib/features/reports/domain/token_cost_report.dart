import 'package:museflow/features/stats/domain/audit_operation_type.dart';

/// Projection of token costs extrapolated to a target word count (50万字).
///
/// Uses multiplier-based estimation with low/high variance bounds.
class TokenCostProjection {
  const TokenCostProjection({
    required this.targetWordCount,
    required this.multiplier,
    required this.estimatedInputTokens,
    required this.estimatedOutputTokens,
    required this.estimatedCalls,
    required this.lowEstimateMultiplier,
    required this.highEstimateMultiplier,
  });

  /// Target word count for extrapolation (default: 500000.0 = 50万字).
  final double targetWordCount;

  /// Multiplier = targetWordCount / actualWordCount.
  final double multiplier;

  /// Estimated total input tokens at target word count.
  final int estimatedInputTokens;

  /// Estimated total output tokens at target word count.
  final int estimatedOutputTokens;

  /// Estimated total API calls at target word count.
  final int estimatedCalls;

  /// Lower bound multiplier for variance-adjusted estimation.
  final double lowEstimateMultiplier;

  /// Upper bound multiplier for variance-adjusted estimation.
  final double highEstimateMultiplier;

  TokenCostProjection copyWith({
    double? targetWordCount,
    double? multiplier,
    int? estimatedInputTokens,
    int? estimatedOutputTokens,
    int? estimatedCalls,
    double? lowEstimateMultiplier,
    double? highEstimateMultiplier,
  }) {
    return TokenCostProjection(
      targetWordCount: targetWordCount ?? this.targetWordCount,
      multiplier: multiplier ?? this.multiplier,
      estimatedInputTokens: estimatedInputTokens ?? this.estimatedInputTokens,
      estimatedOutputTokens:
          estimatedOutputTokens ?? this.estimatedOutputTokens,
      estimatedCalls: estimatedCalls ?? this.estimatedCalls,
      lowEstimateMultiplier:
          lowEstimateMultiplier ?? this.lowEstimateMultiplier,
      highEstimateMultiplier:
          highEstimateMultiplier ?? this.highEstimateMultiplier,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenCostProjection &&
          runtimeType == other.runtimeType &&
          targetWordCount == other.targetWordCount &&
          multiplier == other.multiplier &&
          estimatedInputTokens == other.estimatedInputTokens &&
          estimatedOutputTokens == other.estimatedOutputTokens &&
          estimatedCalls == other.estimatedCalls &&
          lowEstimateMultiplier == other.lowEstimateMultiplier &&
          highEstimateMultiplier == other.highEstimateMultiplier;

  @override
  int get hashCode =>
      targetWordCount.hashCode ^
      multiplier.hashCode ^
      estimatedInputTokens.hashCode ^
      estimatedOutputTokens.hashCode ^
      estimatedCalls.hashCode ^
      lowEstimateMultiplier.hashCode ^
      highEstimateMultiplier.hashCode;
}

/// Aggregated token cost report for a manuscript.
///
/// Holds actual consumption data, per-type and per-chapter breakdowns,
/// a projection for a 50万字 target, and optimization suggestions.
class TokenCostReport {
  const TokenCostReport({
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCalls,
    required this.actualWordCount,
    required this.costByType,
    required this.costByChapter,
    required this.projection,
    required this.optimizationSuggestions,
  });

  /// Total input tokens consumed across all AI operations.
  final int totalInputTokens;

  /// Total output tokens consumed across all AI operations.
  final int totalOutputTokens;

  /// Total number of AI API calls.
  final int totalCalls;

  /// Actual word count of the manuscript (e.g. ~1万字).
  final double actualWordCount;

  /// Token cost broken down by operation type.
  final Map<AuditOperationType, int> costByType;

  /// Token cost broken down by chapter ID.
  final Map<String, int> costByChapter;

  /// Extrapolation projection to target word count.
  final TokenCostProjection projection;

  /// Template-based optimization suggestions.
  final List<String> optimizationSuggestions;

  TokenCostReport copyWith({
    int? totalInputTokens,
    int? totalOutputTokens,
    int? totalCalls,
    double? actualWordCount,
    Map<AuditOperationType, int>? costByType,
    Map<String, int>? costByChapter,
    TokenCostProjection? projection,
    List<String>? optimizationSuggestions,
  }) {
    return TokenCostReport(
      totalInputTokens: totalInputTokens ?? this.totalInputTokens,
      totalOutputTokens: totalOutputTokens ?? this.totalOutputTokens,
      totalCalls: totalCalls ?? this.totalCalls,
      actualWordCount: actualWordCount ?? this.actualWordCount,
      costByType: costByType ?? this.costByType,
      costByChapter: costByChapter ?? this.costByChapter,
      projection: projection ?? this.projection,
      optimizationSuggestions:
          optimizationSuggestions ?? this.optimizationSuggestions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenCostReport &&
          runtimeType == other.runtimeType &&
          totalInputTokens == other.totalInputTokens &&
          totalOutputTokens == other.totalOutputTokens &&
          totalCalls == other.totalCalls &&
          actualWordCount == other.actualWordCount &&
          _mapEquals(costByType, other.costByType) &&
          _mapEquals(costByChapter, other.costByChapter) &&
          projection == other.projection &&
          _listEquals(optimizationSuggestions, other.optimizationSuggestions);

  @override
  int get hashCode =>
      totalInputTokens.hashCode ^
      totalOutputTokens.hashCode ^
      totalCalls.hashCode ^
      actualWordCount.hashCode ^
      projection.hashCode;

  /// Deep equality for maps.
  static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  /// Deep equality for lists.
  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

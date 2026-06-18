import 'package:museflow/features/manuscript/domain/chapter_summary.dart';

/// Staleness checker for stored [ChapterSummary] entries (MC-02 slice 2).
///
/// Symmetric to [KbStalenessChecker] (MC-01): as the author keeps writing a
/// chapter after its summary was generated, the stored summary falls behind
/// the source text. This checker decides whether a stored summary is still
/// fresh enough to inject as adjacent-chapter context, or whether the builder
/// should fall back to truncating the live chapter text.
///
/// A summary is [isStale] when the chapter grew **both** by an absolute
/// amount (≥ [staleAbsoluteGrowth] chars) **and** a relative amount (≥
/// [staleRelativeRatio] of the source). The AND guards against false
/// positives on both ends: a 2000-char chapter nudged by 60 chars (3%) stays
/// fresh, while a 100-char stub grown by 60 chars (60%) is flagged.
class ChapterSummaryStalenessChecker {
  const ChapterSummaryStalenessChecker();

  /// Absolute growth (non-whitespace chars) at/above which a summary may be
  /// considered stale. Must co-occur with the relative threshold.
  static const int staleAbsoluteGrowth = 50;

  /// Relative growth fraction of [ChapterSummary.sourceWordCount] at/above
  /// which a summary may be considered stale. Must co-occur with the absolute
  /// threshold.
  static const double staleRelativeRatio = 0.2;

  /// Whether [summary] is stale relative to the chapter's current non-blank
  /// char count [currentWordCount].
  ///
  /// Returns false when the chapter hasn't grown since summarization
  /// ([currentWordCount] ≤ [ChapterSummary.sourceWordCount]).
  bool isStale(ChapterSummary summary, int currentWordCount) {
    if (currentWordCount <= summary.sourceWordCount) return false;
    final growth = currentWordCount - summary.sourceWordCount;
    return growth >= staleAbsoluteGrowth &&
        growth >= summary.sourceWordCount * staleRelativeRatio;
  }
}

/// Shared style analysis utilities — the single ruler for CJK extraction,
/// sentence-length extraction, rhythm scoring, and vocabulary richness.
///
/// Both [StyleAnalyzer] (author-profile baseline builder) and
/// [StyleDeviationDetector] (AI-text measurement side) MUST delegate to
/// these static methods. Keeping a single authoritative implementation
/// structurally eliminates the dual-ruler drift class that produced five
/// prior bugs (260617-05c/1uk/f7l/hnl/j0z): single-sided edits to byte-
/// identical duplicate logic warped the AI-scent deviation scores
/// (反AI味核心信号).
///
/// Source of truth: every method here is a verbatim lift of the analyzer's
/// pre-refactor private implementation (the profile-builder is the
/// authority). Both consumers now call the SAME function.
library;

import 'dart:math';

/// Pure-Dart, stateless, side-effect-free style analysis primitives.
///
/// All methods are [static] — there is no per-instance state to drift.
class StyleAnalysisUtils {
  const StyleAnalysisUtils._();

  /// Extracts all CJK characters from text as a list.
  ///
  /// Includes three Unicode ranges:
  /// - CJK Unified Ideographs (0x4E00–0x9FFF)
  /// - CJK Extension A (0x3400–0x4DBF)
  /// - CJK Symbols and Punctuation (0x3000–0x303F)
  static List<String> extractCjkChars(String text) {
    return text.runes
        .where(
          (r) =>
              (r >= 0x4E00 && r <= 0x9FFF) || // CJK Unified
              (r >= 0x3400 && r <= 0x4DBF) || // CJK Extension A
              (r >= 0x3000 && r <= 0x303F), // CJK Symbols
        )
        .map((r) => String.fromCharCode(r))
        .toList();
  }

  /// Counts CJK characters (Chinese, Japanese, Korean) in text.
  static int cjkCharCount(String text) => extractCjkChars(text).length;

  /// Splits text into sentences by Chinese/standard punctuation and returns
  /// the CJK character count of each non-empty sentence.
  ///
  /// Splits on `[。！？；\n]+`.
  static List<int> extractSentenceLengths(String text) {
    final sentences = text.split(RegExp(r'[。！？；\n]+'));
    return sentences
        .map((s) => cjkCharCount(s.trim()))
        .where((len) => len > 0)
        .toList();
  }

  /// Computes rhythm score (0.0 = very varied/bursty, 1.0 = very uniform).
  ///
  /// Uses coefficient of variation (CV) of sentence lengths.
  /// High CV = high burstiness = low score (good, human-like).
  /// Low CV = low burstiness = high score (AI-like, uniform).
  ///
  /// Returns neutral 0.5 for sub-threshold inputs:
  /// - fewer than 5 sentences (thin sample → unreliable variance)
  /// - zero average length (degenerate)
  static double computeRhythmScore(List<int> lengths) {
    if (lengths.length < 5) return 0.5;

    final avg = lengths.reduce((a, b) => a + b) / lengths.length;
    if (avg == 0) return 0.5;

    final variance =
        lengths.map((l) => (l - avg) * (l - avg)).reduce((a, b) => a + b) /
        lengths.length;
    final stdDev = sqrt(variance);
    final cv = stdDev / avg;

    // CV > 0.8 = very varied (human-like), CV < 0.3 = very uniform (AI-like)
    // Normalize to 0.0 (varied) – 1.0 (uniform)
    return (1.0 - (cv - 0.3) / 0.5).clamp(0.0, 1.0);
  }

  /// Computes vocabulary richness (0.0 = repetitive, 1.0 = very diverse).
  ///
  /// Uses unique CJK character ratio (type-token ratio).
  ///
  /// Returns neutral 0.5 when the sample has fewer than 50 CJK characters
  /// (thin sample → unreliable type-token ratio).
  ///
  /// Normalization: typical Chinese prose has 30-50% unique ratio.
  /// `< 25%` = very repetitive, `> 55%` = extremely diverse.
  static double computeVocabularyRichness(String text) {
    final cjkChars = extractCjkChars(text);
    if (cjkChars.length < 50) return 0.5;

    final uniqueChars = cjkChars.toSet().length;
    final ratio = uniqueChars / cjkChars.length;

    return ((ratio - 0.25) / 0.30).clamp(0.0, 1.0);
  }
}

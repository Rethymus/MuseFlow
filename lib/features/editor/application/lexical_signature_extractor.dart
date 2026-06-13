/// Lexical signature extractor — pure-function CJK n-gram analysis.
///
/// Extracts high-frequency characteristic bigrams and trigrams from author
/// text to build a [LexicalSignature]. Implements the pipeline:
///
/// 1. CJK segmentation (punctuation/space/latin as delimiters)
/// 2. n-gram generation (bigram windows of 2, trigram windows of 3)
/// 3. frequency counting
/// 4. stopword filtering ([CjkStopwords]: exact multi-char functional
///    phrase OR any single-char function particle)
/// 5. salience scoring (trigram weight 1.5 > bigram weight 1.0)
/// 6. ranking (no substring dedup — bigrams and trigrams of the same span
///    are both retained as distinct author-characteristic surface forms)
/// 7. truncation to maxTerms
///
/// No IO, no external dependencies. Corresponds to the IJCNLP 2025
/// Author Writing Sheet characteristic-word extraction.
library;

import 'package:museflow/features/editor/domain/lexical_signature.dart';
import 'package:museflow/features/editor/infrastructure/cjk_stopwords.dart';

/// Pure-function extractor for author characteristic n-grams.
class LexicalSignatureExtractor {
  const LexicalSignatureExtractor();

  /// Salience weight applied to trigram scores (vs 1.0 for bigrams).
  static const double _trigramWeight = 1.5;

  /// Salience weight applied to bigram scores.
  static const double _bigramWeight = 1.0;

  /// Extracts a ranked [LexicalSignature] from [text].
  ///
  /// Returns an empty signature when the text contains no CJK content
  /// (empty / latin-only / punctuation-only). [maxTerms] bounds the result.
  static LexicalSignature extract(String text, {int maxTerms = 15}) {
    final segments = _extractCjkSegments(text);
    if (segments.isEmpty) return LexicalSignature.empty;

    final frequencies = <String, int>{};
    for (final segment in segments) {
      for (final gram in _generateNGrams(segment)) {
        frequencies[gram] = (frequencies[gram] ?? 0) + 1;
      }
    }

    final candidates = <LexicalTerm>[];
    for (final entry in frequencies.entries) {
      final gram = entry.key;
      if (gram.length < 2) continue;
      if (_isStopword(gram)) continue;
      final weight = gram.length >= 3 ? _trigramWeight : _bigramWeight;
      final score = entry.value.toDouble() * weight;
      candidates.add(
        LexicalTerm(term: gram, score: score, frequency: entry.value),
      );
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));

    // No substring dedup: bigrams and trigrams of the same span are
    // deliberately both retained (e.g. 拔剑 + 拔剑四 both capture distinct
    // author-characteristic surface forms). Salience ranking (trigram ×1.5
    // > bigram ×1.0) naturally orders them, and maxTerms bounds the result.
    final selected = candidates.take(maxTerms).toList(growable: false);

    return LexicalSignature(topTerms: selected);
  }

  /// Splits text into maximal CJK-only runs (punctuation/latin/space as
  /// delimiters). CJK Unified (0x4E00–0x9FFF) + Extension A (0x3400–0x4DBF).
  static List<String> _extractCjkSegments(String text) {
    final segments = <String>[];
    final buf = <String>[];
    for (final rune in text.runes) {
      if (_isCjk(rune)) {
        buf.add(String.fromCharCode(rune));
      } else if (buf.isNotEmpty) {
        segments.add(buf.join());
        buf.clear();
      }
    }
    if (buf.isNotEmpty) segments.add(buf.join());
    return segments;
  }

  static bool _isCjk(int rune) =>
      (rune >= 0x4E00 && rune <= 0x9FFF) || // CJK Unified Ideographs
      (rune >= 0x3400 && rune <= 0x4DBF); // CJK Extension A

  /// Whether [gram] is a stopword n-gram.
  ///
  /// Discards on EITHER:
  /// - exact match against a multi-char functional phrase (知道/这个/没有),
  ///   whose constituent characters are not themselves function particles;
  /// - containing ANY single-char function particle (的/了/是/在 …).
  ///
  /// Content-bearing characters that form characteristic compounds
  /// (道→道心/剑道, 人→人间, 有→有意, 看→看破) are deliberately absent from
  /// [CjkStopwords.functionChars], so genuine author vocabulary survives.
  static bool _isStopword(String gram) {
    if (CjkStopwords.functionPhrases.contains(gram)) return true;
    for (final rune in gram.runes) {
      if (CjkStopwords.functionChars.contains(String.fromCharCode(rune))) {
        return true;
      }
    }
    return false;
  }

  /// Generates bigrams and trigrams for a segment of length >= 2.
  static Iterable<String> _generateNGrams(String segment) sync* {
    final runes = segment.runes.toList();
    if (runes.length < 2) return;
    for (var i = 0; i + 2 <= runes.length; i++) {
      yield String.fromCharCodes(runes.sublist(i, i + 2));
    }
    for (var i = 0; i + 3 <= runes.length; i++) {
      yield String.fromCharCodes(runes.sublist(i, i + 3));
    }
  }
}

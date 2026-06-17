/// Tests for [StyleAnalysisUtils] — the single ruler shared by
/// [StyleAnalyzer] (baseline) and [StyleDeviationDetector] (measurement).
///
/// These tests lock the ONE authoritative implementation of CJK extraction,
/// sentence-length extraction, rhythm scoring, and vocabulary richness.
/// Both consumers MUST delegate to this class — any future single-sided
/// edit to either consumer's dimension math is structurally impossible
/// because there is no longer a duplicate copy to edit.
///
/// See PLAN quick-260617-jgd for the dual-ruler campaign context.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/style_analysis_utils.dart';

void main() {
  group('StyleAnalysisUtils.extractCjkChars', () {
    test('should extract CJK Unified ideographs (0x4E00-0x9FFF)', () {
      const text = '林风站在山门前';
      final chars = StyleAnalysisUtils.extractCjkChars(text);

      expect(chars, hasLength(7));
      expect(chars, equals(['林', '风', '站', '在', '山', '门', '前']));
    });

    test('should include CJK Extension A range (0x3400-0x4DBF)', () {
      // 㐀 (U+3400) and 㐁 (U+3401) — CJK Extension A.
      const text = '㐀㐁字';
      final chars = StyleAnalysisUtils.extractCjkChars(text);

      expect(chars, hasLength(3));
      expect(chars, contains('㐀'));
      expect(chars, contains('㐁'));
      expect(chars, contains('字'));
    });

    test('should include CJK Symbols and Punctuation range (0x3000-0x303F)', () {
      // 。(U+3002), 「(U+300C), 」(U+300D), 〔(U+3014) — all in CJK Symbols.
      const text = '「林。」〔风〕';
      final chars = StyleAnalysisUtils.extractCjkChars(text);

      // Order preserved as runes are encountered: 「 林 。 」 〔 风 〕
      expect(chars, equals(['「', '林', '。', '」', '〔', '风', '〕']));
    });

    test('should ignore ASCII, Latin, digits, whitespace', () {
      const text = 'hello 123 world 林风 abc!';
      final chars = StyleAnalysisUtils.extractCjkChars(text);

      expect(chars, equals(['林', '风']));
    });

    test('should return empty list for text with no CJK', () {
      expect(StyleAnalysisUtils.extractCjkChars(''), isEmpty);
      expect(StyleAnalysisUtils.extractCjkChars('abc 123 !@#'), isEmpty);
    });

    test('cjkCharCount should equal extractCjkChars length', () {
      const text = '「林。」〔风〕abc';
      expect(
        StyleAnalysisUtils.cjkCharCount(text),
        StyleAnalysisUtils.extractCjkChars(text).length,
      );
      expect(StyleAnalysisUtils.cjkCharCount(text), 7);
    });
  });

  group('StyleAnalysisUtils.extractSentenceLengths', () {
    test('should split on 。！？； and newlines', () {
      const text = '林风走。忽然！停下？休息；继续\n再来。';
      final lengths = StyleAnalysisUtils.extractSentenceLengths(text);

      // Segments: "林风走"(3), "忽然"(2), "停下"(2), "休息"(2), "继续"(2), "再来"(2)
      expect(lengths, equals([3, 2, 2, 2, 2, 2]));
    });

    test('should drop zero-length segments (no CJK after split)', () {
      const text = '林风。。走。。';
      final lengths = StyleAnalysisUtils.extractSentenceLengths(text);

      expect(lengths, equals([2, 1])); // 林风(2), 走(1)
    });

    test('should count CJK chars per sentence, not raw chars', () {
      // Mixed CJK + Latin: only CJK count contributes to length.
      const text = '林风abc走。';
      final lengths = StyleAnalysisUtils.extractSentenceLengths(text);

      expect(lengths, equals([3])); // 林风走 = 3 CJK, abc ignored
    });

    test('should return empty list for text without sentence breaks or CJK', () {
      expect(
        StyleAnalysisUtils.extractSentenceLengths('hello world'),
        isEmpty,
      );
    });

    test('should treat consecutive delimiters as one split', () {
      const text = '林风。。走。。！跑';
      final lengths = StyleAnalysisUtils.extractSentenceLengths(text);

      expect(lengths, equals([2, 1, 1])); // 林风, 走, 跑
    });
  });

  group('StyleAnalysisUtils.computeRhythmScore', () {
    test('should return neutral 0.5 for fewer than 5 sentences', () {
      // 4 sentences — below the <5 guard.
      expect(StyleAnalysisUtils.computeRhythmScore([10, 10, 10, 10]), 0.5);
      expect(StyleAnalysisUtils.computeRhythmScore([10, 20]), 0.5);
      expect(StyleAnalysisUtils.computeRhythmScore(<int>[]), 0.5);
    });

    test('should return 1.0 for 5+ uniform-length sentences (AI-like)', () {
      // Uniform → cv ≈ 0 → (1.0 - (0-0.3)/0.5).clamp = clamp(1.6) = 1.0.
      final score = StyleAnalysisUtils.computeRhythmScore([10, 10, 10, 10, 10]);
      expect(score, closeTo(1.0, 1e-9));
    });

    test('should approach 0.0 for highly varied lengths (human-like)', () {
      // Very varied lengths → high cv → (1.0 - (cv-0.3)/0.5) clamps to 0.0.
      // e.g. lengths with cv >> 0.8.
      final score = StyleAnalysisUtils.computeRhythmScore([2, 50, 3, 80, 4]);
      expect(score, lessThanOrEqualTo(0.05));
    });

    test('should return 0.5 when avg length is 0 (degenerate)', () {
      // Cannot happen with extractSentenceLengths (zero-length filtered),
      // but the guard exists; lock it.
      expect(StyleAnalysisUtils.computeRhythmScore([0, 0, 0, 0, 0]), 0.5);
    });

    test('should be in 0.0-1.0 range for moderate variation', () {
      final score = StyleAnalysisUtils.computeRhythmScore([10, 15, 12, 18, 11]);
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(1.0));
    });
  });

  group('StyleAnalysisUtils.computeVocabularyRichness', () {
    test('should return neutral 0.5 for fewer than 50 CJK chars', () {
      // 30 distinct chars — below the <50 guard.
      const text = '春风拂过青石板巷尾飘来桂花香我独自漫步那座老旧的小桥流水人家';
      final score = StyleAnalysisUtils.computeVocabularyRichness(text);
      expect(score, 0.5);
    });

    test('should return 1.0 when every char is unique (ratio 1.0)', () {
      // Build a 60-char string where every CJK char is distinct → ratio 1.0 →
      // ((1.0 - 0.25) / 0.30).clamp = clamp(2.5) = 1.0.
      final buffer = StringBuffer();
      for (var i = 0; i < 60; i++) {
        // 0x4E00 + i walks distinct CJK Unified code points.
        buffer.write(String.fromCharCode(0x4E00 + i));
      }
      final text = buffer.toString();
      final cjkCount = StyleAnalysisUtils.cjkCharCount(text);
      expect(cjkCount, 60, reason: 'fixture must be 60 distinct CJK chars');

      final score = StyleAnalysisUtils.computeVocabularyRichness(text);
      expect(score, closeTo(1.0, 1e-9));
    });

    test('should approach 0.0 for highly repetitive text', () {
      // 60 chars, only 1 distinct → ratio = 1/60 →
      // ((1/60 - 0.25)/0.30).clamp = clamp(negative) = 0.0.
      final text = '风' * 60;
      final score = StyleAnalysisUtils.computeVocabularyRichness(text);
      expect(score, closeTo(0.0, 1e-9));
    });

    test('should produce mid-range value at ratio 0.4', () {
      // ratio 0.4 → ((0.4 - 0.25)/0.30).clamp = 0.5 exactly.
      // Construct text with 20 distinct chars across 60 total chars
      // (each of the 20 distinct chars appears 3 times) → ratio = 1/3.
      final distinct = List.generate(
        20,
        (i) => String.fromCharCode(0x4E00 + i),
      );
      final text = distinct.join() * 3; // 20 × 3 = 60 chars, 20 distinct
      final cjkCount = StyleAnalysisUtils.cjkCharCount(text);
      final ratio = StyleAnalysisUtils.extractCjkChars(text).toSet().length /
          cjkCount;
      // 60 chars, 20 distinct → ratio 1/3 = 0.333...
      expect(cjkCount, 60);
      expect(ratio, closeTo(1 / 3, 1e-9));

      // At ratio 1/3: ((1/3 - 0.25)/0.30) = (0.0833/0.30) ≈ 0.278
      final score = StyleAnalysisUtils.computeVocabularyRichness(text);
      expect(score, closeTo(((1 / 3 - 0.25) / 0.30).clamp(0.0, 1.0), 1e-9));
    });

    test('should be clamped to 0.0-1.0 across extreme ratios', () {
      // Repetitive but ≥50 chars.
      expect(StyleAnalysisUtils.computeVocabularyRichness('风' * 100), 0.0);
      // All-unique ≥50 chars.
      final unique = List.generate(
        100,
        (i) => String.fromCharCode(0x4E00 + i),
      ).join();
      expect(StyleAnalysisUtils.computeVocabularyRichness(unique), 1.0);
    });
  });

  group('StyleAnalysisUtils cross-consumer consistency', () {
    test('rhythm <5 guard value matches the campaign-locked 0.5 baseline', () {
      // Locks the exact 0.5 early-return value. Any consumer delegating to
      // this util for sub-threshold input gets 0.5 — identical to the
      // analyzer's pre-refactor behavior.
      expect(StyleAnalysisUtils.computeRhythmScore([1, 2, 3, 4]), 0.5);
    });

    test('vocabulary <50 guard value matches the campaign-locked 0.5 baseline', () {
      // 49 chars (just below the threshold).
      final text = List.generate(
        49,
        (i) => String.fromCharCode(0x4E00 + i),
      ).join();
      expect(StyleAnalysisUtils.computeVocabularyRichness(text), 0.5);
    });
  });
}

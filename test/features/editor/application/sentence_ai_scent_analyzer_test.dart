/// Tests for [SentenceAiScentAnalyzer] — AA-04 sentence-level AI-scent.
///
/// Validates per-sentence AI-scent scoring: each sentence gets a 0-100 score
/// based on sentence-LOCAL signals (mechanical transition-word starts, AI-tell
/// patterns, high function-word ratio, run-on length). The overall detector
/// (StyleDeviationDetector, Phase 19) gives a whole-text score; this analyzer
/// tells the author *which specific sentences* are most AI-like, per SenDetEX
/// (EMNLP 2025) / LaTeCHCLfL 2026.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/sentence_ai_scent_analyzer.dart';

void main() {
  const analyzer = SentenceAiScentAnalyzer();

  group('SentenceAiScentAnalyzer AA-04 sentence-level scoring', () {
    test('empty or whitespace-only text yields no sentences', () {
      expect(analyzer.analyze('').scores, isEmpty);
      expect(analyzer.analyze('   \n  ').scores, isEmpty);
    });

    test('plain human-like prose scores low on every sentence', () {
      // Short, varied, concrete, dialogue — no AI tells.
      const text =
          '他推开门。风很冷。'
          '"你来晚了，"老人说。'
          '剑还带血。';
      final result = analyzer.analyze(text);
      expect(result.scores, isNotEmpty);
      // Every sentence should be below the "notable" threshold.
      for (final s in result.scores) {
        expect(
          s.score,
          lessThan(SentenceAiScentAnalyzer.notableThreshold),
          reason: 'human-like sentence should not be flagged: "${s.sentence}"',
        );
      }
      expect(result.hasNotable, isFalse);
    });

    test('flags a sentence starting with a mechanical transition word', () {
      const text = '他走进房间。然而，一切都变了。';
      final result = analyzer.analyze(text);
      final however = result.scores.firstWhere(
        (s) => s.sentence.contains('然而'),
      );
      expect(
        however.score,
        greaterThanOrEqualTo(SentenceAiScentAnalyzer.notableThreshold),
      );
      expect(however.reasons.join(), anyOf(contains('过渡'), contains('机械')));
    });

    test('flags an AI-tell pattern ("不仅...而且")', () {
      const text = '他不仅剑法精湛，而且心思缜密。';
      final result = analyzer.analyze(text);
      expect(result.scores, isNotEmpty);
      final worst = result.worst!;
      expect(
        worst.score,
        greaterThanOrEqualTo(SentenceAiScentAnalyzer.notableThreshold),
      );
      expect(
        worst.reasons.join(),
        anyOf(contains('AI'), contains('套式'), contains('模式')),
      );
    });

    test('flags high function-word ratio sentence', () {
      // Stuffed with 的/了/是/在/和 — function-word heavy, content-light.
      const text = '他的剑是他的，而她的剑也是的，是的，是的。';
      final result = analyzer.analyze(text);
      final worst = result.worst!;
      expect(
        worst.score,
        greaterThanOrEqualTo(SentenceAiScentAnalyzer.notableThreshold),
      );
      expect(worst.reasons.join(), anyOf(contains('虚词'), contains('功能词')));
    });

    test('scores are sorted descending (worst first)', () {
      const text = '他推开门。然而，一切都变了。剑很冷。此外，天黑了。';
      final result = analyzer.analyze(text);
      final scores = result.scores.map((s) => s.score).toList();
      for (var i = 1; i < scores.length; i++) {
        expect(
          scores[i - 1],
          greaterThanOrEqualTo(scores[i]),
          reason: 'scores must be non-increasing',
        );
      }
    });

    test('worst is the highest-scoring sentence; null when empty', () {
      expect(analyzer.analyze('').worst, isNull);
      const text = '然而，天黑了。他笑了。';
      final result = analyzer.analyze(text);
      expect(result.worst, isNotNull);
      expect(result.worst!.sentence, contains('然而'));
    });

    test('respects maxSentences cap', () {
      const text = '然而，一。二。此外，三。四。综上所述，五。六。';
      final result = analyzer.analyze(text, maxSentences: 2);
      expect(result.scores.length, lessThanOrEqualTo(2));
    });

    test('clamps score to [0, 100]', () {
      // A sentence hitting every signal should still be ≤ 100.
      const text = '然而，他不仅剑法精湛，而且在这个时代，他的剑是他的，是的。';
      final result = analyzer.analyze(text);
      for (final s in result.scores) {
        expect(s.score, lessThanOrEqualTo(100));
        expect(s.score, greaterThanOrEqualTo(0));
      }
    });
  });
}

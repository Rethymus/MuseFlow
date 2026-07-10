library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/literary_quality_balancer.dart';
import 'package:museflow/features/editor/application/literary_quality_evaluator.dart';

void main() {
  group('LiteraryQualityBalancer', () {
    test('prefers feasible quality over a high-false-positive candidate', () {
      const good = LiteraryQualityConfig.defaults();
      final noisy = good.copyWith(classificationThreshold: 10);
      final corpus = LiteraryQualityCorpus.fromScores(
        version: 1,
        samples: const [
          LabeledLiteraryQualityScore(
            id: 'ai-1',
            label: LiteraryQualityLabel.aiLike,
            score: 80,
          ),
          LabeledLiteraryQualityScore(
            id: 'ai-2',
            label: LiteraryQualityLabel.aiLike,
            score: 70,
          ),
          LabeledLiteraryQualityScore(
            id: 'human-1',
            label: LiteraryQualityLabel.human,
            score: 20,
          ),
          LabeledLiteraryQualityScore(
            id: 'human-2',
            label: LiteraryQualityLabel.human,
            score: 5,
          ),
        ],
      );

      const balancer = LiteraryQualityBalancer(
        minimumRecall: 0.8,
        maximumFalsePositiveRate: 0.1,
      );
      final result = balancer.balanceScores(
        corpus: corpus,
        candidates: [noisy, good],
      );

      expect(result.config, good);
      expect(result.metrics.balancedAccuracy, 1);
    });

    test('tie-break is deterministic regardless of candidate order', () {
      const first = LiteraryQualityConfig.defaults();
      final second = first.copyWith(sentenceNotableThreshold: 35);
      final corpus = LiteraryQualityCorpus.fromScores(
        version: 1,
        samples: const [
          LabeledLiteraryQualityScore(
            id: 'ai',
            label: LiteraryQualityLabel.aiLike,
            score: 90,
          ),
          LabeledLiteraryQualityScore(
            id: 'human',
            label: LiteraryQualityLabel.human,
            score: 0,
          ),
        ],
      );
      const balancer = LiteraryQualityBalancer();

      final forward = balancer.balanceScores(
        corpus: corpus,
        candidates: [second, first],
      );
      final reverse = balancer.balanceScores(
        corpus: corpus,
        candidates: [first, second],
      );

      expect(forward.config, reverse.config);
      expect(forward.config, first);
    });
  });
}

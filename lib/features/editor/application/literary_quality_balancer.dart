/// Constraint-first deterministic parameter search for literary quality.
library;

import 'package:museflow/features/editor/application/literary_quality_evaluator.dart';

class LiteraryQualityBalanceResult {
  final LiteraryQualityConfig config;
  final LiteraryQualityMetrics metrics;
  final int candidateCount;

  const LiteraryQualityBalanceResult({
    required this.config,
    required this.metrics,
    required this.candidateCount,
  });
}

class LiteraryQualityBalancer {
  final double minimumRecall;
  final double maximumFalsePositiveRate;

  const LiteraryQualityBalancer({
    this.minimumRecall = 0.75,
    this.maximumFalsePositiveRate = 0.1,
  });

  LiteraryQualityBalanceResult balance({
    required LiteraryQualityCorpus corpus,
    Iterable<LiteraryQualityConfig>? candidates,
  }) {
    const evaluator = LiteraryQualityEvaluator();
    final configs = (candidates ?? defaultCandidates()).toList();
    final evaluated = configs
        .map((config) => evaluator.evaluate(corpus: corpus, config: config))
        .toList();
    return _select(evaluated, configs.length);
  }

  LiteraryQualityBalanceResult balanceScores({
    required LiteraryQualityCorpus corpus,
    required Iterable<LiteraryQualityConfig> candidates,
  }) {
    final scores = corpus.fixedScores;
    if (scores == null) throw ArgumentError('score corpus required');
    const evaluator = LiteraryQualityEvaluator();
    final configs = candidates.toList();
    final evaluated = configs
        .map(
          (config) => LiteraryQualityEvaluation(
            config: config,
            metrics: evaluator.evaluateScores(
              samples: scores,
              threshold: config.classificationThreshold,
            ),
            scores: scores,
          ),
        )
        .toList();
    return _select(evaluated, configs.length);
  }

  Iterable<LiteraryQualityConfig> defaultCandidates() sync* {
    const base = LiteraryQualityConfig.defaults();
    const weightSets = [
      [0.2, 0.25, 0.15, 0.2, 0.2],
      [0.15, 0.3, 0.15, 0.2, 0.2],
      [0.2, 0.3, 0.1, 0.2, 0.2],
      [0.2, 0.2, 0.15, 0.25, 0.2],
    ];
    for (final weights in weightSets) {
      for (final notable in const [25, 30, 35, 40]) {
        for (final classification in const [35, 40, 45, 50, 55]) {
          yield base.copyWith(
            sentenceLengthWeight: weights[0],
            rhythmWeight: weights[1],
            vocabularyWeight: weights[2],
            rhetoricWeight: weights[3],
            emotionalToneWeight: weights[4],
            sentenceNotableThreshold: notable,
            classificationThreshold: classification,
          );
        }
      }
    }
  }

  LiteraryQualityBalanceResult _select(
    List<LiteraryQualityEvaluation> evaluated,
    int candidateCount,
  ) {
    if (evaluated.isEmpty) throw ArgumentError('candidates must not be empty');
    evaluated.sort(_compare);
    final best = evaluated.first;
    return LiteraryQualityBalanceResult(
      config: best.config,
      metrics: best.metrics,
      candidateCount: candidateCount,
    );
  }

  int _compare(
    LiteraryQualityEvaluation left,
    LiteraryQualityEvaluation right,
  ) {
    final leftFeasible = _isFeasible(left.metrics);
    final rightFeasible = _isFeasible(right.metrics);
    if (leftFeasible != rightFeasible) return leftFeasible ? -1 : 1;
    var comparison = right.metrics.balancedAccuracy.compareTo(
      left.metrics.balancedAccuracy,
    );
    if (comparison != 0) return comparison;
    comparison = right.metrics.recall.compareTo(left.metrics.recall);
    if (comparison != 0) return comparison;
    comparison = left.metrics.falsePositiveRate.compareTo(
      right.metrics.falsePositiveRate,
    );
    if (comparison != 0) return comparison;
    comparison = right.metrics.scoreSeparation.compareTo(
      left.metrics.scoreSeparation,
    );
    if (comparison != 0) return comparison;
    return left.config.stableKey.compareTo(right.config.stableKey);
  }

  bool _isFeasible(LiteraryQualityMetrics metrics) =>
      metrics.recall >= minimumRecall &&
      metrics.falsePositiveRate <= maximumFalsePositiveRate;
}

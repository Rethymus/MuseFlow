/// Deterministic literary-quality evaluation for the editor's anti-AI signals.
library;

import 'dart:math' as math;

import 'package:museflow/features/editor/application/sentence_ai_scent_analyzer.dart';
import 'package:museflow/features/editor/application/style_deviation_detector.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';

enum LiteraryQualityLabel { human, aiLike }

class LiteraryQualityConfig {
  final double sentenceLengthWeight;
  final double rhythmWeight;
  final double vocabularyWeight;
  final double rhetoricWeight;
  final double emotionalToneWeight;
  final double styleScoreWeight;
  final double deviationThreshold;
  final int sentenceNotableThreshold;
  final int classificationThreshold;

  const LiteraryQualityConfig({
    required this.sentenceLengthWeight,
    required this.rhythmWeight,
    required this.vocabularyWeight,
    required this.rhetoricWeight,
    required this.emotionalToneWeight,
    required this.styleScoreWeight,
    required this.deviationThreshold,
    required this.sentenceNotableThreshold,
    required this.classificationThreshold,
  });

  const LiteraryQualityConfig.defaults()
    : sentenceLengthWeight = 0.2,
      rhythmWeight = 0.2,
      vocabularyWeight = 0.15,
      rhetoricWeight = 0.25,
      emotionalToneWeight = 0.2,
      styleScoreWeight = 0.55,
      deviationThreshold = 0.3,
      sentenceNotableThreshold = 25,
      classificationThreshold = 35;

  List<double> get styleWeights => [
    sentenceLengthWeight,
    rhythmWeight,
    vocabularyWeight,
    rhetoricWeight,
    emotionalToneWeight,
  ];

  LiteraryQualityConfig copyWith({
    double? sentenceLengthWeight,
    double? rhythmWeight,
    double? vocabularyWeight,
    double? rhetoricWeight,
    double? emotionalToneWeight,
    double? styleScoreWeight,
    double? deviationThreshold,
    int? sentenceNotableThreshold,
    int? classificationThreshold,
  }) => LiteraryQualityConfig(
    sentenceLengthWeight: sentenceLengthWeight ?? this.sentenceLengthWeight,
    rhythmWeight: rhythmWeight ?? this.rhythmWeight,
    vocabularyWeight: vocabularyWeight ?? this.vocabularyWeight,
    rhetoricWeight: rhetoricWeight ?? this.rhetoricWeight,
    emotionalToneWeight: emotionalToneWeight ?? this.emotionalToneWeight,
    styleScoreWeight: styleScoreWeight ?? this.styleScoreWeight,
    deviationThreshold: deviationThreshold ?? this.deviationThreshold,
    sentenceNotableThreshold:
        sentenceNotableThreshold ?? this.sentenceNotableThreshold,
    classificationThreshold:
        classificationThreshold ?? this.classificationThreshold,
  );

  factory LiteraryQualityConfig.fromJson(Map<String, dynamic> json) =>
      LiteraryQualityConfig(
        sentenceLengthWeight: _double(json, 'sentenceLengthWeight'),
        rhythmWeight: _double(json, 'rhythmWeight'),
        vocabularyWeight: _double(json, 'vocabularyWeight'),
        rhetoricWeight: _double(json, 'rhetoricWeight'),
        emotionalToneWeight: _double(json, 'emotionalToneWeight'),
        styleScoreWeight: _double(json, 'styleScoreWeight'),
        deviationThreshold: _double(json, 'deviationThreshold'),
        sentenceNotableThreshold: _integer(json, 'sentenceNotableThreshold'),
        classificationThreshold: _integer(json, 'classificationThreshold'),
      );

  Map<String, Object> toJson() => {
    'sentenceLengthWeight': sentenceLengthWeight,
    'rhythmWeight': rhythmWeight,
    'vocabularyWeight': vocabularyWeight,
    'rhetoricWeight': rhetoricWeight,
    'emotionalToneWeight': emotionalToneWeight,
    'styleScoreWeight': styleScoreWeight,
    'deviationThreshold': deviationThreshold,
    'sentenceNotableThreshold': sentenceNotableThreshold,
    'classificationThreshold': classificationThreshold,
  };

  String get stableKey => [
    sentenceLengthWeight,
    rhythmWeight,
    vocabularyWeight,
    rhetoricWeight,
    emotionalToneWeight,
    styleScoreWeight,
    deviationThreshold,
    sentenceNotableThreshold,
    classificationThreshold,
  ].map((value) => value.toString()).join('|');

  @override
  bool operator ==(Object other) =>
      other is LiteraryQualityConfig && stableKey == other.stableKey;

  @override
  int get hashCode => stableKey.hashCode;
}

class LiteraryQualitySample {
  final String id;
  final LiteraryQualityLabel label;
  final String text;

  const LiteraryQualitySample({
    required this.id,
    required this.label,
    required this.text,
  });
}

class LabeledLiteraryQualityScore {
  final String id;
  final LiteraryQualityLabel label;
  final int score;

  const LabeledLiteraryQualityScore({
    required this.id,
    required this.label,
    required this.score,
  });
}

class LiteraryQualityCorpus {
  final int version;
  final AuthorStyleProfile? profile;
  final List<LiteraryQualitySample> samples;
  final List<LabeledLiteraryQualityScore>? fixedScores;

  const LiteraryQualityCorpus({
    required this.version,
    required this.profile,
    required this.samples,
    this.fixedScores,
  });

  factory LiteraryQualityCorpus.fromScores({
    required int version,
    required List<LabeledLiteraryQualityScore> samples,
  }) => LiteraryQualityCorpus(
    version: version,
    profile: null,
    samples: const [],
    fixedScores: List.unmodifiable(samples),
  );

  factory LiteraryQualityCorpus.fromJson(Map<String, dynamic> json) {
    final version = _integer(json, 'version');
    final profileJson = json['profile'];
    final rawSamples = json['samples'];
    if (profileJson is! Map<String, dynamic> || rawSamples is! List) {
      throw const FormatException('corpus requires profile and samples');
    }
    final ids = <String>{};
    final samples = rawSamples
        .map((raw) {
          if (raw is! Map<String, dynamic>) {
            throw const FormatException('sample must be an object');
          }
          final id = raw['id'];
          final labelName = raw['label'];
          final text = raw['text'];
          if (id is! String || id.isEmpty || text is! String || text.isEmpty) {
            throw const FormatException(
              'sample requires non-empty id and text',
            );
          }
          if (!ids.add(id)) throw FormatException('duplicate sample id: $id');
          final label = switch (labelName) {
            'human' => LiteraryQualityLabel.human,
            'aiLike' => LiteraryQualityLabel.aiLike,
            _ => throw FormatException('unknown sample label: $labelName'),
          };
          return LiteraryQualitySample(id: id, label: label, text: text);
        })
        .toList(growable: false);
    if (samples.where((s) => s.label == LiteraryQualityLabel.human).isEmpty ||
        samples.where((s) => s.label == LiteraryQualityLabel.aiLike).isEmpty) {
      throw const FormatException('corpus requires both labels');
    }
    return LiteraryQualityCorpus(
      version: version,
      profile: AuthorStyleProfile.fromJson(profileJson),
      samples: samples,
    );
  }
}

class LiteraryQualityMetrics {
  final int truePositives;
  final int falseNegatives;
  final int trueNegatives;
  final int falsePositives;
  final double averageAiLikeScore;
  final double averageHumanScore;

  const LiteraryQualityMetrics({
    required this.truePositives,
    required this.falseNegatives,
    required this.trueNegatives,
    required this.falsePositives,
    required this.averageAiLikeScore,
    required this.averageHumanScore,
  });

  int get sampleCount =>
      truePositives + falseNegatives + trueNegatives + falsePositives;
  double get recall => _ratio(truePositives, truePositives + falseNegatives);
  double get specificity =>
      _ratio(trueNegatives, trueNegatives + falsePositives);
  double get falsePositiveRate => 1 - specificity;
  double get accuracy => _ratio(truePositives + trueNegatives, sampleCount);
  double get balancedAccuracy => (recall + specificity) / 2;
  double get scoreSeparation => averageAiLikeScore - averageHumanScore;

  factory LiteraryQualityMetrics.fromJson(Map<String, dynamic> json) =>
      LiteraryQualityMetrics(
        truePositives: _integer(json, 'truePositives'),
        falseNegatives: _integer(json, 'falseNegatives'),
        trueNegatives: _integer(json, 'trueNegatives'),
        falsePositives: _integer(json, 'falsePositives'),
        averageAiLikeScore: _double(json, 'averageAiLikeScore'),
        averageHumanScore: _double(json, 'averageHumanScore'),
      );

  Map<String, Object> toJson() => {
    'truePositives': truePositives,
    'falseNegatives': falseNegatives,
    'trueNegatives': trueNegatives,
    'falsePositives': falsePositives,
    'averageAiLikeScore': _round(averageAiLikeScore),
    'averageHumanScore': _round(averageHumanScore),
    'recall': _round(recall),
    'falsePositiveRate': _round(falsePositiveRate),
    'accuracy': _round(accuracy),
    'balancedAccuracy': _round(balancedAccuracy),
    'scoreSeparation': _round(scoreSeparation),
  };
}

class LiteraryQualityEvaluation {
  final LiteraryQualityConfig config;
  final LiteraryQualityMetrics metrics;
  final List<LabeledLiteraryQualityScore> scores;

  const LiteraryQualityEvaluation({
    required this.config,
    required this.metrics,
    required this.scores,
  });
}

class LiteraryQualityEvaluator {
  const LiteraryQualityEvaluator();

  LiteraryQualityEvaluation evaluate({
    required LiteraryQualityCorpus corpus,
    required LiteraryQualityConfig config,
  }) {
    final profile = corpus.profile;
    if (profile == null) {
      throw ArgumentError('text evaluation requires a corpus profile');
    }
    final styleDetector = StyleDeviationDetector(
      weights: config.styleWeights,
      threshold: config.deviationThreshold,
    );
    final sentenceAnalyzer = SentenceAiScentAnalyzer(
      threshold: config.sentenceNotableThreshold,
    );
    final scores = corpus.samples
        .map((sample) {
          final style = styleDetector.analyze(
            text: sample.text,
            profile: profile,
          );
          final sentence = sentenceAnalyzer.analyze(sample.text);
          final notableScores = sentence.scores
              .where((item) => item.score >= config.sentenceNotableThreshold)
              .map((item) => item.score)
              .toList();
          final sentenceScore = notableScores.isEmpty
              ? 0
              : notableScores.reduce(math.max);
          final styleScore = style?.aiScentScore ?? 0;
          final combined =
              styleScore * config.styleScoreWeight +
              sentenceScore * (1 - config.styleScoreWeight);
          return LabeledLiteraryQualityScore(
            id: sample.id,
            label: sample.label,
            score: combined.round().clamp(0, 100),
          );
        })
        .toList(growable: false);
    return LiteraryQualityEvaluation(
      config: config,
      metrics: evaluateScores(
        samples: scores,
        threshold: config.classificationThreshold,
      ),
      scores: scores,
    );
  }

  LiteraryQualityMetrics evaluateScores({
    required List<LabeledLiteraryQualityScore> samples,
    required int threshold,
  }) {
    var tp = 0;
    var fn = 0;
    var tn = 0;
    var fp = 0;
    var aiTotal = 0;
    var humanTotal = 0;
    var aiCount = 0;
    var humanCount = 0;
    for (final sample in samples) {
      final predictedAi = sample.score >= threshold;
      if (sample.label == LiteraryQualityLabel.aiLike) {
        aiTotal += sample.score;
        aiCount++;
        predictedAi ? tp++ : fn++;
      } else {
        humanTotal += sample.score;
        humanCount++;
        predictedAi ? fp++ : tn++;
      }
    }
    if (aiCount == 0 || humanCount == 0) {
      throw ArgumentError('evaluation requires both labels');
    }
    return LiteraryQualityMetrics(
      truePositives: tp,
      falseNegatives: fn,
      trueNegatives: tn,
      falsePositives: fp,
      averageAiLikeScore: aiTotal / aiCount,
      averageHumanScore: humanTotal / humanCount,
    );
  }
}

class LiteraryQualityBaseline {
  final int corpusVersion;
  final LiteraryQualityConfig config;
  final LiteraryQualityMetrics metrics;
  final double minimumBalancedAccuracy;
  final double minimumRecall;
  final double maximumFalsePositiveRate;

  const LiteraryQualityBaseline({
    required this.corpusVersion,
    required this.config,
    required this.metrics,
    required this.minimumBalancedAccuracy,
    required this.minimumRecall,
    required this.maximumFalsePositiveRate,
  });

  factory LiteraryQualityBaseline.fromJson(Map<String, dynamic> json) =>
      LiteraryQualityBaseline(
        corpusVersion: _integer(json, 'corpusVersion'),
        config: LiteraryQualityConfig.fromJson(
          json['config'] as Map<String, dynamic>,
        ),
        metrics: LiteraryQualityMetrics.fromJson(
          json['metrics'] as Map<String, dynamic>,
        ),
        minimumBalancedAccuracy: _double(json, 'minimumBalancedAccuracy'),
        minimumRecall: _double(json, 'minimumRecall'),
        maximumFalsePositiveRate: _double(json, 'maximumFalsePositiveRate'),
      );

  Map<String, Object> toJson() => {
    'corpusVersion': corpusVersion,
    'config': config.toJson(),
    'metrics': metrics.toJson(),
    'minimumBalancedAccuracy': minimumBalancedAccuracy,
    'minimumRecall': minimumRecall,
    'maximumFalsePositiveRate': maximumFalsePositiveRate,
  };

  LiteraryQualityBaselineCheck compare({
    required LiteraryQualityConfig config,
    required LiteraryQualityMetrics metrics,
  }) {
    final failures = <String>[];
    if (config != this.config) failures.add('config differs from baseline');
    if (metrics.balancedAccuracy + 1e-9 < minimumBalancedAccuracy) {
      failures.add('balancedAccuracy below minimum');
    }
    if (metrics.recall + 1e-9 < minimumRecall) {
      failures.add('recall below minimum');
    }
    if (metrics.falsePositiveRate - 1e-9 > maximumFalsePositiveRate) {
      failures.add('falsePositiveRate above maximum');
    }
    if (metrics.balancedAccuracy + 1e-9 < this.metrics.balancedAccuracy) {
      failures.add('balancedAccuracy regressed from baseline');
    }
    return LiteraryQualityBaselineCheck(failures: failures);
  }
}

class LiteraryQualityBaselineCheck {
  final List<String> failures;
  const LiteraryQualityBaselineCheck({required this.failures});
  bool get passed => failures.isEmpty;
}

double _ratio(int numerator, int denominator) =>
    denominator == 0 ? 0 : numerator / denominator;

double _round(double value) => double.parse(value.toStringAsFixed(6));

double _double(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) throw FormatException('$key must be numeric');
  return value.toDouble();
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num || value.toInt() != value) {
    throw FormatException('$key must be an integer');
  }
  return value.toInt();
}

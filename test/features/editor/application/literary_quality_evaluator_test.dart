library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/literary_quality_evaluator.dart';
import 'package:museflow/features/editor/application/sentence_ai_scent_analyzer.dart';
import 'package:museflow/features/editor/application/style_deviation_detector.dart';

void main() {
  group('LiteraryQualityCorpus', () {
    test('parses a valid corpus and rejects duplicate ids', () {
      final corpus = LiteraryQualityCorpus.fromJson({
        'version': 1,
        'profile': _profileJson,
        'samples': [
          {'id': 'human-1', 'label': 'human', 'text': '风停了。他把旧信折好，塞回衣襟。'},
          {'id': 'ai-1', 'label': 'aiLike', 'text': '综上所述，这不仅重要，而且值得一提。'},
        ],
      });

      expect(corpus.samples, hasLength(2));
      expect(corpus.samples.last.label, LiteraryQualityLabel.aiLike);

      expect(
        () => LiteraryQualityCorpus.fromJson({
          'version': 1,
          'profile': _profileJson,
          'samples': [
            {'id': 'same', 'label': 'human', 'text': '甲乙丙丁。'},
            {'id': 'same', 'label': 'aiLike', 'text': '戊己庚辛。'},
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('LiteraryQualityEvaluator', () {
    test('defaults match the production detector configuration', () {
      const config = LiteraryQualityConfig.defaults();
      const sentenceDetector = SentenceAiScentAnalyzer();
      const styleDetector = StyleDeviationDetector();

      expect(config.sentenceNotableThreshold, sentenceDetector.threshold);
      expect(config.styleWeights, styleDetector.weights);
      expect(config.deviationThreshold, styleDetector.threshold);
    });

    test('computes confusion-matrix metrics and balanced accuracy', () {
      const evaluator = LiteraryQualityEvaluator();
      final result = evaluator.evaluateScores(
        samples: const [
          LabeledLiteraryQualityScore(
            id: 'tp',
            label: LiteraryQualityLabel.aiLike,
            score: 80,
          ),
          LabeledLiteraryQualityScore(
            id: 'fn',
            label: LiteraryQualityLabel.aiLike,
            score: 20,
          ),
          LabeledLiteraryQualityScore(
            id: 'tn-1',
            label: LiteraryQualityLabel.human,
            score: 10,
          ),
          LabeledLiteraryQualityScore(
            id: 'tn-2',
            label: LiteraryQualityLabel.human,
            score: 30,
          ),
        ],
        threshold: 50,
      );

      expect(result.truePositives, 1);
      expect(result.falseNegatives, 1);
      expect(result.trueNegatives, 2);
      expect(result.falsePositives, 0);
      expect(result.recall, 0.5);
      expect(result.falsePositiveRate, 0);
      expect(result.balancedAccuracy, 0.75);
    });

    test('baseline comparison catches metric and config drift', () {
      const metrics = LiteraryQualityMetrics(
        truePositives: 4,
        falseNegatives: 1,
        trueNegatives: 5,
        falsePositives: 0,
        averageAiLikeScore: 70,
        averageHumanScore: 15,
      );
      const config = LiteraryQualityConfig.defaults();
      final baseline = LiteraryQualityBaseline(
        corpusVersion: 1,
        config: config,
        metrics: metrics,
        minimumBalancedAccuracy: 0.85,
        minimumRecall: 0.75,
        maximumFalsePositiveRate: 0.1,
      );

      expect(baseline.compare(config: config, metrics: metrics).passed, isTrue);

      final drift = baseline.compare(
        config: config.copyWith(classificationThreshold: 65),
        metrics: const LiteraryQualityMetrics(
          truePositives: 3,
          falseNegatives: 2,
          trueNegatives: 4,
          falsePositives: 1,
          averageAiLikeScore: 60,
          averageHumanScore: 30,
        ),
      );
      expect(drift.passed, isFalse);
      expect(drift.failures.join(' '), contains('config'));
      expect(drift.failures.join(' '), contains('balancedAccuracy'));
    });

    test('committed corpus and baseline satisfy the quality gate', () {
      final corpus = LiteraryQualityCorpus.fromJson(
        jsonDecode(
              File('quality/literary_quality_corpus.json').readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final baseline = LiteraryQualityBaseline.fromJson(
        jsonDecode(
              File('quality/literary_quality_baseline.json').readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      const evaluator = LiteraryQualityEvaluator();
      final evaluation = evaluator.evaluate(
        corpus: corpus,
        config: baseline.config,
      );

      expect(baseline.corpusVersion, corpus.version);
      expect(
        baseline
            .compare(config: evaluation.config, metrics: evaluation.metrics)
            .failures,
        isEmpty,
      );
    });
  });
}

const _profileJson = <String, Object>{
  'manuscriptId': 'quality-fixture',
  'sentenceLengthStats': {
    'avg': 16,
    'stdDev': 8,
    'median': 14,
    'shortRatio': 0.3,
    'longRatio': 0.1,
  },
  'rhythmScore': 0.35,
  'vocabularyRichness': 0.55,
  'rhetoricHabits': {
    'metaphorFrequency': 0.08,
    'dialogueRatio': 0.25,
    'descriptionRatio': 0.35,
    'actionRatio': 0.25,
  },
  'emotionalTone': {'overall': '温暖克制', 'warmth': 0.55, 'intensity': 0.45},
  'analyzedChapterCount': 5,
  'analyzedCharCount': 12000,
  'lastAnalyzedAt': '2026-01-01T00:00:00.000Z',
};

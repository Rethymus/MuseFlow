import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/reports/domain/consistency_report.dart';

void main() {
  group('ConsistencyReport', () {
    test('should hold all fields including driftPerSegment', () {
      final report = ConsistencyReport(
        characterResults: const [
          EntityConsistencyResult(
            entityName: 'Alice',
            entityType: 'character',
            chaptersWhereMentioned: 80,
            consistencyScore: 0.92,
            flags: [
              ConsistencyFlag(
                chapterIndex: 45,
                field: 'personality',
                expectedValue: 'brave',
                observedText: 'timid',
                severity: DeviationSeverity.medium,
              ),
            ],
          ),
        ],
        settingResults: const [
          EntityConsistencyResult(
            entityName: 'Magic Academy',
            entityType: 'setting',
            chaptersWhereMentioned: 50,
            consistencyScore: 0.85,
            flags: [],
          ),
        ],
        overallConsistencyScore: 0.88,
        driftPerSegment: [
          0.95,
          0.93,
          0.91,
          0.88,
          0.85,
          0.82,
          0.80,
          0.78,
          0.75,
          0.72,
        ],
        narrativeQuality: const NarrativeQualitySnapshot(
          immersionScore: 0.8,
          characterAnchoringScore: 0.7,
          antiAiScentScore: 0.9,
          signals: [
            NarrativeQualitySignal(
              chapterIndex: 2,
              category: 'immersion',
              title: '场景沉浸线索偏弱',
              evidence: '感官词 0 个',
              suggestion: '补充动作或感官细节。',
              severity: DeviationSeverity.medium,
            ),
          ],
        ),
      );

      expect(report.characterResults.length, 1);
      expect(report.settingResults.length, 1);
      expect(report.overallConsistencyScore, 0.88);
      expect(report.driftPerSegment.length, 10);
      expect(report.driftPerSegment.first, 0.95);
      expect(report.driftPerSegment.last, 0.72);
      expect(report.narrativeQuality.immersionScore, 0.8);
      expect(report.narrativeQuality.signals.single.chapterIndex, 2);
    });

    test('should support copyWith', () {
      final report = ConsistencyReport(
        characterResults: const [],
        settingResults: const [],
        overallConsistencyScore: 0.9,
        driftPerSegment: List.filled(10, 0.9),
      );

      final updated = report.copyWith(overallConsistencyScore: 0.75);
      expect(updated.overallConsistencyScore, 0.75);
      expect(updated.characterResults, isEmpty); // unchanged
    });
  });

  group('NarrativeQualitySnapshot', () {
    test('should hold scores and review signals', () {
      const signal = NarrativeQualitySignal(
        chapterIndex: 4,
        category: 'style',
        title: '疑似模板化 AI 表达',
        evidence: '总而言之',
        suggestion: '改成角色动作或场景推进。',
        severity: DeviationSeverity.medium,
      );

      const snapshot = NarrativeQualitySnapshot(
        immersionScore: 0.6,
        characterAnchoringScore: 0.7,
        antiAiScentScore: 0.8,
        signals: [signal],
      );

      expect(snapshot.immersionScore, 0.6);
      expect(snapshot.characterAnchoringScore, 0.7);
      expect(snapshot.antiAiScentScore, 0.8);
      expect(snapshot.signals, [signal]);
      expect(snapshot.copyWith(antiAiScentScore: 1.0).antiAiScentScore, 1.0);
    });
  });

  group('EntityConsistencyResult', () {
    test('should hold all fields', () {
      const result = EntityConsistencyResult(
        entityName: 'Alice',
        entityType: 'character',
        chaptersWhereMentioned: 80,
        consistencyScore: 0.92,
        flags: [
          ConsistencyFlag(
            chapterIndex: 10,
            field: 'eye_color',
            expectedValue: 'blue',
            observedText: 'brown eyes',
            severity: DeviationSeverity.clear,
          ),
        ],
      );

      expect(result.entityName, 'Alice');
      expect(result.entityType, 'character');
      expect(result.chaptersWhereMentioned, 80);
      expect(result.consistencyScore, 0.92);
      expect(result.flags.length, 1);
    });

    test('should support copyWith', () {
      const result = EntityConsistencyResult(
        entityName: 'Bob',
        entityType: 'character',
        chaptersWhereMentioned: 30,
        consistencyScore: 0.5,
        flags: [],
      );

      final updated = result.copyWith(consistencyScore: 0.8);
      expect(updated.consistencyScore, 0.8);
      expect(updated.entityName, 'Bob');
    });
  });

  group('ConsistencyFlag', () {
    test('should hold all fields', () {
      const flag = ConsistencyFlag(
        chapterIndex: 45,
        field: 'power_level',
        expectedValue: 'S-rank',
        observedText: 'B-rank fighter',
        severity: DeviationSeverity.medium,
      );

      expect(flag.chapterIndex, 45);
      expect(flag.field, 'power_level');
      expect(flag.expectedValue, 'S-rank');
      expect(flag.observedText, 'B-rank fighter');
      expect(flag.severity, DeviationSeverity.medium);
    });

    test('should support equality', () {
      const flag1 = ConsistencyFlag(
        chapterIndex: 1,
        field: 'name',
        expectedValue: 'Alice',
        observedText: 'Alicia',
        severity: DeviationSeverity.low,
      );
      const flag2 = ConsistencyFlag(
        chapterIndex: 1,
        field: 'name',
        expectedValue: 'Alice',
        observedText: 'Alicia',
        severity: DeviationSeverity.low,
      );

      expect(flag1, equals(flag2));
    });
  });
}

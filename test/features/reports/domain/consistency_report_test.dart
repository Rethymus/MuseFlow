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
      );

      expect(report.characterResults.length, 1);
      expect(report.settingResults.length, 1);
      expect(report.overallConsistencyScore, 0.88);
      expect(report.driftPerSegment.length, 10);
      expect(report.driftPerSegment.first, 0.95);
      expect(report.driftPerSegment.last, 0.72);
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

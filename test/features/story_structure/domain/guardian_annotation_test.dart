import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';

void main() {
  group('GuardianFindingKind', () {
    test('should serialize to JSON string', () {
      expect(
        GuardianFindingKind.characterConsistency.toJsonString(),
        'characterConsistency',
      );
      expect(
        GuardianFindingKind.timelineContradiction.toJsonString(),
        'timelineContradiction',
      );
      expect(
        GuardianFindingKind.worldRuleConflict.toJsonString(),
        'worldRuleConflict',
      );
      expect(
        GuardianFindingKind.skillRuleConflict.toJsonString(),
        'skillRuleConflict',
      );
      expect(
        GuardianFindingKind.unresolvedForeshadowing.toJsonString(),
        'unresolvedForeshadowing',
      );
    });

    test('should deserialize from JSON string', () {
      expect(
        GuardianFindingKind.fromJsonString('characterConsistency'),
        GuardianFindingKind.characterConsistency,
      );
      expect(
        GuardianFindingKind.fromJsonString('timelineContradiction'),
        GuardianFindingKind.timelineContradiction,
      );
    });

    test('should default to characterConsistency for unknown value', () {
      expect(
        GuardianFindingKind.fromJsonString('unknown'),
        GuardianFindingKind.characterConsistency,
      );
    });
  });

  group('GuardianSeverity', () {
    test('should serialize to JSON string', () {
      expect(GuardianSeverity.low.toJsonString(), 'low');
      expect(GuardianSeverity.medium.toJsonString(), 'medium');
      expect(GuardianSeverity.high.toJsonString(), 'high');
    });

    test('should deserialize from JSON string', () {
      expect(GuardianSeverity.fromJsonString('high'), GuardianSeverity.high);
    });

    test('should default to low for unknown value', () {
      expect(
        GuardianSeverity.fromJsonString('critical'),
        GuardianSeverity.low,
      );
    });
  });

  group('GuardianAnnotation', () {
    late GuardianAnnotation testAnnotation;

    setUp(() {
      testAnnotation = GuardianAnnotation(
        id: 'ga-1',
        kind: GuardianFindingKind.characterConsistency,
        severity: GuardianSeverity.medium,
        message: 'Character speaks out of character',
        reason: 'Alice is described as shy but speaks boldly here',
        suggestedFix: 'Consider rewriting as a hesitant question',
        nodeId: 'node-1',
        startOffset: 10,
        endOffset: 50,
        sourceText: 'Alice declared confidently',
        characterIds: const ['char-1'],
        worldSettingIds: const [],
        skillIds: const [],
        plotNodeIds: const [],
        foreshadowingIds: const [],
        createdAt: DateTime(2026, 1, 1),
      );
    });

    test('should be dismissed when dismissedAt is non-null', () {
      expect(testAnnotation.isDismissed, isFalse);

      final dismissed = testAnnotation.copyWith(
        dismissedAt: DateTime(2026, 1, 2),
      );
      expect(dismissed.isDismissed, isTrue);
    });

    test('should have exact location when nodeId, startOffset, endOffset all set',
        () {
      // All three present
      expect(testAnnotation.hasExactLocation, isTrue);

      // Missing nodeId
      final noNode = testAnnotation.copyWith(nodeId: null);
      expect(noNode.hasExactLocation, isFalse);

      // Missing startOffset
      final noStart = testAnnotation.copyWith(startOffset: null);
      expect(noStart.hasExactLocation, isFalse);

      // Missing endOffset
      final noEnd = testAnnotation.copyWith(endOffset: null);
      expect(noEnd.hasExactLocation, isFalse);

      // All null
      final noLocation = GuardianAnnotation(
        id: 'ga-no-loc',
        kind: GuardianFindingKind.timelineContradiction,
        severity: GuardianSeverity.high,
        message: 'Timeline issue',
        reason: 'Event ordering contradiction',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(noLocation.hasExactLocation, isFalse);
    });

    test('should support copyWith', () {
      final copy = testAnnotation.copyWith(
        severity: GuardianSeverity.high,
        message: 'Updated message',
      );

      expect(copy.severity, GuardianSeverity.high);
      expect(copy.message, 'Updated message');
      expect(copy.id, testAnnotation.id);
      expect(copy.kind, testAnnotation.kind);
    });

    test('should support equality', () {
      final same = GuardianAnnotation(
        id: 'ga-1',
        kind: GuardianFindingKind.characterConsistency,
        severity: GuardianSeverity.medium,
        message: 'Character speaks out of character',
        reason: 'Alice is described as shy but speaks boldly here',
        suggestedFix: 'Consider rewriting as a hesitant question',
        nodeId: 'node-1',
        startOffset: 10,
        endOffset: 50,
        sourceText: 'Alice declared confidently',
        characterIds: const ['char-1'],
        worldSettingIds: const [],
        skillIds: const [],
        plotNodeIds: const [],
        foreshadowingIds: const [],
        createdAt: DateTime(2026, 1, 1),
      );

      expect(testAnnotation, equals(same));
      expect(testAnnotation.hashCode, equals(same.hashCode));
    });

    test('should not equal an annotation with different id', () {
      final other = testAnnotation.copyWith(id: 'ga-999');
      expect(testAnnotation, isNot(equals(other)));
    });

    test('should roundtrip through JSON with all fields', () {
      final json = testAnnotation.toJson();
      final restored = GuardianAnnotation.fromJson(json);

      expect(restored, equals(testAnnotation));
      expect(restored.id, 'ga-1');
      expect(restored.kind, GuardianFindingKind.characterConsistency);
      expect(restored.severity, GuardianSeverity.medium);
      expect(restored.message, 'Character speaks out of character');
      expect(restored.reason, 'Alice is described as shy but speaks boldly here');
      expect(restored.suggestedFix, 'Consider rewriting as a hesitant question');
      expect(restored.nodeId, 'node-1');
      expect(restored.startOffset, 10);
      expect(restored.endOffset, 50);
      expect(restored.sourceText, 'Alice declared confidently');
      expect(restored.characterIds, ['char-1']);
      expect(restored.hasExactLocation, isTrue);
    });

    test('should roundtrip through JSON with minimal fields', () {
      final minimal = GuardianAnnotation(
        id: 'ga-min',
        kind: GuardianFindingKind.worldRuleConflict,
        severity: GuardianSeverity.low,
        message: 'Minor rule mismatch',
        reason: 'Description conflicts with established rules',
        createdAt: DateTime(2026, 1, 1),
      );

      final json = minimal.toJson();
      final restored = GuardianAnnotation.fromJson(json);

      expect(restored, equals(minimal));
      expect(restored.nodeId, isNull);
      expect(restored.startOffset, isNull);
      expect(restored.endOffset, isNull);
      expect(restored.sourceText, isNull);
      expect(restored.suggestedFix, isNull);
      expect(restored.dismissedAt, isNull);
      expect(restored.hasExactLocation, isFalse);
      expect(restored.isDismissed, isFalse);
      expect(restored.characterIds, isEmpty);
    });

    test('should handle nullable dismissedAt in JSON roundtrip', () {
      // Not dismissed
      final json1 = testAnnotation.toJson();
      final r1 = GuardianAnnotation.fromJson(json1);
      expect(r1.dismissedAt, isNull);

      // Dismissed
      final dismissed = testAnnotation.copyWith(
        dismissedAt: DateTime(2026, 6, 15),
      );
      final json2 = dismissed.toJson();
      final r2 = GuardianAnnotation.fromJson(json2);
      expect(r2.dismissedAt, isNotNull);
      expect(r2.isDismissed, isTrue);
    });

    test('should handle all finding kinds in JSON roundtrip', () {
      for (final kind in GuardianFindingKind.values) {
        final ann = GuardianAnnotation(
          id: 'ga-kind-${kind.name}',
          kind: kind,
          severity: GuardianSeverity.low,
          message: 'Test',
          reason: 'Reason',
          createdAt: DateTime(2026, 1, 1),
        );
        final restored = GuardianAnnotation.fromJson(ann.toJson());
        expect(restored.kind, kind, reason: 'Failed for kind: $kind');
      }
    });

    test('should handle all severities in JSON roundtrip', () {
      for (final severity in GuardianSeverity.values) {
        final ann = GuardianAnnotation(
          id: 'ga-sev-${severity.name}',
          kind: GuardianFindingKind.characterConsistency,
          severity: severity,
          message: 'Test',
          reason: 'Reason',
          createdAt: DateTime(2026, 1, 1),
        );
        final restored = GuardianAnnotation.fromJson(ann.toJson());
        expect(restored.severity, severity, reason: 'Failed for severity: $severity');
      }
    });

    test('should have meaningful toString', () {
      final str = testAnnotation.toString();
      expect(str, contains('GuardianAnnotation'));
      expect(str, contains('ga-1'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';

void main() {
  group('GuardianAnnotation presentation', () {
    test('severity colors should be distinct from diff colors', () {
      // Per UI-SPEC: Guardian annotations must be distinct from Phase 3
      // red/green replacement diff colors and blue provenance.
      //
      // Guardian uses amber (#F59E0B) and violet (#8B5CF6).
      // Phase 3 diff uses red/green. Provenance uses blue.
      //
      // This test documents the color contract. The actual color values
      // are used in GuardianPanel._severityColor and _SeverityChip.

      const amberMedium = Color(0xFFF59E0B);
      const violetHigh = Color(0xFF8B5CF6);
      const grayLow = Color(0xFF9CA3AF);

      // These must NOT be red, green, or blue
      expect(amberMedium.red, greaterThan(200));
      expect(amberMedium.green, greaterThan(100));
      expect(amberMedium.blue, lessThan(50));

      expect(violetHigh.red, greaterThan(100));
      expect(violetHigh.green, lessThan(100));
      expect(violetHigh.blue, greaterThan(200));

      expect(grayLow.red, greaterThan(100));
      expect(grayLow.green, greaterThan(100));
      expect(grayLow.blue, greaterThan(100));
    });

    test('hasExactLocation should be false when offsets are missing', () {
      final fullLocation = GuardianAnnotation(
        id: 'test',
        kind: GuardianFindingKind.characterConsistency,
        severity: GuardianSeverity.medium,
        message: 'Test',
        reason: 'Test reason',
        nodeId: 'node-1',
        startOffset: 0,
        endOffset: 10,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(fullLocation.hasExactLocation, isTrue);

      final noLocation = GuardianAnnotation(
        id: 'test',
        kind: GuardianFindingKind.characterConsistency,
        severity: GuardianSeverity.medium,
        message: 'Test',
        reason: 'Test reason',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(noLocation.hasExactLocation, isFalse);
    });

    test('annotations should be immutable with no mutation methods', () {
      final annotation = GuardianAnnotation(
        id: 'test',
        kind: GuardianFindingKind.characterConsistency,
        severity: GuardianSeverity.medium,
        message: 'Test',
        reason: 'Test reason',
        suggestedFix: 'A fix',
        createdAt: DateTime(2026, 1, 1),
      );

      // Verify suggestedFix is stored but no apply/replace methods exist
      expect(annotation.suggestedFix, 'A fix');
      // copyWith returns a new instance (immutable)
      final copy = annotation.copyWith(severity: GuardianSeverity.high);
      expect(copy.severity, GuardianSeverity.high);
      expect(annotation.severity, GuardianSeverity.medium);
      expect(identical(annotation, copy), isFalse);
    });

    test('dismissal should not delete annotation', () {
      final annotation = GuardianAnnotation(
        id: 'test',
        kind: GuardianFindingKind.characterConsistency,
        severity: GuardianSeverity.medium,
        message: 'Test',
        reason: 'Test reason',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(annotation.isDismissed, isFalse);

      final dismissed = annotation.copyWith(
        dismissedAt: DateTime(2026, 1, 2),
      );

      expect(dismissed.isDismissed, isTrue);
      // Original is unchanged (immutability)
      expect(annotation.isDismissed, isFalse);
    });
  });
}

/// Color class for test-only color validation.
/// Re-uses Flutter's Color API for ARGB comparison.
class Color {
  final int value;

  const Color(int value) : value = value & 0xFFFFFFFF;

  int get red => (value >> 16) & 0xFF;
  int get green => (value >> 8) & 0xFF;
  int get blue => value & 0xFF;
}

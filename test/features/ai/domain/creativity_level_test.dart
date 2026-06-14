/// Tests for [CreativityLevel] — AA-03 user-facing creativity dimension.
///
/// Validates the three-level creativity mapping to sampling temperature
/// (conservative 0.6 / balanced 0.8 default / expressive 0.95), per
/// TempParaphraser (Huang et al., EMNLP 2025) which showed higher sampling
/// temperature reduces AI-text detection rate by up to 82.5%.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/domain/creativity_level.dart';

void main() {
  group('CreativityLevel AA-03 temperature mapping', () {
    test('conservative maps to 0.6 temperature', () {
      expect(CreativityLevel.conservative.temperature, 0.6);
    });

    test('balanced maps to 0.8 temperature (the default)', () {
      expect(CreativityLevel.balanced.temperature, 0.8);
    });

    test('expressive maps to 0.95 temperature', () {
      expect(CreativityLevel.expressive.temperature, 0.95);
    });

    test('higher creativity never exceeds 1.0 (stays coherent)', () {
      // Per AA-03: keep expressive below 1.0 to preserve coherence while
      // raising diversity above the AI-default 0.7 sweet spot.
      for (final level in CreativityLevel.values) {
        expect(level.temperature, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('CreativityLevel labels', () {
    test('exposes Chinese display labels', () {
      expect(CreativityLevel.conservative.label, '保守');
      expect(CreativityLevel.balanced.label, '平衡');
      expect(CreativityLevel.expressive.label, '灵动');
    });
  });

  group('CreativityLevel JSON round-trip', () {
    test('toJson returns the enum name', () {
      expect(CreativityLevel.conservative.toJson(), 'conservative');
      expect(CreativityLevel.balanced.toJson(), 'balanced');
      expect(CreativityLevel.expressive.toJson(), 'expressive');
    });

    test('fromJson round-trips every level', () {
      for (final level in CreativityLevel.values) {
        expect(CreativityLevel.fromJson(level.toJson()), level);
      }
    });

    test('fromJson(null) falls back to balanced (safe default)', () {
      expect(CreativityLevel.fromJson(null), CreativityLevel.balanced);
    });

    test('fromJson(garbage) falls back to balanced (safe default)', () {
      // Unknown persisted values (e.g. from a future version) must not crash.
      expect(CreativityLevel.fromJson('超凡'), CreativityLevel.balanced);
      expect(CreativityLevel.fromJson(''), CreativityLevel.balanced);
    });
  });
}

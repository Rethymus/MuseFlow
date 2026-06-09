import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';

void main() {
  group('OpeningVariantStyle', () {
    test('should have exactly 3 values', () {
      expect(OpeningVariantStyle.values, hasLength(3));
    });

    test('should have correct storage values', () {
      expect(OpeningVariantStyle.scene.value, 'scene');
      expect(OpeningVariantStyle.character.value, 'character');
      expect(OpeningVariantStyle.suspense.value, 'suspense');
    });

    test('should return correct display labels', () {
      expect(OpeningVariantStyle.scene.displayLabel, '场景切入');
      expect(OpeningVariantStyle.character.displayLabel, '人物切入');
      expect(OpeningVariantStyle.suspense.displayLabel, '悬念切入');
    });

    test('should parse from string correctly', () {
      expect(
        OpeningVariantStyle.fromString('scene'),
        OpeningVariantStyle.scene,
      );
      expect(
        OpeningVariantStyle.fromString('character'),
        OpeningVariantStyle.character,
      );
      expect(
        OpeningVariantStyle.fromString('suspense'),
        OpeningVariantStyle.suspense,
      );
    });

    test('should throw ArgumentError for unknown style string', () {
      expect(
        () => OpeningVariantStyle.fromString('unknown'),
        throwsArgumentError,
      );
    });
  });

  group('OpeningVariant', () {
    test('should create with required fields', () {
      const variant = OpeningVariant(
        style: OpeningVariantStyle.scene,
        text: '夜色笼罩着古老的城墙',
      );

      expect(variant.style, OpeningVariantStyle.scene);
      expect(variant.text, '夜色笼罩着古老的城墙');
    });

    test('should serialize to JSON correctly', () {
      const variant = OpeningVariant(
        style: OpeningVariantStyle.character,
        text: '他缓缓睁开双眼',
      );

      final json = variant.toJson();

      expect(json, {'style': 'character', 'text': '他缓缓睁开双眼'});
    });

    test('should deserialize from JSON correctly', () {
      final variant = OpeningVariant.fromJson({
        'style': 'suspense',
        'text': '谁在黑暗中窥视着这一切？',
      });

      expect(variant.style, OpeningVariantStyle.suspense);
      expect(variant.text, '谁在黑暗中窥视着这一切？');
    });

    test('should roundtrip through JSON serialization', () {
      const original = OpeningVariant(
        style: OpeningVariantStyle.scene,
        text: '测试场景开篇文本',
      );

      final json = original.toJson();
      final restored = OpeningVariant.fromJson(json);

      expect(restored.style, original.style);
      expect(restored.text, original.text);
    });

    test('should support equality comparison', () {
      const a = OpeningVariant(style: OpeningVariantStyle.scene, text: '相同的文本');
      const b = OpeningVariant(style: OpeningVariantStyle.scene, text: '相同的文本');
      const c = OpeningVariant(style: OpeningVariantStyle.scene, text: '不同的文本');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('should throw ArgumentError when fromJson receives unknown style', () {
      expect(
        () => OpeningVariant.fromJson({
          'style': 'nonexistent',
          'text': 'some text',
        }),
        throwsArgumentError,
      );
    });
  });
}

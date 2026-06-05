import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';
import 'package:museflow/features/onboarding/presentation/opening_variant_card.dart';

void main() {
  group('OpeningVariantCard', () {
    const variant = OpeningVariant(
      style: OpeningVariantStyle.scene,
      text: '雨水沿着青石街一路漫过门槛，旧灯笼在风里轻轻晃动。',
    );

    testWidgets('displays style badge and text preview', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpeningVariantCard(variant: variant, onSelect: () {}),
          ),
        ),
      );

      expect(find.text('场景切入'), findsOneWidget);
      expect(find.text(variant.text), findsOneWidget);
      expect(find.text('使用此开篇'), findsOneWidget);
    });

    testWidgets('calls onSelect when card is tapped', (tester) async {
      var selected = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpeningVariantCard(
              variant: variant,
              onSelect: () => selected = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OpeningVariantCard));
      expect(selected, isTrue);
    });

    testWidgets('shows filled button when selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpeningVariantCard(
              variant: variant,
              isSelected: true,
              onSelect: () {},
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}

/// Pins the material system's parameters so "Apple style" is an enforced
/// contract, not prose: blur sigmas per tier, tint bases/opacities per
/// mode, the neutral elevation ramp direction, inner highlights, hairline
/// borders, and the focus ring.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/theme/app_materials.dart';
import 'package:museflow/shared/theme/app_theme.dart';

void main() {
  group('AppMaterialTier parameters', () {
    test('blur sigma decreases as the tier thickens', () {
      expect(AppMaterialTier.ultraThin.sigma, 30);
      expect(AppMaterialTier.thin.sigma, 24);
      expect(AppMaterialTier.regular.sigma, 18);
      expect(AppMaterialTier.thick.sigma, 10);
      expect(
        AppMaterialTier.ultraThin.sigma,
        greaterThan(AppMaterialTier.thick.sigma),
      );
    });

    test('tint opacity increases as the tier thickens (both modes)', () {
      for (final p in [lightPalette, darkPalette]) {
        expect(
          p == lightPalette ? 'light' : 'dark',
          isNotEmpty,
        ); // label the loop
        expect(
          AppMaterialTier.ultraThin.tintOpacityOn(p),
          lessThan(AppMaterialTier.thin.tintOpacityOn(p)),
        );
        expect(
          AppMaterialTier.thin.tintOpacityOn(p),
          lessThan(AppMaterialTier.regular.tintOpacityOn(p)),
        );
        expect(
          AppMaterialTier.regular.tintOpacityOn(p),
          lessThan(AppMaterialTier.thick.tintOpacityOn(p)),
        );
        // Glass must stay translucent: even the thickest tier keeps some
        // transparency for the sampled blur to read through.
        expect(AppMaterialTier.thick.tintOpacityOn(p), lessThan(1.0));
        expect(AppMaterialTier.thick.tintOpacityOn(p), greaterThan(0.85));
      }
    });

    test('tint base is white-dominant in light, near-black in dark', () {
      expect(AppMaterialTier.regular.tintBaseOn(lightPalette), Colors.white);
      expect(
        AppMaterialTier.regular.tintBaseOn(darkPalette),
        darkPalette.gray6,
      );
    });

    test('inner highlight is brighter in light mode than dark', () {
      expect(
        AppMaterialTier.regular.highlightAlphaOn(lightPalette),
        greaterThan(AppMaterialTier.regular.highlightAlphaOn(darkPalette)),
      );
    });
  });

  group('AppElevation neutral ramp', () {
    test('light mode raises toward white', () {
      final base = AppElevation.base.on(lightPalette);
      final raised = AppElevation.raised.on(lightPalette);
      final modal = AppElevation.modal.on(lightPalette);
      expect(_luminance(base), lessThan(_luminance(raised)));
      expect(raised, modal); // white at the top of the light ramp
    });

    test('dark mode raises toward lighter gray, monotonically', () {
      final values = [
        AppElevation.base.on(darkPalette),
        AppElevation.raised.on(darkPalette),
        AppElevation.floating.on(darkPalette),
        AppElevation.modal.on(darkPalette),
      ];
      for (var i = 1; i < values.length; i++) {
        expect(
          _luminance(values[i]),
          greaterThan(_luminance(values[i - 1])),
          reason: 'dark elevation step $i must lighten',
        );
      }
      expect(values.first, Colors.black);
    });
  });

  group('AppMaterial widget', () {
    Widget wrap(Widget child, Brightness brightness) => MaterialApp(
      theme: appTheme(brightness),
      home: Scaffold(body: Center(child: child)),
    );

    testWidgets('composes blur + tint + inner highlight + hairline', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const AppMaterial(
            tier: AppMaterialTier.thin,
            child: SizedBox(width: 100, height: 100),
          ),
          Brightness.light,
        ),
      );

      // Real screen-sampling blur present with the tier's sigma.
      final blur = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      expect(
        blur.filter.toString(),
        contains(AppMaterialTier.thin.sigma.toString()),
        reason: 'blur filter must use the thin tier sigma',
      );

      // The tint container carries the semi-transparent white wash and the
      // white top rim (inner highlight).
      final decorated = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .toList();
      final tints = decorated
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color != null && d.color!.a < 1.0)
          .toList();
      expect(tints, isNotEmpty);
      final tint = tints.first.color!;
      expect(
        tint.a,
        closeTo(AppMaterialTier.thin.tintOpacityOn(lightPalette), 0.01),
      );

      // Inner highlight: a hairline top overlay with a white gradient rim.
      final rim = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).gradient is LinearGradient,
          )
          .first;
      final gradient = (rim.decoration! as BoxDecoration).gradient!;
      expect(
        gradient.colors.first,
        Colors.white.withValues(
          alpha: AppMaterialTier.thin.highlightAlphaOn(lightPalette) * 0.35,
        ),
      );
    });

    testWidgets('dark mode tint base switches to near-black', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppMaterial(
            tier: AppMaterialTier.ultraThin,
            child: SizedBox(width: 100, height: 100),
          ),
          Brightness.dark,
        ),
      );

      final tints = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color != null && d.color!.a < 1.0)
          .toList();
      final tint = tints.first.color!;
      // White tint would have r=g=b=1; dark tint is the gray6 base.
      expect((tint.r * 255).round(), lessThan(60));
    });

    testWidgets('hairline edges only where requested', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppMaterial(
            tier: AppMaterialTier.thin,
            borderEdges: {LogicalEdge.right},
            child: SizedBox(width: 100, height: 100),
          ),
          Brightness.light,
        ),
      );

      // Hairline overlays are Containers painted in the separator color
      // (raw color param → ColoredBox inside, exposed via Container.color).
      final separatorHairlines = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (c) =>
                c.color == lightPalette.separator ||
                (c.decoration is BoxDecoration &&
                    (c.decoration! as BoxDecoration).color ==
                        lightPalette.separator),
          )
          .length;

      // Exactly one hairline (right edge); the top carries the white rim
      // instead and left/bottom carry none.
      expect(separatorHairlines, equals(1));
    });
  });

  group('AppScrollEdge (scroll edge effect)', () {
    test('offset maps to 0..1 within 100px', () {
      final edge = AppScrollEdge();
      edge.updateFromOffset(0);
      expect(edge.value, 0.0);
      edge.updateFromOffset(50);
      expect(edge.value, closeTo(0.5, 0.001));
      edge.updateFromOffset(400);
      expect(edge.value, 1.0);
    });

    testWidgets('tint strengthens while content scrolls beneath', (
      tester,
    ) async {
      final edge = AppScrollEdge();
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: Scaffold(
            body: Center(
              child: AppMaterial(
                tier: AppMaterialTier.ultraThin,
                scrollEdge: edge,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      Color tintAt() => tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color != null && d.color!.a < 1.0)
          .first
          .color!;

      edge.updateFromOffset(0);
      await tester.pumpAndSettle();
      final atRest = tintAt();

      edge.updateFromOffset(100);
      await tester.pumpAndSettle();
      final scrolled = tintAt();

      // The scrolled tint is strictly more opaque (the legibility ramp).
      expect(scrolled.a, greaterThan(atRest.a));
      final expected =
          AppMaterialTier.ultraThin.tintOpacityOn(lightPalette) + 0.25;
      expect(scrolled.a, closeTo(expected, 0.01));
    });
  });

  group('AppFocusRing', () {
    testWidgets('shows the accent ring when a descendant is focused', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: Scaffold(
            body: Center(
              child: AppFocusRing(
                child: TextButton(
                  focusNode: focusNode,
                  onPressed: () {},
                  child: const Text('聚焦我'),
                ),
              ),
            ),
          ),
        ),
      );

      // Ring layer hidden before focus.
      expect(_ringDecorations(tester), isEmpty);

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      // Ring layer visible: a fully-transparent container carrying an
      // accent border + glow.
      final rings = _ringDecorations(tester);
      expect(rings, isNotEmpty);
      final border = rings.first.border as Border;
      expect(border.top.color, lightPalette.accent);
    });

    testWidgets('disabled ring never renders', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: Scaffold(
            body: Center(
              child: AppFocusRing(
                enabled: false,
                child: TextButton(
                  focusNode: focusNode,
                  onPressed: () {},
                  child: const Text('不会出现环'),
                ),
              ),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(_ringDecorations(tester), isEmpty);
    });
  });
}

double _luminance(Color c) => c.computeLuminance();

List<BoxDecoration> _ringDecorations(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((d) => d.decoration)
    .whereType<BoxDecoration>()
    .where((d) => d.color == null && d.border is Border)
    .toList();

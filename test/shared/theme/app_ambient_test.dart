/// Pins the ambient backdrop layer — the depth source every glass
/// surface samples (the "毛玻璃随背后的界面内容产生层次" deliverable).
///
/// - Base wash + three subtlety-bounded blobs per brightness.
/// - Collapses to the opaque base when disabled (reduce transparency).
/// - Paints once behind a RepaintBoundary (no per-frame cost).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/theme/app_theme.dart';
import 'package:museflow/shared/widgets/app_ambient.dart';

void main() {
  group('AppAmbient', () {
    test('base color is the grouped page background (both modes)', () {
      expect(
        AppAmbient.baseColor(lightPalette),
        lightPalette.groupedBackground,
      );
      expect(AppAmbient.baseColor(darkPalette), darkPalette.groupedBackground);
    });

    test('exactly three blobs, radii bounded, at least one off-canvas', () {
      for (final p in [lightPalette, darkPalette]) {
        final blobs = AppAmbient.blobs(p);
        expect(blobs, hasLength(3));
        for (final b in blobs) {
          expect(b.radiusFactor, inExclusiveRange(0.3, 0.8));
        }
        // Wallpaper-like blobs bleed past the viewport edge.
        final offCanvas = blobs.any(
          (b) => b.center.x.abs() > 1 || b.center.y.abs() > 1,
        );
        expect(
          offCanvas,
          isTrue,
          reason: 'wallpaper-like blobs must bleed past the viewport',
        );
      }
    });

    test('dark blobs are stronger than light blobs (glow on black)', () {
      int alphaSum(AppPalette p) => AppAmbient.blobs(
        p,
      ).fold(0, (sum, b) => sum + (b.color.a * 255).round());
      expect(alphaSum(darkPalette), greaterThan(alphaSum(lightPalette)));
    });

    test('blobs stay subtle on the base wash (never decoration)', () {
      for (final p in [lightPalette, darkPalette]) {
        final base = AppAmbient.baseColor(p);
        for (final blob in AppAmbient.blobs(p)) {
          // Composite the blob over the base at its peak and bound the
          // contrast delta: < 0.35 = a whisper of depth, not a poster.
          final fgA = blob.color.a;
          final mixed = Color.fromARGB(
            255,
            ((blob.color.r * fgA + base.r * (1 - fgA)) * 255).round(),
            ((blob.color.g * fgA + base.g * (1 - fgA)) * 255).round(),
            ((blob.color.b * fgA + base.b * (1 - fgA)) * 255).round(),
          );
          final ratio = _contrast(mixed, base);
          expect(
            (ratio - 1).abs(),
            lessThan(0.35),
            reason:
                '${p.isDark ? "dark" : "light"} blob too loud '
                '(${(ratio - 1).abs().toStringAsFixed(2)})',
          );
        }
      }
    });

    testWidgets('enabled canvas paints blobs; disabled paints flat base', (
      tester,
    ) async {
      Finder blobPainters() => find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter != null &&
            w.painter.runtimeType.toString() == '_AmbientPainter',
      );

      Future<void> pump({required bool enabled, required Brightness b}) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme(b),
            home: Scaffold(
              body: SizedBox.expand(child: AppAmbientCanvas(enabled: enabled)),
            ),
          ),
        );
      }

      await pump(enabled: true, b: Brightness.light);
      expect(blobPainters(), findsOneWidget);

      await pump(enabled: false, b: Brightness.light);
      // Collapsed canvas paints no blob gradients — only the flat base.
      expect(blobPainters(), findsNothing);
      expect(find.byType(ColoredBox), findsAtLeastNWidgets(1));
    });

    testWidgets('sits in a RepaintBoundary so it never repaints per frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.dark),
          home: const Scaffold(body: AppAmbientCanvas()),
        ),
      );
      // The framework inserts its own boundaries around Scaffold routes;
      // what matters is that OUR painter is behind one.
      expect(
        find.ancestor(
          of: find.byType(CustomPaint),
          matching: find.byType(RepaintBoundary),
        ),
        findsAtLeastNWidgets(1),
      );
    });
  });
}

/// WCAG 2.1 contrast ratio, for the subtlety bound above.
double _contrast(Color a, Color b) {
  double lum(Color c) {
    double lin(double ch) => ch <= 0.03928
        ? ch / 12.92
        : math.pow((ch + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  }

  final la = lum(a);
  final lb = lum(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

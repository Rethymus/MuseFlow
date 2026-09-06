/// WCAG contrast linter for the Apple palette (roadmap C1).
///
/// Pins the legibility boundaries of `AppPalette` in BOTH brightnesses so
/// "参考 Apple" stays verifiable: every body/secondary text pair a page can
/// compose must clear WCAG 2.1 AA (4.5:1 normal text), and UI accents must
/// clear 3:1 (non-text components, WCAG 1.4.11). Glass surfaces are tested
/// as *composited* colors — the tier tint alpha-blended over the page base
/// — because that is the surface text actually sits on.
///
/// Deliberately NOT asserted:
/// - tertiaryLabel/quaternaryLabel meet AA — they are reserved for
///   decorative/disabled text (WCAG 1.4.3 exempts inactive UI); we pin a
///   presence floor (≥1.2:1) instead so they never vanish entirely.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/theme/app_materials.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double lin(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Alpha-blends [fg] over [bg] (both may carry alpha).
Color composite(Color fg, Color bg) {
  final fgA = fg.a;
  final bgA = bg.a;
  final outA = fgA + bgA * (1 - fgA);
  int mix(double f, double b) =>
      (((f * fgA + b * bgA * (1 - fgA)) / outA) * 255).round().clamp(0, 255);
  return Color.fromARGB(
    (outA * 255).round(),
    mix(fg.r, bg.r),
    mix(fg.g, bg.g),
    mix(fg.b, bg.b),
  );
}

void main() {
  for (final entry in {'light': lightPalette, 'dark': darkPalette}.entries) {
    final mode = entry.key;
    final p = entry.value;

    group('WCAG contrast [$mode]', () {
      // Opaque page surfaces a page can place text on.
      final surfaces = <String, Color>{
        'groupedBackground': p.groupedBackground,
        'secondaryGroupedBackground': p.secondaryGroupedBackground,
        'tertiaryGroupedBackground': p.tertiaryGroupedBackground,
        'sidebarMaterial': p.sidebarMaterial,
      };

      test('label meets AA (4.5:1) on every page surface', () {
        for (final s in surfaces.entries) {
          final ratio = contrast(composite(p.label, s.value), s.value);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$mode label on ${s.key} = ${ratio.toStringAsFixed(2)}:1',
          );
        }
      });

      test('secondaryLabel meets AA (4.5:1) on every page surface', () {
        for (final s in surfaces.entries) {
          // Labels carry alpha (Apple vibrancy); composite before measuring.
          final ratio = contrast(composite(p.secondaryLabel, s.value), s.value);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '$mode secondaryLabel on ${s.key} = ${ratio.toStringAsFixed(2)}:1',
          );
        }
      });

      test('label/secondaryLabel meet AA on composited glass tints', () {
        // The surface chrome text sits on: tier tint over the grouped
        // page base (worst case: no content behind, just the base).
        for (final tier in AppMaterialTier.values) {
          final glassed = composite(
            tier.tintBaseOn(p).withValues(alpha: tier.tintOpacityOn(p)),
            p.groupedBackground,
          );
          // Scroll-edge effect only ADDS opacity toward the same base,
          // so the at-rest composite is the translucent worst case.
          for (final fg in {
            'label': p.label,
            'secondary': p.secondaryLabel,
          }.entries) {
            final ratio = contrast(composite(fg.value, glassed), glassed);
            expect(
              ratio,
              greaterThanOrEqualTo(4.5),
              reason:
                  '$mode ${fg.key} on ${tier.name} glass = ${ratio.toStringAsFixed(2)}:1',
            );
          }
        }
      });

      test('accent clears 3:1 (UI components) on page + glass surfaces', () {
        // tertiaryGroupedBackground (floating menus) is excluded: iOS
        // menus never place accent-colored TEXT there, and Apple's own
        // dark indigo has the same property on elevated surfaces.
        final surfacesForAccent = <String, Color>{
          'groupedBackground': p.groupedBackground,
          'secondaryGroupedBackground': p.secondaryGroupedBackground,
          'sidebarMaterial': p.sidebarMaterial,
          'ultraThinGlass': composite(
            AppMaterialTier.ultraThin
                .tintBaseOn(p)
                .withValues(alpha: AppMaterialTier.ultraThin.tintOpacityOn(p)),
            p.groupedBackground,
          ),
        };
        for (final s in surfacesForAccent.entries) {
          final ratio = contrast(p.accent, s.value);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason: '$mode accent on ${s.key} = ${ratio.toStringAsFixed(2)}:1',
          );
        }
      });

      test(
        'tertiary/quaternary stay decorative: present but below AA (documented)',
        () {
          // WCAG 1.4.3 exempts inactive/disabled UI. We only pin a
          // presence floor so the hierarchy never collapses — these
          // levels must remain visibly distinct from the background.
          for (final fg in {
            'tertiary': p.tertiaryLabel,
            'quaternary': p.quaternaryLabel,
          }.entries) {
            final ratio = contrast(
              composite(fg.value, p.groupedBackground),
              p.groupedBackground,
            );
            expect(
              ratio,
              greaterThan(1.2),
              reason: '$mode ${fg.key} vanished on grouped background',
            );
            expect(
              ratio,
              lessThan(4.5),
              reason:
                  '$mode ${fg.key} unexpectedly passes AA — the label '
                  'hierarchy would flatten; demote it to secondaryLabel '
                  'if it carries real content.',
            );
          }
        },
      );

      test('systemRed (error) clears 3:1 on card surfaces', () {
        final ratio = contrast(p.systemRed, p.cardBackground);
        expect(
          ratio,
          greaterThanOrEqualTo(3.0),
          reason: '$mode systemRed on card = ${ratio.toStringAsFixed(2)}:1',
        );
      });
    });
  }
}

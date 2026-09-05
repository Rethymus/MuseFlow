/// Pins the Apple motion system's math and presets so the "silky, damped"
/// feel is an enforced contract (see docs/design/apple-motion-research.md):
/// spring parameter conversion, preset values, press-feedback behavior,
/// and scroll physics.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/shared/theme/app_motion.dart';
import 'package:museflow/shared/theme/apple_scroll_behavior.dart';
import 'package:museflow/shared/theme/app_theme.dart';
import 'package:museflow/shared/widgets/app_pressable.dart';

void main() {
  group('AppleMotion presets match SwiftUI defaults', () {
    test('.spring() default = response 0.5 / dampingFraction 0.825', () {
      expect(AppleMotion.defaultResponse, 0.5);
      expect(AppleMotion.defaultDampingFraction, 0.825);
    });

    test('.smooth = 0.5s, critically damped (no overshoot)', () {
      expect(AppleMotion.smoothResponse, 0.5);
      expect(AppleMotion.smoothDampingFraction, 1.0);
    });

    test('.snappy = 0.3s with small bounce', () {
      expect(AppleMotion.snappyResponse, 0.3);
      expect(AppleMotion.snappyDampingFraction, lessThan(1.0));
      expect(AppleMotion.snappyDampingFraction, greaterThan(0.4));
    });

    test('.bouncy bounces more than .snappy', () {
      expect(
        AppleMotion.bouncyDampingFraction,
        lessThan(AppleMotion.snappyDampingFraction),
      );
    });
  });

  group('AppleSprings math', () {
    test('converts (response, dampingFraction) to stiffness/damping', () {
      final spring = AppleSprings.description(0.5, 0.825);
      // ω = 2π/0.5 = 4π;  stiffness = ω² ≈ 157.91;  damping = 2·0.825·ω ≈ 20.73
      expect(spring.stiffness, closeTo(157.91, 0.01));
      expect(spring.damping, closeTo(20.73, 0.01));
      expect(spring.mass, 1.0);
    });

    test('critically damped spring never overshoots its target', () {
      final sim = AppleSprings.smooth(1.0, velocity: 0);
      var max = 0.0;
      for (var t = 0.0; t < 3; t += 0.016) {
        final x = sim.x(t);
        if (x > max) max = x;
      }
      expect(max, lessThan(1.0001), reason: 'ζ=1.0 must not overshoot');
    });

    test('snappy spring overshoots slightly (the tactile signature)', () {
      final sim = AppleSprings.snappy(1.0, velocity: 0);
      var max = 0.0;
      for (var t = 0.0; t < 2; t += 0.008) {
        final x = sim.x(t);
        if (x > max) max = x;
      }
      expect(max, greaterThan(1.0), reason: 'ζ<1 must overshoot');
      // ζ=0.65 → overshoot = exp(−ζπ/√(1−ζ²)) ≈ 6.8%: visible but light.
      expect(max, lessThan(1.08), reason: 'overshoot stays light (<8%)');
    });
  });

  group('AppPressSpec', () {
    test('touch press is stronger than pointer press', () {
      expect(AppPressSpec.touchScale, 0.97);
      expect(AppPressSpec.pointerScale, greaterThan(AppPressSpec.touchScale));
      expect(AppPressSpec.pointerScale, lessThanOrEqualTo(1.0));
    });

    test('release uses the snappy spring', () {
      expect(AppPressSpec.releaseResponse, AppleMotion.snappyResponse);
      expect(AppPressSpec.releaseDamping, AppleMotion.snappyDampingFraction);
    });
  });

  group('AppPressable behavior', () {
    Widget wrap(Widget child) => MaterialApp(
      theme: appTheme(Brightness.light),
      home: Scaffold(body: Center(child: child)),
    );

    testWidgets('touch press scales down, release springs back', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          AppPressable(
            onTap: () => taps++,
            child: Container(width: 100, height: 100, color: Colors.grey),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppPressable)),
        kind: PointerDeviceKind.touch,
      );
      await tester.pumpAndSettle();
      _expectScale(tester, closeTo(AppPressSpec.touchScale, 0.01));

      await gesture.up();
      await tester.pumpAndSettle();
      _expectScale(tester, closeTo(1.0, 0.001));
      expect(taps, 1);
    });

    testWidgets('mouse press is subtler than touch', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppPressable(
            child: Container(width: 100, height: 100, color: Colors.grey),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppPressable)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      _expectScale(tester, closeTo(AppPressSpec.pointerScale, 0.01));

      await gesture.up();
      await tester.pumpAndSettle();
      _expectScale(tester, closeTo(1.0, 0.001));
    });
  });

  group('AppleScrollBehavior', () {
    testWidgets('non-mac platforms get bouncing (rubber-band) physics', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          scrollBehavior: const AppleScrollBehavior(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                captured = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(
        const AppleScrollBehavior().getScrollPhysics(captured),
        isA<BouncingScrollPhysics>(),
      );
      expect(
        ScrollConfiguration.of(captured).getScrollPhysics(captured),
        isA<BouncingScrollPhysics>(),
        reason: 'the app behavior must actually reach the scrollables',
      );

      debugDefaultTargetPlatformOverride = null;
    });
  });
}

void _expectScale(WidgetTester tester, Object matcher) {
  final scale = tester
      .widget<ScaleTransition>(
        find.descendant(
          of: find.byType(AppPressable),
          matching: find.byType(ScaleTransition),
        ),
      )
      .scale
      .value;
  expect(scale, matcher);
}

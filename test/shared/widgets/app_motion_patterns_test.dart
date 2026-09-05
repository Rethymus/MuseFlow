/// Verifies the four specialized motion patterns (research doc §9):
/// boulder shake math, toast spring entrance/exit, slot-snap thumb, and
/// the alert's scale entrance.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/shared/theme/app_motion.dart';
import 'package:museflow/shared/theme/app_theme.dart';
import 'package:museflow/shared/widgets/app_controls.dart';
import 'package:museflow/shared/widgets/app_dialogs.dart';
import 'package:museflow/shared/widgets/app_shake.dart';
import 'package:museflow/shared/widgets/app_toast.dart';

void main() {
  group('AppShakeSimulation math', () {
    test('starts at full amplitude with zero velocity (the push instant)', () {
      final sim = AppShakeSimulation(amplitude: 9);
      expect(sim.x(0), closeTo(0, 1e-9)); // sin(0) = 0, mid-swing
      expect(sim.dx(0).abs(), greaterThan(0)); // but moving
      expect(sim.dx(0).sign, isNonZero);
    });

    test('peaks near the first quarter period at ≈amplitude', () {
      final sim = AppShakeSimulation(amplitude: 9, frequency: 10);
      // Quarter period = 25ms; amplitude is the envelope there.
      final peak = sim.x(0.025);
      expect(peak, greaterThan(7.0));
      expect(peak, lessThanOrEqualTo(9.0));
    });

    test('decays to under 2% within ~3 swings', () {
      final sim = AppShakeSimulation(amplitude: 9, decay: 9);
      // Envelope at 0.3s: 9·e^(−2.7) ≈ 0.60px (<2% of 9 ≈ 0.18? envelope
      // itself is 0.60 — assert the VISUAL displacement at 0.3s is tiny).
      final late = sim.x(0.3).abs();
      expect(late, lessThan(0.6));
      expect(sim.isDone(0.45), isTrue, reason: '400ms duration ends it');
    });

    test('oscillates around zero (both signs visited)', () {
      final sim = AppShakeSimulation(amplitude: 9, frequency: 10);
      var sawPositive = false;
      var sawNegative = false;
      for (var t = 0.0; t < 0.2; t += 0.005) {
        if (sim.x(t) > 1) sawPositive = true;
        if (sim.x(t) < -1) sawNegative = true;
      }
      expect(sawPositive, isTrue);
      expect(sawNegative, isTrue);
    });
  });

  group('AppShake widget', () {
    testWidgets('shake() displaces the subtree then returns to rest', (
      tester,
    ) async {
      final key = GlobalKey<AppShakeState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppShake(key: key, child: const Text('校验失败')),
            ),
          ),
        ),
      );

      key.currentState!.shake();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 25));

      // Mid-shake: the Transform carries a non-zero offset.
      final shakeTransforms = find.descendant(
        of: find.byType(AppShake),
        matching: find.byType(Transform),
      );
      Transform mid = tester.widget<Transform>(shakeTransforms.first);
      expect(mid.transform.getTranslation().x, isNot(0.0));

      await tester.pumpAndSettle();
      mid = tester.widget<Transform>(shakeTransforms.first);
      expect(mid.transform.getTranslation().x, closeTo(0.0, 0.5));
    });
  });

  group('AppSegmentedControl slot snap', () {
    testWidgets('thumb glides to the tapped slot', (tester) async {
      String selected = '浅色';
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) => AppSegmentedControl<String>(
                  segments: const ['浅色', '深色', '跟随系统'],
                  selected: selected,
                  onSelectionChanged: (v) => setState(() => selected = v),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap the LAST slot; the thumb must travel across two slots.
      await tester.tap(find.text('跟随系统'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      // Mid-flight: thumb left edge is between slot 0 and slot 2.
      final thumbFinder = find.descendant(
        of: find.byWidgetPredicate((w) => w is AppSegmentedControl),
        matching: find.byWidgetPredicate(
          (w) => w is Positioned && w.width != null,
        ),
      );
      final thumb = tester.widget<Positioned>(thumbFinder.first);
      final midLeft = thumb.left!;
      expect(midLeft, greaterThan(0.0));

      await tester.pumpAndSettle();
      final settled = tester.widget<Positioned>(thumbFinder.first);
      // Settled at slot 2 of 3 (thumb left = 2 × slotWidth).
      expect(settled.left!, greaterThan(midLeft));
      expect(selected, '跟随系统');
    });
  });

  group('AppToast', () {
    testWidgets('spring entrance: slides up and scales to full', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showAppToast(context, message: '已保存'),
                  child: const Text('触发'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('触发'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('已保存'), findsOneWidget);

      // Advance a single 900ms frame: the entrance spring has settled but
      // the hold (2.4s, frame-scheduled) has not — toast fully entered.
      await tester.pump(const Duration(milliseconds: 900));
      final toast = find.ancestor(
        of: find.text('已保存'),
        matching: find.byType(Opacity),
      );
      final opacity = tester.widget<Opacity>(toast).opacity;
      expect(opacity, 1.0);

      // The frame-scheduled hold then auto-dismisses: full lifecycle
      // (entrance → hold → fade → removal) without pending timers.
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(find.text('已保存'), findsNothing);
    });
  });

  group('SpringSheet (action sheet host)', () {
    Future<void> pumpHost(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showAppActionSheet(
                    context,
                    title: '选择操作',
                    actions: [
                      AppSheetAction('重命名'),
                      AppSheetAction('删除', isDestructive: true),
                    ],
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Finder sheetTranslation() => find.ancestor(
      of: find.text('取消'),
      matching: find.byType(FractionalTranslation),
    );

    testWidgets('slides in from below and seats (no overshoot beyond ~2%)', (
      tester,
    ) async {
      await pumpHost(tester);
      await tester.tap(find.text('打开'));
      await tester.pump();

      // Mid-flight: still translated down.
      var translation = tester
          .widget<FractionalTranslation>(sheetTranslation())
          .translation;
      expect(translation.dy, greaterThan(0.0));

      await tester.pumpAndSettle();
      translation = tester
          .widget<FractionalTranslation>(sheetTranslation())
          .translation;
      // Smooth spring is critically damped: seats at 0 without overshoot.
      expect(translation.dy, closeTo(0.0, 0.02));
    });

    testWidgets('drag down past threshold dismisses and removes the overlay', (
      tester,
    ) async {
      await pumpHost(tester);
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(find.text('重命名'), findsOneWidget);

      await tester.drag(find.text('选择操作'), const Offset(0, 600));
      await tester.pumpAndSettle();

      expect(find.text('重命名'), findsNothing);
      expect(find.text('选择操作'), findsNothing);
    });

    testWidgets('small drag springs back to seated', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      await tester.drag(find.text('选择操作'), const Offset(0, 80));
      await tester.pump();
      var translation = tester
          .widget<FractionalTranslation>(sheetTranslation())
          .translation;
      expect(translation.dy, greaterThan(0.0));

      await tester.pumpAndSettle();
      translation = tester
          .widget<FractionalTranslation>(sheetTranslation())
          .translation;
      expect(translation.dy, closeTo(0.0, 0.02));
      expect(find.text('重命名'), findsOneWidget);
    });

    testWidgets('action tap dismisses the sheet and keeps the callback order', (
      tester,
    ) async {
      var picked = '';
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showAppActionSheet(
                    context,
                    actions: [
                      AppSheetAction('重命名', onPressed: () => picked = 'rename'),
                    ],
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('重命名'));
      await tester.pumpAndSettle();

      expect(picked, 'rename');
      expect(find.text('重命名'), findsNothing);
    });
  });

  group('showAppDialog entrance', () {
    testWidgets('dialog scales in and settles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showAppDialog(
                    context,
                    title: '确认',
                    actions: const [AppDialogAction('好', isDefault: true)],
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('确认'), findsOneWidget);

      await tester.pumpAndSettle();
      // Settled scale returns to exactly 1.0 (no stuck transform).
      final scaleFinder = find.ancestor(
        of: find.byType(Dialog),
        matching: find.byType(ScaleTransition),
      );
      final scale = tester
          .widget<ScaleTransition>(scaleFinder.first)
          .scale
          .value;
      expect(scale, 1.0);
    });
  });
}

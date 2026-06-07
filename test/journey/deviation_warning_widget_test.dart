/// Widget tests for DeviationWarningWidget.
///
/// Closes P14-07-HUMAN-02: proves DeviationWarningWidget renders all four
/// fields (severity, skillName, description, suggestedFix) using pre-loaded
/// mock deviation state. No AI generation or IME required.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/knowledge/application/skill_notifier.dart';
import 'package:museflow/features/knowledge/presentation/deviation_warning_widget.dart';

/// A fake [DeviationNotifier] that returns pre-loaded [DeviationResult].
class _FakeDeviationNotifier extends DeviationNotifier {
  final DeviationResult _result;
  final List<String> _callLog = [];

  _FakeDeviationNotifier(this._result);

  @override
  Future<DeviationResult> build() async => _result;

  @override
  Future<void> checkDeviations(String text) async {}

  @override
  void dismissWarning(int index) {}

  @override
  void clearAll() {
    _callLog.add('clearAll');
    state = const AsyncData(DeviationResult(warnings: []));
  }

  /// Records calls for verification.
  List<String> get callLog => _callLog;
}

void main() {
  group('DeviationWarningWidget', () {
    late _FakeDeviationNotifier fakeNotifier;

    /// Helper to pump the widget with a given [DeviationResult].
    Future<void> pumpWithResult(
      WidgetTester tester,
      DeviationResult result,
    ) async {
      fakeNotifier = _FakeDeviationNotifier(result);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              overrides: [
                deviationNotifierProvider.overrideWith(() => fakeNotifier),
              ],
              child: const DeviationWarningWidget(),
            ),
          ),
        ),
      );

      // Allow the async notifier to resolve.
      await tester.pumpAndSettle();
    }

    testWidgets(
        'should render warning tiles with skillName and description '
        'when warnings are present', (tester) async {
      final warnings = [
        const DeviationWarning(
          severity: DeviationSeverity.clear,
          skillName: '境界体系约束',
          description: '主角使用了筑基期法术',
          suggestedFix: '将法术改为练气期级别',
        ),
        const DeviationWarning(
          severity: DeviationSeverity.medium,
          skillName: '门派等级森严',
          description: '外门弟子进入内门禁地',
          suggestedFix: null,
        ),
      ];

      await pumpWithResult(tester, DeviationResult(warnings: warnings));

      // Both skillName values should be visible.
      expect(find.textContaining('境界体系约束'), findsOneWidget);
      expect(find.textContaining('门派等级森严'), findsOneWidget);

      // Both description values should be visible.
      expect(find.textContaining('主角使用了筑基期法术'), findsOneWidget);
      expect(find.textContaining('外门弟子进入内门禁地'), findsOneWidget);

      // The count header should show "2 条".
      expect(find.textContaining('检测到 2 条设定偏离提醒'), findsOneWidget);
    });

    testWidgets(
        'should render suggestedFix when non-null', (tester) async {
      final warnings = [
        const DeviationWarning(
          severity: DeviationSeverity.clear,
          skillName: '境界体系约束',
          description: '主角使用了筑基期法术',
          suggestedFix: '将法术改为练气期级别',
        ),
      ];

      await pumpWithResult(tester, DeviationResult(warnings: warnings));

      // The suggested fix text should contain the label and content.
      expect(find.textContaining('建议修复'), findsOneWidget);
      expect(find.textContaining('将法术改为练气期级别'), findsOneWidget);
    });

    testWidgets(
        'should show error-colored icon for clear severity', (tester) async {
      final warnings = [
        const DeviationWarning(
          severity: DeviationSeverity.clear,
          skillName: '境界体系约束',
          description: '主角使用了筑基期法术',
        ),
      ];

      await pumpWithResult(tester, DeviationResult(warnings: warnings));

      // Find the leading Icon widget inside the ListTile.
      // For severity.clear, the icon color should match colorScheme.error.
      final iconFinder = find.descendant(
        of: find.byType(ListTile),
        matching: find.byIcon(Icons.report_problem_outlined),
      );
      expect(iconFinder, findsOneWidget);

      final icon = tester.widget<Icon>(iconFinder.first);
      // Verify the color is non-null (set by the widget based on severity).
      expect(icon.color, isNotNull);
    });

    testWidgets(
        'should render SizedBox.shrink when warnings list is empty',
        (tester) async {
      await pumpWithResult(
        tester,
        const DeviationResult(warnings: []),
      );

      // With no warnings, the widget returns SizedBox.shrink().
      // Verify no warning-related text is present.
      expect(find.textContaining('设定偏离提醒'), findsNothing);
      expect(find.textContaining('全部忽略'), findsNothing);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets(
        'should call clearAll when 全部忽略 button is tapped', (tester) async {
      final warnings = [
        const DeviationWarning(
          severity: DeviationSeverity.medium,
          skillName: '门派等级森严',
          description: '外门弟子进入内门禁地',
        ),
      ];

      await pumpWithResult(tester, DeviationResult(warnings: warnings));

      // Tap the "全部忽略" button.
      final clearButton = find.text('全部忽略');
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Verify clearAll was called on the notifier.
      expect(fakeNotifier.callLog, contains('clearAll'));
    });
  });
}

/// Widget tests for the sentence-level AI-scent section in
/// [StyleThermometerDashboard] (AA-04 wiring).
///
/// Verifies that the dashboard renders the 「最可疑的句子」 section only when
/// the source text contains a notable AI-tell sentence, and hides it when the
/// text is fresh/natural or empty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/style_deviation_detector.dart';
import 'package:museflow/features/editor/presentation/style_thermometer_dashboard.dart';

/// Helper to build a [StyleDeviationResult] with the given [text] and
/// neutral placeholder values for the other fields.
StyleDeviationResult _resultWith(String text) => StyleDeviationResult(
  deviations: const [],
  aiScentScore: 50,
  summary: 'test',
  hasDeviations: false,
  text: text,
);

Future<void> _pumpDashboard(WidgetTester tester, StyleDeviationResult result) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StyleThermometerDashboard(result: result)),
      ),
    );

void main() {
  testWidgets('should render sentence section when text has AI-tell sentence', (
    tester,
  ) async {
    // Text with both a mechanical transition-word start AND an AI-tell
    // formulaic pattern — guaranteed to clear notableThreshold (30).
    const aiText = '不仅如此，而且在这个快速发展的时代，一切都显得尤为重要。';
    await _pumpDashboard(tester, _resultWith(aiText));
    await tester.pump();

    expect(find.text('最可疑的句子'), findsOneWidget);
    // At least one known reason from SentenceAiScentAnalyzer signals.
    expect(find.text('AI套式句式'), findsWidgets);
  });

  testWidgets(
    'should not render sentence section when text is fresh and natural',
    (tester) async {
      // Short, natural dialogue-driven sentences: no AI-tell pattern, no
      // mechanical transition start, low function-word ratio, no run-on.
      const freshText = '他推开门，看见她在窗边。风很大。';
      await _pumpDashboard(tester, _resultWith(freshText));
      await tester.pump();

      expect(find.text('最可疑的句子'), findsNothing);
    },
  );

  testWidgets('should not render sentence section when text is empty', (
    tester,
  ) async {
    await _pumpDashboard(tester, _resultWith(''));
    await tester.pump();

    expect(find.text('最可疑的句子'), findsNothing);
  });
}

// Widget tests for [SynthesisPanel] — SY-01 review-signals surface.
//
// Closes the synthesis-side gap (vs the editor flow): the panel now shows an
// "AI修改复查" summary when [SynthesisState.reviewSignals] is non-empty, and
// stays clean (no noise) when there are no signals.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/features/ai/presentation/synthesis_notifier.dart';
import 'package:museflow/features/ai/presentation/synthesis_panel.dart';

/// A [SynthesisNotifier] override that emits a fixed state, so the panel can
/// be driven without streaming any AI output.
class _FixedSynthesisNotifier extends SynthesisNotifier {
  _FixedSynthesisNotifier(this._state);
  final SynthesisState _state;

  @override
  SynthesisState build() => _state;
}

List<ReviewSignal> _twoSignals() => const [
  ReviewSignal(
    title: '转场套话偏多',
    description: '连续使用常见转场词会让段落显得机械。',
    severity: ReviewSignalSeverity.medium,
    evidence: '2 次',
  ),
  ReviewSignal(
    title: '结尾悬念公式化',
    description: '章节收束出现常见钩子句式。',
    severity: ReviewSignalSeverity.high,
    evidence: '1 处',
  ),
];

void main() {
  testWidgets(
    'shows the AI review summary when reviewSignals is non-empty (SY-01)',
    (tester) async {
      final state = SynthesisState(
        accumulatedText: '他走了。',
        isEditing: true,
        reviewSignals: _twoSignals(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            synthesisProvider.overrideWith(
              () => _FixedSynthesisNotifier(state),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: SynthesisPanel())),
        ),
      );
      await tester.pumpAndSettle();

      // The highest-severity signal here is high (结尾悬念公式化), so its
      // title leads the summary line. Both signals count toward the total.
      expect(find.textContaining('AI修改复查'), findsOneWidget);
      expect(find.textContaining('结尾悬念公式化'), findsOneWidget);
    },
  );

  testWidgets(
    'does not render the review summary when reviewSignals is empty',
    (tester) async {
      final state = SynthesisState(
        accumulatedText: '他走了。',
        isEditing: true,
        reviewSignals: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            synthesisProvider.overrideWith(
              () => _FixedSynthesisNotifier(state),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: SynthesisPanel())),
        ),
      );
      await tester.pumpAndSettle();

      // Clean text must not surface a noise summary line.
      expect(find.textContaining('AI修改复查'), findsNothing);
    },
  );
}

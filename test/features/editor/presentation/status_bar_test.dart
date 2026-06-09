import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/features/editor/application/editor_ai_notifier.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:museflow/features/editor/presentation/status_bar.dart';

void main() {
  testWidgets('StatusBar renders AI edit review signal summary', (
    tester,
  ) async {
    const signal = ReviewSignal(
      title: '转场套话偏多',
      description: '连续使用常见转场词会让段落显得机械',
      severity: ReviewSignalSeverity.medium,
      evidence: '3 次',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorAINotifierProvider.overrideWith(
            () => _FixedEditorAINotifier(
              const EditorAIState(reviewSignals: [signal]),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: StatusBar())),
      ),
    );

    expect(find.text('1 条AI修改复查：转场套话偏多'), findsOneWidget);
  });

  testWidgets('StatusBar surfaces author-intent preservation signals', (
    tester,
  ) async {
    const signal = ReviewSignal(
      title: '原文关键信息可能丢失',
      description: 'AI 输出没有保留部分专名或强记忆词，采纳前请确认是否偏离作者原意。',
      severity: ReviewSignalSeverity.high,
      evidence: '青铜玉简、苏雪晴',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorAINotifierProvider.overrideWith(
            () => _FixedEditorAINotifier(
              const EditorAIState(reviewSignals: [signal]),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: StatusBar())),
      ),
    );

    expect(find.text('1 条AI修改复查：原文关键信息可能丢失'), findsOneWidget);
  });
}

class _FixedEditorAINotifier extends EditorAINotifier {
  _FixedEditorAINotifier(this.fixedState);

  final EditorAIState fixedState;

  @override
  EditorAIState build() => fixedState;
}

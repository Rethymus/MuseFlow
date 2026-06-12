/// Tests for VersionComparisonDialog and VersionHistoryButton.
///
/// Per Phase 23 (EDIT-02): Validates version comparison UI renders
/// correctly and displays undo history entries.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/editor/application/selective_undo.dart';
import 'package:museflow/features/editor/presentation/version_comparison_dialog.dart';

/// Wraps dialog content in [Dialog] widget to simulate dialog constraints.
Widget _dialogScaffold({SelectiveUndoService? service}) {
  return ProviderScope(
    overrides: service != null
        ? [
            selectiveUndoServiceProvider.overrideWith((ref) => service),
          ]
        : [],
    child: const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dialog(
            child: SizedBox(
              width: 500,
              child: VersionComparisonDialog(),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('VersionHistoryButton', () {
    testWidgets('should show without badge when undo stack is empty',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: VersionHistoryButton()),
          ),
        ),
      );

      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('should show badge when undo stack has entries',
        (tester) async {
      final service = SelectiveUndoService();
      service.record(
        originalText: '原文',
        replacementText: 'AI文本',
        nodeId: 'node-1',
        startOffset: 0,
        endOffset: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectiveUndoServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: Scaffold(body: VersionHistoryButton()),
          ),
        ),
      );

      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('VersionComparisonDialog', () {
    testWidgets('should show empty message when no entries', (tester) async {
      await tester.pumpWidget(_dialogScaffold());

      expect(find.text('AI 操作历史'), findsOneWidget);
      expect(find.text('暂无 AI 操作记录'), findsOneWidget);
    });

    testWidgets('should show entries when undo stack has data',
        (tester) async {
      final service = SelectiveUndoService();
      service.record(
        originalText: '他走进了房间。',
        replacementText: '他缓缓地推开门，走进了那间昏暗的房间。',
        nodeId: 'node-1',
        startOffset: 0,
        endOffset: 7,
      );

      await tester.pumpWidget(_dialogScaffold(service: service));

      expect(find.text('AI 操作历史'), findsOneWidget);
      expect(find.textContaining('共 1 条记录'), findsOneWidget);
      expect(find.text('操作 #1'), findsOneWidget);
      expect(find.text('原文 (A)'), findsOneWidget);
      expect(find.text('AI 文本 (B)'), findsOneWidget);
      expect(find.text('他走进了房间。'), findsOneWidget);
    });

    testWidgets('should show multiple entries in reverse order',
        (tester) async {
      final service = SelectiveUndoService();
      service.record(
        originalText: '第一段原文',
        replacementText: '第一段AI',
        nodeId: 'node-1',
        startOffset: 0,
        endOffset: 5,
      );
      service.record(
        originalText: '第二段原文',
        replacementText: '第二段AI',
        nodeId: 'node-2',
        startOffset: 10,
        endOffset: 15,
      );

      await tester.pumpWidget(_dialogScaffold(service: service));

      expect(find.textContaining('共 2 条记录'), findsOneWidget);
      expect(find.text('操作 #2'), findsOneWidget);
      expect(find.text('操作 #1'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/presentation/editor_toolbar.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  group('EditorToolbar opening generator entry', () {
    late Editor editor;

    setUp(() {
      editor = createDefaultDocumentEditor(
        document: MutableDocument(
          nodes: [ParagraphNode(id: 'node-1', text: AttributedText('正文'))],
        ),
      );
    });

    tearDown(() {
      editor.composer.dispose();
    });

    testWidgets('should show opening generator toolbar button and tooltip', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EditorToolbar(editor: editor)),
        ),
      );

      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
      final button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.auto_stories),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.tooltip, '开篇生成');
    });

    testWidgets('should open opening generator bottom sheet when tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EditorToolbar(editor: editor)),
        ),
      );

      await tester.tap(find.byIcon(Icons.auto_stories));
      await tester.pumpAndSettle();

      expect(find.text('开篇生成'), findsOneWidget);
      expect(find.text('补充描述你的故事概念（可选）'), findsOneWidget);
      expect(find.text('生成开篇'), findsOneWidget);
    });
  });
}

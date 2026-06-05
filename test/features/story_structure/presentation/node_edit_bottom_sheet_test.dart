import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart';

void main() {
  testWidgets('should show edit fields initialized from node', (tester) async {
    final node = PlotNode(
      id: 'pn-1',
      title: '初遇',
      chapter: 3,
      summary: '主角遇见导师',
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: NodeEditBottomSheet(node: node)),
        ),
      ),
    );

    expect(find.text('编辑节点'), findsOneWidget);
    expect(find.widgetWithText(TextField, '初遇'), findsOneWidget);
    expect(find.widgetWithText(TextField, '3'), findsOneWidget);
    expect(find.widgetWithText(TextField, '主角遇见导师'), findsOneWidget);
    expect(find.text('保存修改'), findsOneWidget);
  });

  testWidgets('should validate empty title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: NodeEditBottomSheet())),
      ),
    );

    await tester.tap(find.text('保存节点'));
    await tester.pump();

    expect(find.text('请输入标题'), findsOneWidget);
  });

  testWidgets('should call onSave with edited node', (tester) async {
    PlotNode? saved;
    final node = PlotNode(
      id: 'pn-1',
      title: '旧标题',
      chapter: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: NodeEditBottomSheet(
              node: node,
              onSave: (value) => saved = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, '旧标题'), '新标题');
    await tester.tap(find.text('保存修改'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.title, '新标题');
    expect(saved!.id, 'pn-1');
  });

  testWidgets('should reject non-numeric chapter input', (tester) async {
    PlotNode? saved;
    final node = PlotNode(
      id: 'pn-1',
      title: '旧标题',
      chapter: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: NodeEditBottomSheet(
              node: node,
              onSave: (value) => saved = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, '1'), 'abc');
    await tester.tap(find.text('保存修改'));
    await tester.pump();

    expect(saved, isNull);
    expect(find.text('请输入有效的章节号'), findsOneWidget);
    expect(find.text('编辑节点'), findsOneWidget);
  });

  testWidgets('should reject zero chapter input', (tester) async {
    PlotNode? saved;
    final node = PlotNode(
      id: 'pn-1',
      title: '旧标题',
      chapter: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: NodeEditBottomSheet(
              node: node,
              onSave: (value) => saved = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, '1'), '0');
    await tester.tap(find.text('保存修改'));
    await tester.pump();

    expect(saved, isNull);
    expect(find.text('章节号必须大于0'), findsOneWidget);
    expect(find.text('编辑节点'), findsOneWidget);
  });

  testWidgets('should reject negative chapter input', (tester) async {
    PlotNode? saved;
    final node = PlotNode(
      id: 'pn-1',
      title: '旧标题',
      chapter: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: NodeEditBottomSheet(
              node: node,
              onSave: (value) => saved = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, '1'), '-1');
    await tester.tap(find.text('保存修改'));
    await tester.pump();

    expect(saved, isNull);
    expect(find.text('章节号必须大于0'), findsOneWidget);
    expect(find.text('编辑节点'), findsOneWidget);
  });

  testWidgets('should save valid positive chapter input', (tester) async {
    PlotNode? saved;
    final node = PlotNode(
      id: 'pn-1',
      title: '旧标题',
      chapter: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: NodeEditBottomSheet(
              node: node,
              onSave: (value) => saved = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, '1'), '12');
    await tester.tap(find.text('保存修改'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.chapter, 12);
  });
}

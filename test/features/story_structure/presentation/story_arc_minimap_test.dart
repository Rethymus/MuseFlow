import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/presentation/story_arc/story_arc_minimap.dart';

void main() {
  testWidgets('should render minimap semantics and container', (tester) async {
    final controller = TransformationController();
    final nodes = [
      PlotNode(
        id: 'pn-1',
        title: '初遇',
        chapter: 1,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              StoryArcMinimap(
                plotNodes: nodes,
                nodePositions: const {'pn-1': Offset(100, 200)},
                transformationController: controller,
                graphCanvasSize: const Size(800, 600),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('故事弧缩略图，当前视口已高亮'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('should update when transformation controller changes', (
    tester,
  ) async {
    final controller = TransformationController();
    final nodes = [
      PlotNode(
        id: 'pn-1',
        title: '初遇',
        chapter: 1,
        createdAt: DateTime(2026, 1, 1),
      ),
      PlotNode(
        id: 'pn-2',
        title: '高潮',
        chapter: 5,
        structuralRole: PlotNodeStructuralRole.climax,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              StoryArcMinimap(
                plotNodes: nodes,
                nodePositions: const {
                  'pn-1': Offset(100, 200),
                  'pn-2': Offset(500, 600),
                },
                transformationController: controller,
                graphCanvasSize: const Size(800, 600),
              ),
            ],
          ),
        ),
      ),
    );

    controller.value = Matrix4.identity()
      ..translateByDouble(-100.0, -50.0, 0.0, 1.0)
      ..scaleByDouble(1.5, 1.5, 1.5, 1.0);
    await tester.pump();

    expect(find.byType(CustomPaint), findsWidgets);
  });
}

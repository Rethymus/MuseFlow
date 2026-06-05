import 'package:flutter/material.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/presentation/story_arc/graph_colors.dart';

/// Miniature overview of the story arc graph.
class StoryArcMinimap extends StatelessWidget {
  final List<PlotNode> plotNodes;
  final Map<String, Offset> nodePositions;
  final TransformationController transformationController;
  final Size graphCanvasSize;

  const StoryArcMinimap({
    super.key,
    required this.plotNodes,
    required this.nodePositions,
    required this.transformationController,
    required this.graphCanvasSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      right: 16,
      bottom: 16,
      child: Semantics(
        label: '故事弧缩略图，当前视口已高亮',
        child: Container(
          width: 150,
          height: 100,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedBuilder(
            animation: transformationController,
            builder: (context, _) {
              return CustomPaint(
                painter: _MinimapPainter(
                  plotNodes: plotNodes,
                  nodePositions: nodePositions,
                  transform: transformationController.value,
                  graphCanvasSize: graphCanvasSize,
                  primaryColor: colorScheme.primary,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final List<PlotNode> plotNodes;
  final Map<String, Offset> nodePositions;
  final Matrix4 transform;
  final Size graphCanvasSize;
  final Color primaryColor;
  final bool isDark;

  const _MinimapPainter({
    required this.plotNodes,
    required this.nodePositions,
    required this.transform,
    required this.graphCanvasSize,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (plotNodes.isEmpty) return;

    const padding = 8.0;
    final positions = <String, Offset>{
      for (var i = 0; i < plotNodes.length; i++)
        plotNodes[i].id:
            nodePositions[plotNodes[i].id] ??
            Offset(60.0 + i * 40.0, 40.0 + (i % 3) * 35.0),
    };

    final xs = positions.values.map((p) => p.dx).toList();
    final ys = positions.values.map((p) => p.dy).toList();
    final minX = xs.reduce((a, b) => a < b ? a : b);
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final graphWidth = (maxX - minX).abs() < 1 ? 1.0 : maxX - minX;
    final graphHeight = (maxY - minY).abs() < 1 ? 1.0 : maxY - minY;
    final scale = ((size.width - padding * 2) / graphWidth).clamp(
      0.01,
      (size.height - padding * 2) / graphHeight,
    );

    Offset toMini(Offset point) => Offset(
      padding + (point.dx - minX) * scale,
      padding + (point.dy - minY) * scale,
    );

    for (final node in plotNodes) {
      final position = positions[node.id]!;
      final dotCenter = toMini(position);
      final paint = Paint()
        ..color = GraphColor.forRole(node.structuralRole, isDark: isDark)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromCenter(center: dotCenter, width: 4, height: 4),
        paint,
      );
    }

    final currentScale = transform.getMaxScaleOnAxis();
    final translateX = transform.getTranslation().x;
    final translateY = transform.getTranslation().y;
    final visibleTopLeft = Offset(
      -translateX / currentScale,
      -translateY / currentScale,
    );
    final visibleSize = Size(
      graphCanvasSize.width / currentScale,
      graphCanvasSize.height / currentScale,
    );
    final miniTopLeft = toMini(visibleTopLeft);
    final miniBottomRight = toMini(
      visibleTopLeft + Offset(visibleSize.width, visibleSize.height),
    );
    final viewportRect = Rect.fromPoints(
      miniTopLeft,
      miniBottomRight,
    ).intersect(Offset.zero & size);

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(viewportRect, fillPaint);
    canvas.drawRect(viewportRect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) {
    return plotNodes != oldDelegate.plotNodes ||
        nodePositions != oldDelegate.nodePositions ||
        transform != oldDelegate.transform ||
        graphCanvasSize != oldDelegate.graphCanvasSize ||
        primaryColor != oldDelegate.primaryColor ||
        isDark != oldDelegate.isDark;
  }
}

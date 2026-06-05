import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

/// Relationship types shown in the story arc graph.
enum EdgeType { causal, association, foreshadowing }

/// Custom edge renderer for story arc relationship semantics.
class StoryArcEdgeRenderer extends ArrowEdgeRenderer {
  final Map<Edge, EdgeType> edgeTypes;
  final bool isDark;

  StoryArcEdgeRenderer({required this.edgeTypes, this.isDark = true})
    : super(noArrow: false);

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    final type = edgeTypes[edge] ?? EdgeType.association;
    switch (type) {
      case EdgeType.causal:
        _renderCausalEdge(canvas, edge, paint);
      case EdgeType.association:
        _renderAssociationEdge(canvas, edge);
      case EdgeType.foreshadowing:
        _renderForeshadowingEdge(canvas, edge);
    }
  }

  void _renderCausalEdge(Canvas canvas, Edge edge, Paint fallbackPaint) {
    final points = _clippedPoints(edge);
    final start = points.$1;
    final end = points.$2;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.blue.shade700, Colors.blue.shade300],
      ).createShader(Rect.fromPoints(start, end))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final trianglePaint = Paint()
      ..color = Colors.blue.shade300
      ..style = PaintingStyle.fill;
    final triangleCenter = drawTriangle(
      canvas,
      trianglePaint,
      start.dx,
      start.dy,
      end.dx,
      end.dy,
    );
    canvas.drawLine(start, triangleCenter, linePaint);
  }

  void _renderAssociationEdge(Canvas canvas, Edge edge) {
    final points = _clippedPoints(edge);
    final paint = Paint()
      ..color = isDark ? Colors.grey.shade600 : Colors.grey.shade400
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(points.$1, points.$2, paint);
  }

  void _renderForeshadowingEdge(Canvas canvas, Edge edge) {
    final points = _clippedPoints(edge);
    final paint = Paint()
      ..color = Colors.amber.shade500
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _drawDashedLine(canvas, points.$1, points.$2, paint);
    _drawDotMarkers(canvas, points.$1, points.$2, paint.color);
  }

  (Offset, Offset) _clippedPoints(Edge edge) {
    final source = edge.source;
    final destination = edge.destination;
    final sourceOffset = getNodePosition(source);
    final destinationOffset = getNodePosition(destination);
    final startX = sourceOffset.dx + source.width * 0.5;
    final startY = sourceOffset.dy + source.height * 0.5;
    final stopX = destinationOffset.dx + destination.width * 0.5;
    final stopY = destinationOffset.dy + destination.height * 0.5;
    final clipped = clipLineEnd(
      startX,
      startY,
      stopX,
      stopY,
      destinationOffset.dx,
      destinationOffset.dy,
      destination.width,
      destination.height,
    );
    return (Offset(clipped[0], clipped[1]), Offset(clipped[2], clipped[3]));
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final vector = end - start;
    final distance = vector.distance;
    if (distance == 0) return;
    final direction = vector / distance;
    const dash = 8.0;
    const gap = 5.0;
    var travelled = 0.0;
    while (travelled < distance) {
      final dashEnd = math.min(travelled + dash, distance);
      canvas.drawLine(
        start + direction * travelled,
        start + direction * dashEnd,
        paint,
      );
      travelled += dash + gap;
    }
  }

  void _drawDotMarkers(Canvas canvas, Offset start, Offset end, Color color) {
    final vector = end - start;
    final distance = vector.distance;
    if (distance == 0) return;
    final direction = vector / distance;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (var travelled = 18.0; travelled < distance; travelled += 36.0) {
      canvas.drawCircle(start + direction * travelled, 2, paint);
    }
  }
}

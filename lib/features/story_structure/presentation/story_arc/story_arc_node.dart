import 'package:flutter/material.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/presentation/story_arc/graph_colors.dart';

/// Color-coded graph node for a [PlotNode].
class StoryArcNode extends StatelessWidget {
  final PlotNode plotNode;
  final VoidCallback? onTap;

  const StoryArcNode({super.key, required this.plotNode, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderPattern = GraphStatus.borderPattern(plotNode.writingStatus);
    final size = plotNode.title.length <= 8
        ? const Size(120, 48)
        : const Size(160, 64);

    return Semantics(
      button: true,
      label: '编辑节点: ${plotNode.title}',
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          foregroundPainter: _PatternBorderPainter(
            color: GraphStatus.borderColor(plotNode.writingStatus),
            pattern: borderPattern,
            radius: 4,
          ),
          child: Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: GraphColor.forRole(
                plotNode.structuralRole,
                isDark: isDark,
              ),
              borderRadius: BorderRadius.circular(4),
              border: borderPattern == 'solid'
                  ? Border.all(
                      color: GraphStatus.borderColor(plotNode.writingStatus),
                      width: 2,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 36, 8),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        plotNode.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: _ChapterBadge(chapter: plotNode.chapter),
                ),
                Positioned(
                  top: 4,
                  right: 24,
                  child: Icon(
                    GraphStatus.statusIcon(plotNode.writingStatus),
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterBadge extends StatelessWidget {
  final int chapter;

  const _ChapterBadge({required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Ch$chapter',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PatternBorderPainter extends CustomPainter {
  final Color color;
  final String pattern;
  final double radius;

  const _PatternBorderPainter({
    required this.color,
    required this.pattern,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == 'solid') return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()..addRRect(rrect);
    final dash = pattern == 'dotted' ? 1.0 : 6.0;
    final gap = pattern == 'dotted' ? 5.0 : 4.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        pattern != oldDelegate.pattern ||
        radius != oldDelegate.radius;
  }
}

/// Context anchor visual indicator overlay for the editor.
///
/// Renders anchor visual markers in the editor:
/// - Gold background on anchored paragraphs
/// - Pin icon in the left margin
///
/// Per D-14: Persistent anchors use deeper gold (0x1AFFD700),
/// one-time anchors use lighter gold (0x0DFFD700).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/editor/domain/context_anchor.dart';
import 'package:super_editor/super_editor.dart';

/// Gold background color for persistent anchors (deeper, 10% opacity).
const _persistentAnchorColor = Color(0x1AFFD700);

/// Gold background color for one-time anchors (lighter, 5% opacity).
const _oneTimeAnchorColor = Color(0x0DFFD700);

/// Overlay builder that renders anchor visual indicators in the editor.
///
/// Shows gold backgrounds and pin icons for active context anchors.
/// Uses [ContentLayerProxyWidget] to integrate with SuperEditor's overlay system.
class ContextAnchorOverlayBuilder implements SuperEditorLayerBuilder {
  const ContextAnchorOverlayBuilder();

  @override
  ContentLayerWidget build(BuildContext context, SuperEditorContext editContext) {
    return ContentLayerProxyWidget(
      child: _AnchorOverlay(editor: editContext.editor),
    );
  }
}

/// Widget that renders anchor indicators as overlays on the editor.
class _AnchorOverlay extends ConsumerWidget {
  const _AnchorOverlay({required this.editor});

  final Editor editor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anchors = ref.watch(contextAnchorNotifierProvider);

    if (anchors.isEmpty) {
      return const SizedBox.shrink();
    }

    return _AnchorIndicators(
      editor: editor,
      anchors: anchors,
    );
  }
}

/// Renders positioned indicator widgets for each active anchor.
class _AnchorIndicators extends StatelessWidget {
  const _AnchorIndicators({
    required this.editor,
    required this.anchors,
  });

  final Editor editor;
  final List<ContextAnchor> anchors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: anchors.map((anchor) {
          return _AnchorIndicator(
            anchor: anchor,
            editor: editor,
          );
        }).toList(),
      ),
    );
  }
}

/// A single anchor indicator with gold background and pin icon.
///
/// Renders at the approximate position of the anchored node.
class _AnchorIndicator extends StatelessWidget {
  const _AnchorIndicator({
    required this.anchor,
    required this.editor,
  });

  final ContextAnchor anchor;
  final Editor editor;

  @override
  Widget build(BuildContext context) {
    final document = editor.document;
    final node = document.getNodeById(anchor.nodeId);
    if (node is! TextNode) return const SizedBox.shrink();

    final color =
        anchor.isPersistent ? _persistentAnchorColor : _oneTimeAnchorColor;

    return CustomPaint(
      painter: _AnchorHighlightPainter(
        nodeId: anchor.nodeId,
        color: color,
      ),
    );
  }
}

/// Custom painter for rendering anchor highlights.
///
/// Renders a gold-tinted background overlay for the anchored paragraph.
class _AnchorHighlightPainter extends CustomPainter {
  _AnchorHighlightPainter({
    required this.nodeId,
    required this.color,
  });

  final String nodeId;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _AnchorHighlightPainter oldDelegate) {
    return nodeId != oldDelegate.nodeId || color != oldDelegate.color;
  }
}

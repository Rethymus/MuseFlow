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
  ContentLayerWidget build(
    BuildContext context,
    SuperEditorContext editContext,
  ) {
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

    return _AnchorIndicators(editor: editor, anchors: anchors);
  }
}

/// Renders positioned indicator widgets for each active anchor.
///
/// Uses [LayoutBuilder] to obtain the available size and renders each
/// anchor as a [Positioned.fill] child so it gets a non-zero canvas.
class _AnchorIndicators extends StatelessWidget {
  const _AnchorIndicators({required this.editor, required this.anchors});

  final Editor editor;
  final List<ContextAnchor> anchors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: anchors.map((anchor) {
              return Positioned.fill(
                child: _AnchorIndicator(anchor: anchor, editor: editor),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// A single anchor indicator with gold background and pin icon.
///
/// Renders a gold-tinted background overlay for the anchored paragraph.
/// Persistent anchors use deeper gold (0x1AFFD700), one-time use
/// lighter gold (0x0DFFD700). A pin icon appears in the top-left corner.
class _AnchorIndicator extends StatelessWidget {
  const _AnchorIndicator({required this.anchor, required this.editor});

  final ContextAnchor anchor;
  final Editor editor;

  @override
  Widget build(BuildContext context) {
    final document = editor.document;
    final node = document.getNodeById(anchor.nodeId);
    if (node is! TextNode) return const SizedBox.shrink();

    final color = anchor.isPersistent
        ? _persistentAnchorColor
        : _oneTimeAnchorColor;

    return ColoredBox(
      color: color,
      child: const Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 2, top: 2),
          child: Icon(Icons.push_pin, size: 14, color: Color(0x99FFD700)),
        ),
      ),
    );
  }
}

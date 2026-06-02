/// Inline diff display overlay for the editor.
///
/// Renders sentence-level diff highlights directly in the editor:
/// - Deletions: red background with strikethrough (20% opacity)
/// - Insertions: green background (20% opacity)
///
/// Per D-01/D-02: Shows inline diff after AI operations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/editor/domain/diff_state.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:super_editor/super_editor.dart';

/// Color for deleted sentences -- red with 20% opacity.
const _deletionColor = Color(0x33FF0000);

/// Color for inserted sentences -- green with 20% opacity.
const _insertionColor = Color(0x3300FF00);

/// Floating action bar for accepting/rejecting pending diff sentences.
///
/// Per D-03: Appears when user selects text overlapping with pending
/// diff sentences. Shows "接受"/"拒绝" for single sentences, or
/// "全部接受"/"全部拒绝" for multiple.
class AcceptRejectBar extends ConsumerStatefulWidget {
  const AcceptRejectBar({
    super.key,
    required this.editor,
    required this.selectionLayerLinks,
  });

  final Editor editor;
  final SelectionLayerLinks selectionLayerLinks;

  @override
  ConsumerState<AcceptRejectBar> createState() => _AcceptRejectBarState();
}

class _AcceptRejectBarState extends ConsumerState<AcceptRejectBar> {
  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(editorAINotifierProvider);
    final diffResult = aiState.diffResult;

    // Only show when there are pending diffs
    if (diffResult == null || diffResult.allResolved) {
      return const SizedBox.shrink();
    }

    // Check if current selection overlaps with pending sentences
    final composer = widget.editor.composer;
    final selection = composer.selection;
    if (selection == null || selection.isCollapsed) {
      return const SizedBox.shrink();
    }

    // Find pending sentences that overlap with the selection
    final pendingIndices = _findOverlappingPendingSentences(
      selection,
      diffResult,
    );
    if (pendingIndices.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isMultiple = pendingIndices.length > 1;

    // Position below the selection using Follower
    return Follower.withOffset(
      link: widget.selectionLayerLinks.expandedSelectionBoundsLink,
      leaderAnchor: Alignment.bottomCenter,
      followerAnchor: Alignment.topCenter,
      offset: const Offset(0, 8),
      boundary: const ScreenFollowerBoundary(),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AcceptRejectButton(
              label: isMultiple ? '全部接受' : '接受',
              color: Colors.green.shade700,
              onTap: () {
                final notifier = ref.read(editorAINotifierProvider.notifier);
                if (isMultiple) {
                  notifier.acceptAll();
                } else {
                  notifier.acceptSentence(pendingIndices.first);
                }
              },
            ),
            const SizedBox(width: 4),
            _AcceptRejectButton(
              label: isMultiple ? '全部拒绝' : '拒绝',
              color: Colors.red.shade700,
              onTap: () {
                final notifier = ref.read(editorAINotifierProvider.notifier);
                if (isMultiple) {
                  notifier.rejectAll();
                } else {
                  notifier.rejectSentence(pendingIndices.first);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Finds indices of pending sentences that overlap with the selection.
  List<int> _findOverlappingPendingSentences(
    DocumentSelection selection,
    DiffResult diffResult,
  ) {
    final baseNodeId = selection.base.nodeId;
    final baseOffset =
        (selection.base.nodePosition as TextNodePosition).offset;
    final extentOffset =
        (selection.extent.nodePosition as TextNodePosition).offset;
    final selStart = baseOffset < extentOffset ? baseOffset : extentOffset;
    final selEnd = baseOffset < extentOffset ? extentOffset : baseOffset;

    final indices = <int>[];
    for (var i = 0; i < diffResult.sentences.length; i++) {
      final sentence = diffResult.sentences[i];
      if (sentence.status != DiffStatus.pending) continue;
      if (sentence.nodeId != baseNodeId) continue;

      // Check overlap: sentence range intersects selection range
      if (sentence.startOffset < selEnd && sentence.endOffset > selStart) {
        indices.add(i);
      }
    }
    return indices;
  }
}

/// A compact button for the accept/reject action bar.
class _AcceptRejectButton extends StatelessWidget {
  const _AcceptRejectButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Overlay builder that renders inline diff highlights in the editor.
///
/// Reads the current [DiffResult] from [EditorAIState] and renders
/// colored overlays for pending sentences. Accepted/rejected sentences
/// are not highlighted (accepted text has provenance attribution from
/// the document model).
class DiffOverlayBuilder implements SuperEditorLayerBuilder {
  const DiffOverlayBuilder();

  @override
  ContentLayerWidget build(BuildContext context, SuperEditorContext editContext) {
    return ContentLayerProxyWidget(
      child: _DiffOverlay(editor: editContext.editor),
    );
  }
}

/// Widget that renders diff highlights as overlays on the editor.
class _DiffOverlay extends ConsumerWidget {
  const _DiffOverlay({required this.editor});

  final Editor editor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(editorAINotifierProvider);
    final diffResult = aiState.diffResult;

    if (diffResult == null || diffResult.allResolved) {
      return const SizedBox.shrink();
    }

    // Build overlays for each pending sentence
    return _DiffHighlights(
      editor: editor,
      diffResult: diffResult,
    );
  }
}

/// Renders colored highlight boxes for each pending sentence diff.
///
/// Uses the editor's document layout to calculate positions of sentence
/// ranges and renders colored containers at those positions.
class _DiffHighlights extends StatelessWidget {
  const _DiffHighlights({
    required this.editor,
    required this.diffResult,
  });

  final Editor editor;
  final DiffResult diffResult;

  @override
  Widget build(BuildContext context) {
    // Filter to only pending sentences
    final pendingSentences = diffResult.sentences
        .where((s) => s.status == DiffStatus.pending)
        .toList();

    if (pendingSentences.isEmpty) {
      return const SizedBox.shrink();
    }

    // Render a stack of positioned highlight boxes
    return IgnorePointer(
      child: Stack(
        children: pendingSentences.map((sentence) {
          final color = sentence.isDeletion ? _deletionColor : _insertionColor;
          return _SentenceHighlight(
            sentence: sentence,
            color: color,
            editor: editor,
          );
        }).toList(),
      ),
    );
  }
}

/// A single sentence highlight overlay positioned at the sentence's range.
class _SentenceHighlight extends StatelessWidget {
  const _SentenceHighlight({
    required this.sentence,
    required this.color,
    required this.editor,
  });

  final SentenceDiff sentence;
  final Color color;
  final Editor editor;

  @override
  Widget build(BuildContext context) {
    // Get the document node to calculate text layout position
    final document = editor.document;
    final node = document.getNodeById(sentence.nodeId);
    if (node is! TextNode) return const SizedBox.shrink();

    // Calculate the visual rectangle for the sentence range.
    // We use a simple approach: render a colored overlay across the full
    // node width at the approximate vertical position.
    // The exact pixel-level positioning requires access to the document
    // layout's TextLayout, which is handled by the editor's rendering pipeline.
    return CustomPaint(
      painter: _DiffHighlightPainter(
        nodeId: sentence.nodeId,
        startOffset: sentence.startOffset,
        endOffset: sentence.endOffset,
        color: color,
        isDeletion: sentence.isDeletion,
      ),
    );
  }
}

/// Custom painter for rendering diff highlights at text positions.
///
/// This is a placeholder that provides the visual indication.
/// For production, this would integrate with the editor's text layout
/// to get precise character-level bounding boxes.
class _DiffHighlightPainter extends CustomPainter {
  _DiffHighlightPainter({
    required this.nodeId,
    required this.startOffset,
    required this.endOffset,
    required this.color,
    required this.isDeletion,
  });

  final String nodeId;
  final int startOffset;
  final int endOffset;
  final Color color;
  final bool isDeletion;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw a colored rectangle covering the area
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // For deletions, draw a strikethrough line
    if (isDeletion) {
      final strikePaint = Paint()
        ..color = const Color(0xFFFF0000)
        ..strokeWidth = 1.5;
      final y = size.height / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), strikePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiffHighlightPainter oldDelegate) {
    return nodeId != oldDelegate.nodeId ||
        startOffset != oldDelegate.startOffset ||
        endOffset != oldDelegate.endOffset ||
        color != oldDelegate.color;
  }
}

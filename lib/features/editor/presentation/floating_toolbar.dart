/// Floating toolbar overlay for editor AI actions.
///
/// Appears when the user selects text in the editor, offering three AI
/// operations: tone rewrite, paragraph polish, and free-input editing.
/// During AI streaming, replaces the action buttons with a progress bar
/// and cancel button.
///
/// Per D-05: Three horizontally-arranged action buttons.
/// Per D-06: Free-input expands an inline text field.
/// Per D-07: Progress bar + cancel during streaming.
/// Per D-08: Smart flip positioning (below by default, flips above when
///           selection is in the bottom 40% of the viewport).
/// Per Pitfall 4: Suppressed during IME composition.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/editor/domain/context_anchor.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:uuid/uuid.dart';
import 'package:super_editor/super_editor.dart';

/// Floating toolbar that appears on text selection with AI action buttons.
///
/// Integrates with the editor overlay system via [SelectionLayerLinks]
/// and [Follower.withOffset] for positioning relative to the selection.
class FloatingToolbar extends ConsumerStatefulWidget {
  const FloatingToolbar({
    super.key,
    required this.editor,
    required this.selectionLayerLinks,
    this.manuscriptId,
    this.chapterId,
  });

  /// The editor instance for reading selection and document state.
  final Editor editor;

  /// Links for positioning relative to the editor selection.
  final SelectionLayerLinks selectionLayerLinks;

  /// Optional manuscript context for token-audit attribution.
  final String? manuscriptId;

  /// Optional chapter context for token-audit attribution.
  final String? chapterId;

  @override
  ConsumerState<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends ConsumerState<FloatingToolbar> {
  /// Whether the free-input text field is expanded.
  bool _showFreeInput = false;

  /// Controller for the free-input text field.
  final _freeInputController = TextEditingController();

  @override
  void dispose() {
    _freeInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorAIState = ref.watch(editorAINotifierProvider);
    final composer = widget.editor.composer;

    // Pitfall 4: Suppress toolbar during IME composition
    final composingRegion = composer.composingRegion.value;
    if (composingRegion != null) {
      return const SizedBox.shrink();
    }

    // Only show toolbar when there's an expanded selection or AI is streaming
    return ValueListenableBuilder<DocumentSelection?>(
      valueListenable: composer.selectionNotifier,
      builder: (context, selection, _) {
        final hasExpandedSelection =
            selection != null && !selection.isCollapsed;

        if (!hasExpandedSelection && !editorAIState.isStreaming) {
          return const SizedBox.shrink();
        }

        // D-07: Show progress during streaming
        if (editorAIState.isStreaming) {
          return _buildFollower(
            child: _StreamingProgress(
              state: editorAIState,
              onCancel: () {
                ref.read(editorAINotifierProvider.notifier).cancel();
              },
            ),
          );
        }

        // D-08: Smart flip positioning
        return _buildFollower(
          child: _ToolbarContent(
            editor: widget.editor,
            showFreeInput: _showFreeInput,
            freeInputController: _freeInputController,
            onToggleFreeInput: () {
              setState(() {
                _showFreeInput = !_showFreeInput;
                if (!_showFreeInput) {
                  _freeInputController.clear();
                }
              });
            },
            onStartOperation: _startOperation,
            onSetAnchor: _setAnchor,
          ),
        );
      },
    );
  }

  /// Builds a [Follower.withAligner] with smart flip logic.
  ///
  /// D-08: The toolbar appears below the selection by default. When the
  /// selection's vertical center falls in the bottom 40% of the viewport,
  /// the toolbar flips above the selection to stay fully visible.
  Widget _buildFollower({required Widget child}) {
    return Follower.withAligner(
      link: widget.selectionLayerLinks.expandedSelectionBoundsLink,
      aligner: FunctionalAligner(delegate: _flipAlign),
      boundary: const ScreenFollowerBoundary(),
      child: child,
    );
  }

  /// Determines toolbar anchor alignment based on selection's viewport position.
  ///
  /// Returns a [FollowerAlignment] that places the toolbar below the selection
  /// when the selection is in the top 60% of the viewport, or above it when
  /// in the bottom 40%.
  static FollowerAlignment _flipAlign(
    Rect globalLeaderRect,
    Size followerSize, [
    Rect? globalBounds,
  ]) {
    // Default: toolbar below selection
    bool flipAbove = false;

    if (globalBounds != null && globalBounds.height > 0) {
      // Compare selection center Y against the 60% threshold of the viewport.
      final selectionCenterY = globalLeaderRect.center.dy;
      final threshold = globalBounds.height * 0.6;
      flipAbove = selectionCenterY > threshold;
    }

    if (flipAbove) {
      return const FollowerAlignment(
        leaderAnchor: Alignment.topCenter,
        followerAnchor: Alignment.bottomCenter,
        followerOffset: Offset(0, -8),
      );
    }

    return const FollowerAlignment(
      leaderAnchor: Alignment.bottomCenter,
      followerAnchor: Alignment.topCenter,
      followerOffset: Offset(0, 8),
    );
  }

  /// Sets a context anchor from the current selection.
  ///
  /// Per D-13: Creates a ContextAnchor and adds it to the notifier.
  /// Shows a SnackBar confirmation.
  void _setAnchor(AnchorType type) {
    final selection = widget.editor.composer.selection;
    if (selection == null) return;

    final selectedText = _getSelectedText(selection);
    if (selectedText.isEmpty) return;

    final nodeId = selection.base.nodeId;
    final baseOffset = (selection.base.nodePosition as TextNodePosition).offset;
    final extentOffset =
        (selection.extent.nodePosition as TextNodePosition).offset;
    final startOffset = baseOffset < extentOffset ? baseOffset : extentOffset;
    final endOffset = baseOffset < extentOffset ? extentOffset : baseOffset;

    final anchor = ContextAnchor.fromType(
      id: const Uuid().v4(),
      text: selectedText,
      nodeId: nodeId,
      startOffset: startOffset,
      endOffset: endOffset,
      type: type,
      createdAt: DateTime.now(),
    );

    final notifier = ref.read(contextAnchorNotifierProvider.notifier);
    final added = notifier.add(anchor);

    if (!added && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('锚点数量已达上限（最多10个）'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (mounted) {
      final label = type == AnchorType.persistent ? '持久锚点' : '本次参考';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已设置为$label'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Starts an AI operation on the selected text.
  void _startOperation(EditorAIOperation operation, {String? userInstruction}) {
    final selection = widget.editor.composer.selection;
    if (selection == null) return;

    // Extract selected text from the document
    final selectedText = _getSelectedText(selection);
    if (selectedText.isEmpty) return;

    // Get selection range info
    final nodeId = selection.base.nodeId;
    final baseOffset = (selection.base.nodePosition as TextNodePosition).offset;
    final extentOffset =
        (selection.extent.nodePosition as TextNodePosition).offset;
    final startOffset = baseOffset < extentOffset ? baseOffset : extentOffset;
    final endOffset = baseOffset < extentOffset ? extentOffset : baseOffset;

    ref
        .read(editorAINotifierProvider.notifier)
        .startOperation(
          operation,
          selectedText,
          nodeId,
          startOffset,
          endOffset,
          userInstruction: userInstruction,
          manuscriptId: widget.manuscriptId,
          chapterId: widget.chapterId,
        );

    // Reset free-input state after starting
    setState(() {
      _showFreeInput = false;
      _freeInputController.clear();
    });
  }

  /// Extracts the selected text from the editor document.
  String _getSelectedText(DocumentSelection selection) {
    final document = widget.editor.document;
    final nodeId = selection.base.nodeId;
    final node = document.getNodeById(nodeId);
    if (node is! TextNode) return '';

    final baseOffset = (selection.base.nodePosition as TextNodePosition).offset;
    final extentOffset =
        (selection.extent.nodePosition as TextNodePosition).offset;
    final start = baseOffset < extentOffset ? baseOffset : extentOffset;
    final end = baseOffset < extentOffset ? extentOffset : baseOffset;

    if (start == end) return '';

    return node.text.toPlainText().substring(start, end);
  }
}

/// Horizontal row of three AI action buttons.
///
/// Per D-05: 语气改写, 文段润色, 自由输入.
class _ToolbarContent extends StatelessWidget {
  const _ToolbarContent({
    required this.editor,
    required this.showFreeInput,
    required this.freeInputController,
    required this.onToggleFreeInput,
    required this.onStartOperation,
    required this.onSetAnchor,
  });

  final Editor editor;
  final bool showFreeInput;
  final TextEditingController freeInputController;
  final VoidCallback onToggleFreeInput;
  final void Function(EditorAIOperation operation, {String? userInstruction})
  onStartOperation;
  final void Function(AnchorType type) onSetAnchor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  key: const Key('ai_synthesis_button'),
                  icon: Icons.auto_fix_high,
                  label: '语气改写',
                  shortcutLabel: 'Ctrl+Shift+T',
                  onTap: () => onStartOperation(EditorAIOperation.toneRewrite),
                ),
                const SizedBox(width: 2),
                _ActionButton(
                  icon: Icons.auto_awesome,
                  label: '文段润色',
                  shortcutLabel: 'Ctrl+Shift+P',
                  onTap: () =>
                      onStartOperation(EditorAIOperation.paragraphPolish),
                ),
                const SizedBox(width: 2),
                _ActionButton(
                  icon: Icons.edit_note,
                  label: '自由输入',
                  onTap: onToggleFreeInput,
                  isActive: showFreeInput,
                ),
                // D-13: Anchor entry button
                const SizedBox(width: 2),
                const VerticalDivider(width: 1, indent: 4, endIndent: 4),
                const SizedBox(width: 2),
                _AnchorButton(onSetAnchor: onSetAnchor),
              ],
            ),
          ),
          // D-06: Free-input field
          if (showFreeInput)
            _FreeInputField(
              controller: freeInputController,
              onSubmit: (instruction) {
                onStartOperation(
                  EditorAIOperation.freeInput,
                  userInstruction: instruction,
                );
              },
              onCancel: onToggleFreeInput,
            ),
        ],
      ),
    );
  }
}

/// A compact AI action button.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.shortcutLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final String? shortcutLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final tooltipText =
        shortcutLabel != null ? '$label ($shortcutLabel)' : label;

    return Tooltip(
      message: tooltipText,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline text field for free-input instructions.
///
/// Per D-06: Appears below the action buttons when "自由输入" is tapped.
/// Has a hint text and submit on Enter. Cancel (X) collapses the field.
class _FreeInputField extends StatelessWidget {
  const _FreeInputField({
    required this.controller,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final void Function(String instruction) onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: '输入修改指令...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                // T-03-01: Limit free-input to 500 characters
                counterText: '',
              ),
              maxLength: 500,
              onSubmitted: (value) {
                final trimmed = value.trim();
                if (trimmed.isNotEmpty) {
                  onSubmit(trimmed);
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onCancel,
            tooltip: '取消',
          ),
        ],
      ),
    );
  }
}

/// Anchor entry button with popup menu for choosing anchor type.
///
/// Per D-13: Shows a "📌" button that opens a menu with two options:
/// "持久锚点" (persistent) and "本次参考" (one-time).
class _AnchorButton extends StatelessWidget {
  const _AnchorButton({required this.onSetAnchor});

  final void Function(AnchorType type) onSetAnchor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<AnchorType>(
      tooltip: '设置参考锚点',
      onSelected: onSetAnchor,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: AnchorType.persistent,
          child: Row(
            children: [
              Icon(Icons.push_pin, size: 16),
              SizedBox(width: 8),
              Text('持久锚点'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: AnchorType.oneTime,
          child: Row(
            children: [
              Icon(Icons.push_pin_outlined, size: 16),
              SizedBox(width: 8),
              Text('本次参考'),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Icon(Icons.push_pin, size: 16, color: colorScheme.onSurface),
      ),
    );
  }
}

/// Progress display during AI streaming.
///
/// Per D-07: Shows an indeterminate progress bar with a cancel button.
/// Displays accumulated text as a subtle subtitle.
class _StreamingProgress extends StatelessWidget {
  const _StreamingProgress({required this.state, required this.onCancel});

  final EditorAIState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 280,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Operation label + cancel button
          Row(
            children: [
              Expanded(
                child: Text(
                  '${state.operation?.label ?? "AI 处理"}中...',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                ),
              ),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '取消',
                  style: TextStyle(fontSize: 13, color: colorScheme.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Indeterminate progress bar
          LinearProgressIndicator(
            borderRadius: BorderRadius.circular(2),
            color: colorScheme.primary,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
          // Show error if any
          if (state.error != null) ...[
            const SizedBox(height: 4),
            Text(
              state.error!,
              style: TextStyle(fontSize: 12, color: colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

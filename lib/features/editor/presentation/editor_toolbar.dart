import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

/// Fixed formatting toolbar with 6 controls for the rich text editor.
///
/// Controls: Bold, Italic, Headings (H1/H2/H3), Unordered List, Ordered List.
/// Toolbar buttons reflect the current selection's formatting state via
/// ListenableBuilder on the composer's selectionNotifier.
class EditorToolbar extends StatefulWidget {
  const EditorToolbar({super.key, required this.editor});

  final Editor editor;

  @override
  State<EditorToolbar> createState() => _EditorToolbarState();
}

class _EditorToolbarState extends State<EditorToolbar> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: colorScheme.surfaceContainerHighest,
      child: ListenableBuilder(
        listenable: widget.editor.composer.selectionNotifier,
        builder: (context, _) {
          return Row(
            children: [
              // Bold button
              _FormatToggleButton(
                icon: Icons.format_bold,
                tooltip: '加粗 (Ctrl+B)',
                isActive: _isBoldActive(),
                onPressed: _toggleBold,
              ),
              // Italic button
              _FormatToggleButton(
                icon: Icons.format_italic,
                tooltip: '斜体 (Ctrl+I)',
                isActive: _isItalicActive(),
                onPressed: _toggleItalic,
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 24,
                child: VerticalDivider(color: colorScheme.outline),
              ),
              const SizedBox(width: 4),
              // Heading dropdown
              PopupMenuButton<NamedAttribution>(
                tooltip: '标题',
                icon: Icon(
                  Icons.title,
                  color: _activeHeadingAttribution() != null
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
                onSelected: _setHeading,
                itemBuilder: (context) => [
                  _HeadingMenuItem(
                    label: '标题 1',
                    attribution: header1Attribution,
                    isActive: _activeHeadingAttribution() == header1Attribution,
                  ),
                  _HeadingMenuItem(
                    label: '标题 2',
                    attribution: header2Attribution,
                    isActive: _activeHeadingAttribution() == header2Attribution,
                  ),
                  _HeadingMenuItem(
                    label: '标题 3',
                    attribution: header3Attribution,
                    isActive: _activeHeadingAttribution() == header3Attribution,
                  ),
                ],
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 24,
                child: VerticalDivider(color: colorScheme.outline),
              ),
              const SizedBox(width: 4),
              // Unordered list button
              _FormatToggleButton(
                icon: Icons.format_list_bulleted,
                tooltip: '无序列表',
                isActive: _isListNode(ListItemType.unordered),
                onPressed: () => _setList(ListItemType.unordered),
              ),
              // Ordered list button
              _FormatToggleButton(
                icon: Icons.format_list_numbered,
                tooltip: '有序列表',
                isActive: _isListNode(ListItemType.ordered),
                onPressed: () => _setList(ListItemType.ordered),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Bold ---

  bool _isBoldActive() {
    final selection = widget.editor.composer.selection;
    if (selection == null) return false;

    if (selection.isCollapsed) {
      return widget.editor.composer.preferences.currentAttributions
          .contains(boldAttribution);
    }

    // For expanded selection, check if document has bold at the range
    return _hasAttributionInRange(boldAttribution, selection);
  }

  void _toggleBold() {
    final composer = widget.editor.composer;
    final selection = composer.selection;
    if (selection == null) return;

    if (selection.isCollapsed) {
      composer.preferences.toggleStyles({boldAttribution});
    } else {
      widget.editor.execute([
        ToggleTextAttributionsRequest(
          documentRange: selection,
          attributions: {boldAttribution},
        ),
      ]);
    }
  }

  // --- Italic ---

  bool _isItalicActive() {
    final selection = widget.editor.composer.selection;
    if (selection == null) return false;

    if (selection.isCollapsed) {
      return widget.editor.composer.preferences.currentAttributions
          .contains(italicsAttribution);
    }

    return _hasAttributionInRange(italicsAttribution, selection);
  }

  void _toggleItalic() {
    final composer = widget.editor.composer;
    final selection = composer.selection;
    if (selection == null) return;

    if (selection.isCollapsed) {
      composer.preferences.toggleStyles({italicsAttribution});
    } else {
      widget.editor.execute([
        ToggleTextAttributionsRequest(
          documentRange: selection,
          attributions: {italicsAttribution},
        ),
      ]);
    }
  }

  // --- Heading ---

  NamedAttribution? _activeHeadingAttribution() {
    final selection = widget.editor.composer.selection;
    if (selection == null) return null;

    final nodeId = selection.base.nodeId;
    final node = widget.editor.document.getNodeById(nodeId);
    if (node is! TextNode) return null;

    final blockType = node.metadata['blockType'];
    if (blockType == header1Attribution) return header1Attribution;
    if (blockType == header2Attribution) return header2Attribution;
    if (blockType == header3Attribution) return header3Attribution;
    return null;
  }

  void _setHeading(NamedAttribution headerAttribution) {
    final composer = widget.editor.composer;
    final selection = composer.selection;
    if (selection == null) return;

    final nodeId = selection.base.nodeId;
    final node = widget.editor.document.getNodeById(nodeId);
    if (node is! TextNode) return;

    // If already this heading type, revert to plain paragraph
    final currentBlockType = node.metadata['blockType'];
    final newNode = ParagraphNode(
      id: node.id,
      text: node.text,
      metadata: currentBlockType == headerAttribution
          ? {}
          : {'blockType': headerAttribution},
    );

    widget.editor.execute([
      ReplaceNodeRequest(existingNodeId: node.id, newNode: newNode),
    ]);
  }

  // --- Lists ---

  bool _isListNode(ListItemType type) {
    final selection = widget.editor.composer.selection;
    if (selection == null) return false;

    final nodeId = selection.base.nodeId;
    final node = widget.editor.document.getNodeById(nodeId);
    if (node is! ListItemNode) return false;
    return node.type == type;
  }

  void _setList(ListItemType type) {
    final composer = widget.editor.composer;
    final selection = composer.selection;
    if (selection == null) return;

    final nodeId = selection.base.nodeId;
    final node = widget.editor.document.getNodeById(nodeId);
    if (node is! TextNode) return;

    // If already this list type, revert to paragraph
    if (node is ListItemNode && node.type == type) {
      final newNode = ParagraphNode(
        id: node.id,
        text: node.text,
      );
      widget.editor.execute([
        ReplaceNodeRequest(existingNodeId: node.id, newNode: newNode),
      ]);
      return;
    }

    final newNode = ListItemNode(
      id: node.id,
      itemType: type,
      text: node.text,
    );

    widget.editor.execute([
      ReplaceNodeRequest(existingNodeId: node.id, newNode: newNode),
    ]);
  }

  // --- Helpers ---

  /// Check if an attribution exists at any point in the given selection range.
  bool _hasAttributionInRange(Attribution attribution, DocumentSelection range) {
    try {
      final baseOffset = (range.base.nodePosition as TextNodePosition).offset;
      final extentOffset = (range.extent.nodePosition as TextNodePosition).offset;
      final start = baseOffset < extentOffset ? baseOffset : extentOffset;
      final end = baseOffset < extentOffset ? extentOffset : baseOffset;

      if (start == end) return false;

      final nodeId = range.base.nodeId;
      final node = widget.editor.document.getNodeById(nodeId);
      if (node is! TextNode) return false;

      final spans = node.text.getAttributionSpansInRange(
        attributionFilter: (a) => a == attribution,
        range: SpanRange(start, end - 1),
      );
      return spans.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

/// Toolbar toggle button that reflects active state via color.
class _FormatToggleButton extends StatelessWidget {
  const _FormatToggleButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      iconSize: 24,
      color: isActive ? colorScheme.primary : colorScheme.onSurface,
      onPressed: onPressed,
    );
  }
}

/// Heading popup menu item with active indicator.
class _HeadingMenuItem extends PopupMenuItem<NamedAttribution> {
  _HeadingMenuItem({
    required String label,
    required NamedAttribution attribution,
    required bool isActive,
  }) : super(
          value: attribution,
          child: Builder(
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              return Row(
                children: [
                  Expanded(child: Text(label)),
                  if (isActive)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                ],
              );
            },
          ),
        );
}

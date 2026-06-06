import 'package:flutter/material.dart';

/// Callback type for chapter context menu actions.
typedef ChapterContextMenuCallback = void Function(ChapterAction action);

/// Actions available in the chapter context menu.
enum ChapterAction {
  rename,
  split,
  merge,
  duplicate,
  delete,
}

/// Shows a context menu for chapter operations.
///
/// Per D-16: Provides rename, split (at cursor), merge (with adjacent),
/// duplicate (with '(副本)' suffix), and delete (with confirmation) actions.
///
/// [isSplitEnabled] controls whether the split action is available
/// (disabled when no cursor position is available).
/// [isMergeEnabled] controls whether the merge action is available
/// (disabled for the last chapter).
void showChapterContextMenu({
  required BuildContext context,
  required ChapterContextMenuCallback onAction,
  bool isSplitEnabled = false,
  bool isMergeEnabled = false,
  RelativeRect? position,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  // Default position: near the center-left of the screen
  final defaultPosition = RelativeRect.fromLTRB(
    32,
    200,
    0,
    0,
  );

  showMenu<ChapterAction>(
    context: context,
    position: position ?? defaultPosition,
    items: [
      PopupMenuItem<ChapterAction>(
        value: ChapterAction.rename,
        child: const ListTile(
          leading: Icon(Icons.edit, size: 20),
          title: Text('重命名'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      PopupMenuItem<ChapterAction>(
        value: ChapterAction.split,
        enabled: isSplitEnabled,
        child: const ListTile(
          leading: Icon(Icons.cut, size: 20),
          title: Text('在光标处拆分'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      PopupMenuItem<ChapterAction>(
        value: ChapterAction.merge,
        enabled: isMergeEnabled,
        child: const ListTile(
          leading: Icon(Icons.merge, size: 20),
          title: Text('与下一章合并'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      PopupMenuItem<ChapterAction>(
        value: ChapterAction.duplicate,
        child: const ListTile(
          leading: Icon(Icons.copy, size: 20),
          title: Text('复制章节'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<ChapterAction>(
        value: ChapterAction.delete,
        child: ListTile(
          leading: Icon(Icons.delete, size: 20, color: colorScheme.error),
          title: Text('删除', style: TextStyle(color: colorScheme.error)),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ],
  ).then((action) {
    if (action != null) {
      onAction(action);
    }
  });
}

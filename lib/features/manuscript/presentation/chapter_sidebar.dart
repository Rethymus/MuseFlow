import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/presentation/chapter_sidebar_row.dart';

/// Sidebar widget displaying a reorderable list of chapters for a manuscript.
///
/// Per D-13: Fixed 260px width, colorScheme.surface background, manuscript title
/// header, ReorderableListView of chapter rows, and "新建章节" OutlinedButton.
class ChapterSidebar extends ConsumerWidget {
  const ChapterSidebar({
    super.key,
    required this.manuscriptId,
    required this.manuscriptTitle,
    required this.activeChapterId,
    required this.onChapterTap,
    required this.onNewChapter,
    this.onReorder,
    this.onChapterContextMenu,
  });

  /// The manuscript ID whose chapters are displayed.
  final String manuscriptId;

  /// The manuscript title displayed at the top of the sidebar.
  final String manuscriptTitle;

  /// The ID of the currently active (selected) chapter.
  final String? activeChapterId;

  /// Called when the user taps a chapter row to switch to it.
  final ValueChanged<String> onChapterTap;

  /// Called when the user taps the "新建章节" button.
  final VoidCallback onNewChapter;

  /// Called when the user reorders chapters via drag-and-drop.
  /// Receives (manuscriptId, oldIndex, newIndex).
  final void Function(String manuscriptId, int oldIndex, int newIndex)?
      onReorder;

  /// Called when the user long-presses a chapter row for context menu.
  /// Receives the chapter that was long-pressed.
  final void Function(Chapter chapter)? onChapterContextMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chapterNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 260,
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Manuscript title header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              manuscriptTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          // Chapter list
          Expanded(
            child: chaptersAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => Center(
                child: Text(
                  '加载失败',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.error,
                  ),
                ),
              ),
              data: (chapters) {
                if (chapters.isEmpty) {
                  return Center(
                    child: Text(
                      '暂无章节',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) =>
                      _DragProxy(child: child, animation: animation),
                  onReorder: (oldIndex, newIndex) {
                    // ReorderableListView uses (old, new) where new is the
                    // target index after removing old. Adjust for our API.
                    if (oldIndex < newIndex) newIndex -= 1;
                    onReorder?.call(manuscriptId, oldIndex, newIndex);
                  },
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    return _ChapterRowWrapper(
                      key: ValueKey(chapter.id),
                      index: index,
                      chapter: chapter,
                      isActive: chapter.id == activeChapterId,
                      onTap: () => onChapterTap(chapter.id),
                      onLongPress: () =>
                          onChapterContextMenu?.call(chapter),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // New chapter button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: onNewChapter,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新建章节'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a [ChapterSidebarRow] with a drag handle for reordering.
class _ChapterRowWrapper extends StatelessWidget {
  const _ChapterRowWrapper({
    super.key,
    required this.index,
    required this.chapter,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  final int index;
  final Chapter chapter;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Row(
        children: [
          Expanded(
            child: ChapterSidebarRow(
              chapter: chapter,
              isActive: isActive,
              onTap: onTap,
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.drag_handle,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Drag proxy widget with Material elevation effect.
class _DragProxy extends StatelessWidget {
  const _DragProxy({
    required this.child,
    required this.animation,
  });

  final Widget child;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Material(
          elevation: 4.0 * animation.value,
          borderRadius: BorderRadius.circular(8),
          child: child,
        );
      },
      child: child,
    );
  }
}

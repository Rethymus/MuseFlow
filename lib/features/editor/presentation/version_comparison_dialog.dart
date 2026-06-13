/// Version comparison dialog for AI operations.
///
/// Per Phase 23 (EDIT-02): Displays the AI undo history with side-by-side
/// text comparison. Users can view original (A) vs AI replacement (B)
/// for each operation and choose to restore any previous version.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/editor/application/selective_undo.dart';

/// Dialog showing AI operation history with version comparison.
///
/// Presents the undo stack as a list of operations with timestamps.
/// Each operation shows original text (A) and AI replacement (B)
/// in a side-by-side layout. Users can tap "恢复" to restore
/// the original text.
class VersionComparisonDialog extends ConsumerWidget {
  const VersionComparisonDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final undoService = ref.watch(selectiveUndoServiceProvider);
    final entries = undoService.entries;

    return AlertDialog(
      title: const Text('AI 操作历史'),
      content: SizedBox(
        width: double.maxFinite,
        child: entries.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('暂无 AI 操作记录')),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '共 ${entries.length} 条记录'
                    '（最多保留 ${undoService.maxLimit} 条）',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      reverse: true, // newest first
                      itemBuilder: (context, index) {
                        final entry = entries.reversed.elementAt(index);
                        return _VersionTile(
                          entry: entry,
                          index: entries.length - index,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

/// A single version entry tile showing original (A) vs replacement (B).
class _VersionTile extends StatelessWidget {
  final UndoEntry entry;
  final int index;

  const _VersionTile({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '操作 #$index',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  _formatTime(entry.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Side-by-side comparison
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Original text (A)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '原文 (A)',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onPrimaryContainer),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 80),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            entry.originalText,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Arrow icon
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 8),
                // AI replacement (B)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'AI 文本 (B)',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onTertiaryContainer,
                              ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 80),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            entry.replacementText,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}

/// Button that opens the version comparison dialog.
///
/// Intended to be placed in the editor toolbar or as a standalone button.
/// Shows a badge with the number of undo entries when non-zero.
class VersionHistoryButton extends ConsumerWidget {
  const VersionHistoryButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final undoService = ref.watch(selectiveUndoServiceProvider);
    final count = undoService.stackLength;

    return IconButton(
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.history),
      ),
      tooltip: 'AI 操作历史',
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const VersionComparisonDialog(),
      ),
    );
  }
}

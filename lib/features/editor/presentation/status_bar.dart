/// Status bar showing pending AI modification count and manuscript progress.
///
/// Per D-11: Displays "当前文档有 N 处AI修改待确认" when N > 0.
/// Per D-25: Displays "总字数: {current}/{target} 字" when manuscript
/// context is available.
/// Hidden when no pending modifications exist and no manuscript context.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';

/// Status bar widget that shows manuscript word count progress and
/// pending AI modification count.
///
/// When [currentWordCount] and [targetWordCount] are provided, displays
/// manuscript progress. When there are pending AI diffs, shows the count.
/// Hidden when neither condition is met.
class StatusBar extends ConsumerWidget {
  const StatusBar({super.key, this.currentWordCount, this.targetWordCount});

  /// Total word count across all chapters in the current manuscript.
  /// When null, manuscript progress is not displayed.
  final int? currentWordCount;

  /// Target word count for the current manuscript.
  /// When null, manuscript progress is not displayed.
  final int? targetWordCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(editorAINotifierProvider);
    final diffResult = aiState.diffResult;
    final hasPendingDiffs = diffResult != null && !diffResult.allResolved;
    final hasManuscriptContext =
        currentWordCount != null && targetWordCount != null;

    // Hide when no diff and no manuscript context
    if (!hasPendingDiffs && !hasManuscriptContext) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          if (hasManuscriptContext) ...[
            Text(
              '总字数: ${_formatNumber(currentWordCount!)}/${_formatNumber(targetWordCount!)} 字',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasPendingDiffs)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '|',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
            if (hasPendingDiffs)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '${diffResult.pendingCount} 处AI修改待确认',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ] else if (hasPendingDiffs) ...[
            Text(
              '当前文档有 ${diffResult.pendingCount} 处AI修改待确认',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Formats a number with comma separators for readability.
  String _formatNumber(int n) {
    if (n < 1000) return '$n';
    final parts = <String>[];
    var remaining = n;
    while (remaining > 0) {
      final chunk = remaining % 1000;
      remaining ~/= 1000;
      if (remaining > 0) {
        parts.add(chunk.toString().padLeft(3, '0'));
      } else {
        parts.add(chunk.toString());
      }
    }
    return parts.reversed.join(',');
  }
}

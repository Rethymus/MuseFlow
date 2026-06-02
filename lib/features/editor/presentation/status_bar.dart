/// Status bar showing pending AI modification count.
///
/// Per D-11: Displays "当前文档有 N 处AI修改待确认" when N > 0.
/// Hidden when no pending modifications exist.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';

/// Status bar widget that shows the count of pending AI modifications.
///
/// Displayed at the bottom of the editor area. Hidden when
/// [EditorAIState.diffResult] is null or all sentences are resolved.
class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(editorAINotifierProvider);
    final diffResult = aiState.diffResult;

    // Hide when no diff or all resolved
    if (diffResult == null || diffResult.allResolved) {
      return const SizedBox.shrink();
    }

    final pendingCount = diffResult.pendingCount;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        '当前文档有 $pendingCount 处AI修改待确认',
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

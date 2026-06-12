/// Foreshadowing reminder widget — shows non-blocking reminders in editor sidebar.
///
/// Per Phase 21 (KNOW-04): Displays unresolved foreshadowing count,
/// threshold-overdue warnings, and target-overdue alerts. Follows
/// the same pattern as [DeviationWarningWidget] for UI consistency.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_reminder_service.dart';

/// Non-blocking reminder widget for foreshadowing management.
///
/// Computes reminders from [ForeshadowingNotifier] state using the
/// current chapter index and default threshold. Only renders when
/// reminders exist; returns [SizedBox.shrink] otherwise.
class ForeshadowingReminderWidget extends ConsumerWidget {
  const ForeshadowingReminderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(foreshadowingNotifierProvider);
    final entries = entriesAsync.asData?.value ?? [];

    if (entries.isEmpty) return const SizedBox.shrink();

    // Filter to open entries for count display
    final openCount = entries.where((e) => e.isOpen).length;
    if (openCount == 0) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$openCount 条伏笔未收束',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expanded foreshadowing reminder panel for the knowledge sidebar.
///
/// Shows full reminder details grouped by kind: unresolved count,
/// threshold overdue, and target overdue.
class ForeshadowingReminderPanel extends ConsumerWidget {
  /// The current chapter index (1-based) for threshold computation.
  final int currentChapter;

  /// Default chapter threshold for overdue detection.
  final int defaultThreshold;

  const ForeshadowingReminderPanel({
    super.key,
    required this.currentChapter,
    this.defaultThreshold = 10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(foreshadowingNotifierProvider.notifier);
    final reminders = notifier.remindersForChapter(
      currentChapter: currentChapter,
      defaultThreshold: defaultThreshold,
    );

    if (reminders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '伏笔追踪',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final reminder in reminders)
              _ReminderTile(reminder: reminder),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final ForeshadowingReminder reminder;

  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final color = switch (reminder.kind) {
      ForeshadowingReminderKind.targetOverdue =>
        Theme.of(context).colorScheme.error,
      ForeshadowingReminderKind.thresholdOverdue =>
        Theme.of(context).colorScheme.tertiary,
      ForeshadowingReminderKind.unresolvedCount =>
        Theme.of(context).colorScheme.primary,
    };

    final icon = switch (reminder.kind) {
      ForeshadowingReminderKind.targetOverdue =>
        Icons.error_outline,
      ForeshadowingReminderKind.thresholdOverdue =>
        Icons.warning_amber_outlined,
      ForeshadowingReminderKind.unresolvedCount =>
        Icons.info_outline,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              reminder.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';

/// Kind of foreshadowing reminder.
enum ForeshadowingReminderKind {
  /// General count of unresolved foreshadowing threads.
  unresolvedCount,

  /// Foreshadowing that has been open beyond the default chapter threshold.
  thresholdOverdue,

  /// Foreshadowing that has passed its target resolution chapter.
  targetOverdue,
}

/// A non-blocking reminder about foreshadowing state.
///
/// Reminders are advisory and never interrupt the writing workflow.
/// Each reminder groups related entry IDs and provides a human-readable message.
class ForeshadowingReminder {
  final ForeshadowingReminderKind kind;
  final List<String> entryIds;
  final String message;
  final int count;

  const ForeshadowingReminder({
    required this.kind,
    required this.entryIds,
    required this.message,
    required this.count,
  });

  @override
  String toString() =>
      'ForeshadowingReminder(kind: $kind, count: $count, '
      'entryIds: $entryIds)';
}

/// Deterministic service that computes foreshadowing reminders.
///
/// Combines chapter-threshold alerts and optional target-resolution chapters
/// to produce non-blocking reminders for unresolved threads.
///
/// Per D-03/D-04: Reminders are advisory, non-blocking, and deterministic.
/// No AI involvement in this service.
class ForeshadowingReminderService {
  /// Finds all applicable reminders for the given entries and current chapter.
  ///
  /// Returns a list of [ForeshadowingReminder] covering:
  /// - Unresolved count (total open entries)
  /// - Threshold overdue (open entries past defaultThreshold chapters)
  /// - Target overdue (open entries past their targetResolutionChapter)
  List<ForeshadowingReminder> findReminders({
    required List<ForeshadowingEntry> entries,
    required int currentChapter,
    required int defaultThreshold,
  }) {
    final reminders = <ForeshadowingReminder>[];

    // Filter to open entries only
    final openEntries = entries.where((e) => e.isOpen).toList();

    // Unresolved count reminder
    if (openEntries.isNotEmpty) {
      reminders.add(ForeshadowingReminder(
        kind: ForeshadowingReminderKind.unresolvedCount,
        entryIds: openEntries.map((e) => e.id).toList(),
        message: '有 ${openEntries.length} 条未解决的伏笔',
        count: openEntries.length,
      ));
    }

    // Threshold overdue
    final thresholdOverdueEntries = openEntries
        .where((e) => currentChapter - e.plantedChapter >= defaultThreshold)
        .toList();
    if (thresholdOverdueEntries.isNotEmpty) {
      reminders.add(ForeshadowingReminder(
        kind: ForeshadowingReminderKind.thresholdOverdue,
        entryIds: thresholdOverdueEntries.map((e) => e.id).toList(),
        message: '有 ${thresholdOverdueEntries.length} 条伏笔已超过默认提醒阈值（$defaultThreshold 章）',
        count: thresholdOverdueEntries.length,
      ));
    }

    // Target overdue
    final targetOverdueEntries = openEntries
        .where((e) =>
            e.targetResolutionChapter != null &&
            currentChapter > e.targetResolutionChapter!)
        .toList();
    if (targetOverdueEntries.isNotEmpty) {
      reminders.add(ForeshadowingReminder(
        kind: ForeshadowingReminderKind.targetOverdue,
        entryIds: targetOverdueEntries.map((e) => e.id).toList(),
        message: '有 ${targetOverdueEntries.length} 条伏笔已超过计划解决章节',
        count: targetOverdueEntries.length,
      ));
    }

    return reminders;
  }
}

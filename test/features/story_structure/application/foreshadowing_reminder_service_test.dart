import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_reminder_service.dart';

void main() {
  late ForeshadowingReminderService service;

  setUp(() {
    service = ForeshadowingReminderService();
  });

  ForeshadowingEntry makeEntry({
    required String id,
    ForeshadowingStatus status = ForeshadowingStatus.planted,
    int plantedChapter = 1,
    int? targetResolutionChapter,
  }) {
    return ForeshadowingEntry(
      id: id,
      title: 'Foreshadowing $id',
      mode: ForeshadowingMode.detailed,
      status: status,
      plantedChapter: plantedChapter,
      targetResolutionChapter: targetResolutionChapter,
      createdAt: DateTime(2026),
    );
  }

  group('ForeshadowingReminderService', () {
    test('should return empty list when no entries provided', () {
      final reminders = service.findReminders(
        entries: [],
        currentChapter: 5,
        defaultThreshold: 3,
      );
      expect(reminders, isEmpty);
    });

    test('should return unresolved count reminder when open entries exist', () {
      final entries = [
        makeEntry(
          id: '1',
          status: ForeshadowingStatus.planted,
          plantedChapter: 1,
        ),
        makeEntry(
          id: '2',
          status: ForeshadowingStatus.developing,
          plantedChapter: 2,
        ),
        makeEntry(
          id: '3',
          status: ForeshadowingStatus.resolved,
          plantedChapter: 1,
        ),
      ];

      final reminders = service.findReminders(
        entries: entries,
        currentChapter: 3,
        defaultThreshold: 10,
      );

      expect(reminders, isNotEmpty);
      final countReminder = reminders.where(
        (r) => r.kind == ForeshadowingReminderKind.unresolvedCount,
      );
      expect(countReminder, hasLength(1));
      expect(
        countReminder.first.count,
        2,
      ); // planted + developing, not resolved
    });

    test('should return threshold overdue reminder', () {
      // Planted at chapter 1, threshold 3, current chapter 5 => overdue
      final entries = [makeEntry(id: '1', plantedChapter: 1)];

      final reminders = service.findReminders(
        entries: entries,
        currentChapter: 5,
        defaultThreshold: 3,
      );

      final overdue = reminders.where(
        (r) => r.kind == ForeshadowingReminderKind.thresholdOverdue,
      );
      expect(overdue, hasLength(1));
      expect(overdue.first.entryIds, contains('1'));
    });

    test('should not return threshold overdue when within threshold', () {
      final entries = [makeEntry(id: '1', plantedChapter: 1)];

      final reminders = service.findReminders(
        entries: entries,
        currentChapter: 3,
        defaultThreshold: 5,
      );

      final overdue = reminders.where(
        (r) => r.kind == ForeshadowingReminderKind.thresholdOverdue,
      );
      expect(overdue, isEmpty);
    });

    test('should return target overdue reminder when past target chapter', () {
      final entries = [
        makeEntry(id: '1', plantedChapter: 1, targetResolutionChapter: 5),
      ];

      final reminders = service.findReminders(
        entries: entries,
        currentChapter: 6,
        defaultThreshold: 100, // high so threshold overdue does not fire
      );

      final targetOverdue = reminders.where(
        (r) => r.kind == ForeshadowingReminderKind.targetOverdue,
      );
      expect(targetOverdue, hasLength(1));
      expect(targetOverdue.first.entryIds, contains('1'));
    });

    test('should not return target overdue when before target chapter', () {
      final entries = [
        makeEntry(id: '1', plantedChapter: 1, targetResolutionChapter: 10),
      ];

      final reminders = service.findReminders(
        entries: entries,
        currentChapter: 5,
        defaultThreshold: 100,
      );

      final targetOverdue = reminders.where(
        (r) => r.kind == ForeshadowingReminderKind.targetOverdue,
      );
      expect(targetOverdue, isEmpty);
    });

    test('should not return reminders for resolved entries', () {
      final entries = [
        makeEntry(
          id: '1',
          status: ForeshadowingStatus.resolved,
          plantedChapter: 1,
        ),
      ];

      final reminders = service.findReminders(
        entries: entries,
        currentChapter: 100,
        defaultThreshold: 1,
      );

      final overdue = reminders.where(
        (r) => r.kind == ForeshadowingReminderKind.thresholdOverdue,
      );
      expect(overdue, isEmpty);
    });

    test('should not return reminders for abandoned entries', () {
      final entries = [
        makeEntry(
          id: '1',
          status: ForeshadowingStatus.abandoned,
          plantedChapter: 1,
        ),
      ];

      final reminders = service.findReminders(
        entries: entries,
        currentChapter: 100,
        defaultThreshold: 1,
      );

      final overdue = reminders.where(
        (r) => r.kind == ForeshadowingReminderKind.thresholdOverdue,
      );
      expect(overdue, isEmpty);
    });

    test('should group threshold overdue entries into single reminder', () {
      final entries = [
        makeEntry(id: '1', plantedChapter: 1),
        makeEntry(id: '2', plantedChapter: 2),
        makeEntry(id: '3', plantedChapter: 3),
      ];

      final reminders = service.findReminders(
        entries: entries,
        currentChapter: 10,
        defaultThreshold: 3,
      );

      final overdue = reminders.where(
        (r) => r.kind == ForeshadowingReminderKind.thresholdOverdue,
      );
      // All three are overdue, should be grouped into one reminder
      expect(overdue, hasLength(1));
      expect(overdue.first.entryIds.length, 3);
    });

    test('should group target overdue entries into single reminder', () {
      final entries = [
        makeEntry(id: '1', plantedChapter: 1, targetResolutionChapter: 3),
        makeEntry(id: '2', plantedChapter: 1, targetResolutionChapter: 4),
      ];

      final reminders = service.findReminders(
        entries: entries,
        currentChapter: 10,
        defaultThreshold: 100,
      );

      final targetOverdue = reminders.where(
        (r) => r.kind == ForeshadowingReminderKind.targetOverdue,
      );
      expect(targetOverdue, hasLength(1));
      expect(targetOverdue.first.entryIds.length, 2);
    });
  });
}

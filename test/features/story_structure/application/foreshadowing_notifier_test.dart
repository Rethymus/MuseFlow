import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_reminder_service.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/infrastructure/foreshadowing_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late ProviderContainer container;
  late Box<dynamic> box;

  setUp(() async {
    await setUpHiveTest();
    box = await Hive.openBox<dynamic>('test_foreshadowing_notifier');

    container = ProviderContainer(
      overrides: [
        foreshadowingRepositoryProvider
            .overrideWith((ref) async => ForeshadowingRepository(box)),
        foreshadowingReminderServiceProvider
            .overrideWithValue(ForeshadowingReminderService()),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await tearDownHiveTest();
  });

  ForeshadowingEntry _makeEntry({
    required String id,
    String title = 'Test',
    ForeshadowingStatus status = ForeshadowingStatus.planted,
    int plantedChapter = 1,
  }) {
    return ForeshadowingEntry(
      id: id,
      title: title,
      mode: ForeshadowingMode.simple,
      status: status,
      plantedChapter: plantedChapter,
      createdAt: DateTime(2026),
    );
  }

  group('ForeshadowingNotifier', () {
    test('build should load entries from repository', () async {
      // Pre-populate the box
      final repo = ForeshadowingRepository(box);
      await repo.add(_makeEntry(id: 'e1'));
      await repo.add(_makeEntry(id: 'e2'));

      final notifier = container.read(foreshadowingNotifierProvider.notifier);
      final entries = await notifier.future;

      expect(entries, hasLength(2));
      expect(entries.map((e) => e.id), containsAll(['e1', 'e2']));
    });

    test('add should persist and refresh state', () async {
      final notifier = container.read(foreshadowingNotifierProvider.notifier);

      await notifier.add(_makeEntry(id: 'e1'));
      final entries = await notifier.future;

      expect(entries, hasLength(1));
      expect(entries.first.id, 'e1');
    });

    test('save should update existing entry and refresh state', () async {
      final notifier = container.read(foreshadowingNotifierProvider.notifier);

      await notifier.add(_makeEntry(id: 'e1', title: 'Original'));
      final original = (await notifier.future).first;

      await notifier.save(original.copyWith(title: 'Updated'));
      final updated = (await notifier.future).first;

      expect(updated.title, 'Updated');
    });

    test('delete should remove entry and refresh state', () async {
      final notifier = container.read(foreshadowingNotifierProvider.notifier);

      await notifier.add(_makeEntry(id: 'e1'));
      await notifier.delete('e1');

      final entries = await notifier.future;
      expect(entries, isEmpty);
    });

    test('markResolved should set status to resolved and set resolvedChapter',
        () async {
      final notifier = container.read(foreshadowingNotifierProvider.notifier);

      await notifier.add(_makeEntry(id: 'e1'));
      await notifier.markResolved('e1', resolvedChapter: 10);

      final entry = (await notifier.future).first;
      expect(entry.status, ForeshadowingStatus.resolved);
      expect(entry.resolvedChapter, 10);
    });

    test('markAbandoned should set status to abandoned', () async {
      final notifier = container.read(foreshadowingNotifierProvider.notifier);

      await notifier.add(_makeEntry(id: 'e1'));
      await notifier.markAbandoned('e1');

      final entry = (await notifier.future).first;
      expect(entry.status, ForeshadowingStatus.abandoned);
    });

    test('remindersForChapter should return reminders for current state',
        () async {
      final notifier = container.read(foreshadowingNotifierProvider.notifier);

      await notifier.add(_makeEntry(id: 'e1', plantedChapter: 1));
      await notifier.add(_makeEntry(
        id: 'e2',
        status: ForeshadowingStatus.developing,
        plantedChapter: 1,
      ));

      // Wait for state to settle
      await notifier.future;

      final reminders = notifier.remindersForChapter(
        currentChapter: 5,
        defaultThreshold: 3,
      );

      expect(reminders, isNotEmpty);
      // Should have at least unresolved count and threshold overdue
      expect(
        reminders.any((r) =>
            r.kind == ForeshadowingReminderKind.unresolvedCount),
        isTrue,
      );
      expect(
        reminders.any((r) =>
            r.kind == ForeshadowingReminderKind.thresholdOverdue),
        isTrue,
      );
    });

    test('remindersForChapter should return empty for resolved entries',
        () async {
      final notifier = container.read(foreshadowingNotifierProvider.notifier);

      await notifier.add(_makeEntry(id: 'e1'));
      await notifier.markResolved('e1', resolvedChapter: 5);

      // Wait for state to settle
      await notifier.future;

      final reminders = notifier.remindersForChapter(
        currentChapter: 100,
        defaultThreshold: 1,
      );

      // Resolved entries should not generate reminders
      expect(
        reminders.where((r) =>
            r.kind == ForeshadowingReminderKind.unresolvedCount),
        isEmpty,
      );
    });
  });
}

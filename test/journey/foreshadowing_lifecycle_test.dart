import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_reminder_service.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'helpers/journey_container.dart';

void main() {
  group('Foreshadowing lifecycle', () {
    late ProviderContainer container;

    setUp(() async {
      container = await createJourneyContainer(
        apiKey: 'journey-local-test-key',
        baseUrl: 'https://example.com/v1',
        model: 'fake-model',
      );
    });

    tearDown(() async {
      await cleanupJourneyContainer(container);
    });

    group('Foreshadowing creation', () {
      test('should create 4 foreshadowing entries', () async {
        final notifier = container.read(foreshadowingNotifierProvider.notifier);

        for (final entry in _foreshadowingEntries()) {
          await notifier.add(entry);
        }

        final entries = await container.read(foreshadowingNotifierProvider.future);
        expect(entries, hasLength(4));
        expect(
          entries.map((entry) => entry.status).toSet(),
          equals({ForeshadowingStatus.planted}),
        );
        expect(
          entries.map((entry) => entry.mode).toSet(),
          equals({ForeshadowingMode.detailed}),
        );
        expect(
          entries.map((entry) => entry.plantedChapter).toSet(),
          equals({3, 10, 20, 30}),
        );
        expect(
          entries.map((entry) => entry.targetResolutionChapter).toSet(),
          equals({90, 75, 85, 95}),
        );
      });
    });

    group('State transitions', () {
      test('should transition entries through planted-developing-resolved', () async {
        final resolvedEntries = await _runFullForeshadowingLifecycle(container);

        expect(resolvedEntries, hasLength(4));
        expect(
          resolvedEntries.map((entry) => entry.status).toSet(),
          equals({ForeshadowingStatus.resolved}),
        );
        expect(_entryById(resolvedEntries, 'fs-mysterious-origin').resolvedChapter, 92);
        expect(_entryById(resolvedEntries, 'fs-senior-sister-secret').resolvedChapter, 78);
        expect(_entryById(resolvedEntries, 'fs-forbidden-zone').resolvedChapter, 88);
        expect(_entryById(resolvedEntries, 'fs-ancient-artifact').resolvedChapter, 96);
      });
    });

    group('Cross-chapter tracking', () {
      test('should track 4 threads across 60 plus chapters per D-05', () async {
        final resolvedEntries = await _runFullForeshadowingLifecycle(container);
        final spans = resolvedEntries.map(
          (entry) => entry.resolvedChapter! - entry.plantedChapter,
        );

        expect(spans, everyElement(greaterThanOrEqualTo(60)));
        expect(
          resolvedEntries.map((entry) => entry.plantedChapter).toSet(),
          equals({3, 10, 20, 30}),
        );
        expect(
          resolvedEntries.map((entry) => entry.resolvedChapter).toSet(),
          equals({92, 78, 88, 96}),
        );
      });
    });

    group('Reminder service', () {
      test('should generate threshold overdue reminders at chapter 85', () async {
        final notifier = container.read(foreshadowingNotifierProvider.notifier);
        for (final entry in _foreshadowingEntries()) {
          await notifier.add(entry);
        }
        final entries = await container.read(foreshadowingNotifierProvider.future);
        final service = container.read(foreshadowingReminderServiceProvider);

        final reminders = service.findReminders(
          entries: entries,
          currentChapter: 85,
          defaultThreshold: 50,
        );
        final thresholdReminder = reminders.singleWhere(
          (reminder) => reminder.kind == ForeshadowingReminderKind.thresholdOverdue,
        );

        expect(thresholdReminder.count, greaterThanOrEqualTo(2));
        expect(thresholdReminder.entryIds, contains('fs-mysterious-origin'));
        expect(thresholdReminder.entryIds, contains('fs-senior-sister-secret'));
      });
    });

    group('Full lifecycle end state', () {
      test('should have all threads resolved by chapter 100', () async {
        final resolvedEntries = await _runFullForeshadowingLifecycle(container);

        expect(resolvedEntries, everyElement((ForeshadowingEntry entry) => entry.isResolved));
        expect(
          resolvedEntries.map((entry) => entry.resolvedChapter),
          everyElement(inInclusiveRange(75, 96)),
        );
        expect(
          resolvedEntries.map((entry) => entry.resolvedChapter),
          everyElement(lessThanOrEqualTo(100)),
        );
      });
    });

  });
}

List<ForeshadowingEntry> _foreshadowingEntries() {
  final createdAt = DateTime(2026, 6, 8);
  return [
    ForeshadowingEntry(
      id: 'fs-mysterious-origin',
      title: '神秘身世',
      mode: ForeshadowingMode.detailed,
      status: ForeshadowingStatus.planted,
      plantedChapter: 3,
      targetResolutionChapter: 90,
      sourceExcerpt: '林风身世不明，清虚真人对他格外关注',
      createdAt: createdAt,
    ),
    ForeshadowingEntry(
      id: 'fs-senior-sister-secret',
      title: '师姐的秘密',
      mode: ForeshadowingMode.detailed,
      status: ForeshadowingStatus.planted,
      plantedChapter: 10,
      targetResolutionChapter: 75,
      sourceExcerpt: '苏雪晴深夜独自前往禁地，行为可疑',
      createdAt: createdAt,
    ),
    ForeshadowingEntry(
      id: 'fs-forbidden-zone',
      title: '门派禁地',
      mode: ForeshadowingMode.detailed,
      status: ForeshadowingStatus.planted,
      plantedChapter: 20,
      targetResolutionChapter: 85,
      sourceExcerpt: '禁地深处传来异响，封印似乎在松动',
      createdAt: createdAt,
    ),
    ForeshadowingEntry(
      id: 'fs-ancient-artifact',
      title: '远古法器',
      mode: ForeshadowingMode.detailed,
      status: ForeshadowingStatus.planted,
      plantedChapter: 30,
      targetResolutionChapter: 95,
      sourceExcerpt: '林风发现玉简表面刻满古老符文，灵光隐隐',
      createdAt: createdAt,
    ),
  ];
}

Future<List<ForeshadowingEntry>> _runFullForeshadowingLifecycle(
  ProviderContainer container,
) async {
  final notifier = container.read(foreshadowingNotifierProvider.notifier);
  for (final entry in _foreshadowingEntries()) {
    await notifier.add(entry);
  }

  await _developAndResolve(
    container: container,
    id: 'fs-mysterious-origin',
    notes: '身世线索逐渐浮现',
    resolvedChapter: 92,
  );
  await _developAndResolve(
    container: container,
    id: 'fs-senior-sister-secret',
    notes: '苏雪晴的真实身份开始暴露',
    resolvedChapter: 78,
  );
  await _developAndResolve(
    container: container,
    id: 'fs-forbidden-zone',
    notes: '禁地封印出现裂痕',
    resolvedChapter: 88,
  );
  await _developAndResolve(
    container: container,
    id: 'fs-ancient-artifact',
    notes: '玉简灵光越来越强',
    resolvedChapter: 96,
  );

  return container.read(foreshadowingNotifierProvider.future);
}

Future<void> _developAndResolve({
  required ProviderContainer container,
  required String id,
  required String notes,
  required int resolvedChapter,
}) async {
  final notifier = container.read(foreshadowingNotifierProvider.notifier);
  final entries = await container.read(foreshadowingNotifierProvider.future);
  final entry = _entryById(entries, id);
  await notifier.save(
    entry.copyWith(
      status: ForeshadowingStatus.developing,
      notes: notes,
      updatedAt: DateTime(2026, 6, 8),
    ),
  );
  final developingEntries = await container.read(foreshadowingNotifierProvider.future);
  expect(_entryById(developingEntries, id).status, ForeshadowingStatus.developing);

  await notifier.markResolved(id, resolvedChapter: resolvedChapter);
  final resolvedEntries = await container.read(foreshadowingNotifierProvider.future);
  final resolvedEntry = _entryById(resolvedEntries, id);
  expect(resolvedEntry.status, ForeshadowingStatus.resolved);
  expect(resolvedEntry.resolvedChapter, resolvedChapter);
}

ForeshadowingEntry _entryById(List<ForeshadowingEntry> entries, String id) {
  return entries.singleWhere((entry) => entry.id == id);
}

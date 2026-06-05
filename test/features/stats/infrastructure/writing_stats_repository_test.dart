import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/stats/infrastructure/writing_stats_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late Box<dynamic> aggregateBox;
  late Box<dynamic> dailyBox;
  late WritingStatsRepository repository;

  setUp(() async {
    await setUpHiveTest();
    aggregateBox = await Hive.openBox<dynamic>('test_writing_stats');
    dailyBox = await Hive.openBox<dynamic>('test_daily_writing_stats');
    repository = WritingStatsRepository(aggregateBox, dailyBox);
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  group('WritingStatsRepository', () {
    test('records global daily and project deltas', () async {
      await repository.recordSessionDelta(
        projectId: 'novel-1',
        documentId: 'chapter-1',
        humanUnits: 120,
        aiUnits: 30,
        editDuration: const Duration(minutes: 10),
        occurredAt: DateTime(2026, 6, 4, 10),
      );

      final snapshot = await repository.loadSnapshot(projectId: 'novel-1');

      expect(snapshot.totalUnits, 150);
      expect(snapshot.humanUnits, 120);
      expect(snapshot.aiUnits, 30);
      expect(snapshot.sessionCount, 1);
      expect(snapshot.editSeconds, 600);
      expect(snapshot.writingDays, 1);
      expect(snapshot.daily.single.dateKey, '2026-06-04');
      expect(snapshot.currentProject!.totalUnits, 150);
    });

    test('aggregates multiple sessions', () async {
      await repository.recordSessionDelta(
        humanUnits: 10,
        aiUnits: 0,
        editDuration: const Duration(seconds: 30),
        occurredAt: DateTime(2026, 6, 4),
      );
      await repository.recordSessionDelta(
        humanUnits: 0,
        aiUnits: 5,
        editDuration: const Duration(seconds: 20),
        occurredAt: DateTime(2026, 6, 5),
      );

      final snapshot = await repository.loadSnapshot();

      expect(snapshot.totalUnits, 15);
      expect(snapshot.sessionCount, 2);
      expect(snapshot.writingDays, 2);
      expect(snapshot.daily, hasLength(2));
    });

    test('clears aggregate and daily stats', () async {
      await repository.recordSessionDelta(
        humanUnits: 10,
        aiUnits: 2,
        editDuration: const Duration(seconds: 10),
        occurredAt: DateTime(2026, 6, 4),
      );

      await repository.clearAll();
      final snapshot = await repository.loadSnapshot();

      expect(snapshot.totalUnits, 0);
      expect(snapshot.daily, isEmpty);
    });
  });
}

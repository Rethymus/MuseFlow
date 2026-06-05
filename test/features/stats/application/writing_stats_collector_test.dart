import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/stats/application/writing_stats_collector.dart';
import 'package:museflow/features/stats/infrastructure/writing_stats_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late WritingStatsRepository repository;
  late WritingStatsCollector collector;

  setUp(() async {
    await setUpHiveTest();
    repository = WritingStatsRepository(
      await Hive.openBox<dynamic>('test_writing_stats'),
      await Hive.openBox<dynamic>('test_daily_writing_stats'),
    );
    collector = WritingStatsCollector(
      repository,
      debounceDuration: const Duration(milliseconds: 20),
    );
  });

  tearDown(() async {
    collector.dispose();
    await tearDownHiveTest();
  });

  group('WritingStatsCollector', () {
    test('uses first text snapshot as baseline', () async {
      collector.recordTextSnapshot('月光');
      await collector.flush();

      final snapshot = await repository.loadSnapshot();
      expect(snapshot.totalUnits, 0);
    });

    test('records positive human text deltas only', () async {
      collector.recordTextSnapshot('月光');
      collector.recordTextSnapshot('月光下他走了');
      collector.recordTextSnapshot('月光');
      await collector.flush();

      final snapshot = await repository.loadSnapshot();
      expect(snapshot.humanUnits, 4);
      expect(snapshot.aiUnits, 0);
    });

    test('records AI insertion units separately', () async {
      collector.recordTextSnapshot('月光');
      collector.recordAiInsertion('AI wrote this');
      await collector.flush();

      final snapshot = await repository.loadSnapshot();
      expect(snapshot.humanUnits, 0);
      expect(snapshot.aiUnits, 3);
    });

    test('debounces persistence', () async {
      collector.recordTextSnapshot('月');
      collector.recordTextSnapshot('月光');

      expect((await repository.loadSnapshot()).totalUnits, 0);
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect((await repository.loadSnapshot()).humanUnits, 1);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/infrastructure/writing_stats_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  setUp(() async {
    await setUpHiveTest();
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  test('loads snapshot from repository', () async {
    final repository = WritingStatsRepository(
      await Hive.openBox<dynamic>('test_writing_stats'),
      await Hive.openBox<dynamic>('test_daily_writing_stats'),
    );
    await repository.recordSessionDelta(
      humanUnits: 12,
      aiUnits: 3,
      editDuration: const Duration(minutes: 1),
      occurredAt: DateTime(2026, 6, 4),
    );

    final container = ProviderContainer(
      overrides: [
        writingStatsRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);

    final snapshot = await container.read(writingStatsNotifierProvider.future);

    expect(snapshot.totalUnits, 15);
  });
}

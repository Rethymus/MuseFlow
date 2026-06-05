import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';

class WritingStatsNotifier extends AsyncNotifier<StatsSnapshot> {
  @override
  Future<StatsSnapshot> build() async {
    final repository = await ref.watch(writingStatsRepositoryProvider.future);
    return repository.loadSnapshot();
  }

  Future<void> refresh() async {
    final repository = await ref.read(writingStatsRepositoryProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.loadSnapshot);
  }

  Future<void> clearAll() async {
    final repository = await ref.read(writingStatsRepositoryProvider.future);
    await repository.clearAll();
    state = const AsyncData(StatsSnapshot());
  }
}

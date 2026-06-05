import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/domain/achievement_badge.dart';

class AchievementNotifier extends AsyncNotifier<List<AchievementBadge>> {
  @override
  Future<List<AchievementBadge>> build() async {
    final snapshot = await ref.watch(writingStatsNotifierProvider.future);
    final repository = await ref.watch(writingStatsRepositoryProvider.future);
    final previous = await repository.loadBadges();
    final service = ref.watch(achievementServiceProvider);
    final badges = service.evaluateBadges(snapshot, previous: previous);
    await repository.saveBadges(badges);
    return badges;
  }
}

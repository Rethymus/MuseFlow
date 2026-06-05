import 'package:museflow/features/stats/domain/achievement_badge.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';

class AchievementService {
  const AchievementService();

  static const defaultBadges = [
    AchievementBadge(
      id: 'first_1k',
      title: '千字起笔',
      description: '完成第一个一千字。',
      type: AchievementBadgeType.totalWords,
      threshold: 1000,
    ),
    AchievementBadge(
      id: 'first_10k',
      title: '万字成章',
      description: '累计写下一万字。',
      type: AchievementBadgeType.totalWords,
      threshold: 10000,
    ),
    AchievementBadge(
      id: 'first_50k',
      title: '五万字长风',
      description: '故事已经有了长篇的骨架。',
      type: AchievementBadgeType.totalWords,
      threshold: 50000,
    ),
    AchievementBadge(
      id: 'streak_7',
      title: '连续七日有光',
      description: '连续七个写作日保持创作。',
      type: AchievementBadgeType.streakDays,
      threshold: 7,
    ),
    AchievementBadge(
      id: 'streak_30',
      title: '一月不熄',
      description: '连续三十个写作日都有进展。',
      type: AchievementBadgeType.streakDays,
      threshold: 30,
    ),
    AchievementBadge(
      id: 'streak_100',
      title: '百日成河',
      description: '连续一百个写作日，水滴穿石。',
      type: AchievementBadgeType.streakDays,
      threshold: 100,
    ),
  ];

  List<AchievementBadge> evaluateBadges(
    StatsSnapshot snapshot, {
    DateTime? now,
    List<AchievementBadge> previous = const [],
  }) {
    final previousById = {for (final badge in previous) badge.id: badge};
    final streakDays = _consecutiveWritingDays(snapshot);
    final unlockedAt = now ?? DateTime.now();

    return [
      for (final badge in defaultBadges)
        _evaluateBadge(
          badge,
          previousById[badge.id],
          snapshot: snapshot,
          streakDays: streakDays,
          unlockedAt: unlockedAt,
        ),
    ];
  }

  AchievementBadge _evaluateBadge(
    AchievementBadge badge,
    AchievementBadge? previous, {
    required StatsSnapshot snapshot,
    required int streakDays,
    required DateTime unlockedAt,
  }) {
    final progress = switch (badge.type) {
      AchievementBadgeType.totalWords => snapshot.totalUnits,
      AchievementBadgeType.streakDays => streakDays,
    };
    final existingUnlock = previous?.unlockedAt;
    return badge.copyWith(
      progress: progress > badge.threshold ? badge.threshold : progress,
      unlockedAt:
          existingUnlock ?? (progress >= badge.threshold ? unlockedAt : null),
    );
  }

  int _consecutiveWritingDays(StatsSnapshot snapshot) {
    final activeDates =
        snapshot.daily
            .where((day) => day.totalUnits > 0)
            .map((day) => DateTime.parse(day.dateKey))
            .toList()
          ..sort();
    if (activeDates.isEmpty) return 0;

    var streak = 1;
    for (var i = activeDates.length - 1; i > 0; i--) {
      final current = activeDates[i];
      final previous = activeDates[i - 1];
      if (current.difference(previous).inDays == 1) {
        streak++;
      } else if (current.difference(previous).inDays > 1) {
        break;
      }
    }
    return streak;
  }
}

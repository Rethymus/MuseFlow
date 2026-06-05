import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/application/achievement_service.dart';
import 'package:museflow/features/stats/domain/daily_writing_stats.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';

void main() {
  const service = AchievementService();

  test('unlocks total word thresholds', () {
    final badges = service.evaluateBadges(
      const StatsSnapshot(totalUnits: 12000),
      now: DateTime(2026, 6, 4),
    );

    expect(
      badges.firstWhere((badge) => badge.id == 'first_1k').isUnlocked,
      isTrue,
    );
    expect(
      badges.firstWhere((badge) => badge.id == 'first_10k').isUnlocked,
      isTrue,
    );
    expect(
      badges.firstWhere((badge) => badge.id == 'first_50k').isUnlocked,
      isFalse,
    );
  });

  test('unlocks streak thresholds from consecutive writing days', () {
    final badges = service.evaluateBadges(
      StatsSnapshot(
        daily: [
          for (var day = 1; day <= 7; day++)
            DailyWritingStats(dateKey: '2026-06-0$day', humanUnits: 10),
        ],
      ),
      now: DateTime(2026, 6, 8),
    );

    expect(
      badges.firstWhere((badge) => badge.id == 'streak_7').isUnlocked,
      isTrue,
    );
    expect(
      badges.firstWhere((badge) => badge.id == 'streak_30').isUnlocked,
      isFalse,
    );
  });

  test('preserves existing unlockedAt', () {
    final first = service.evaluateBadges(
      const StatsSnapshot(totalUnits: 1000),
      now: DateTime(2026, 6, 4),
    );
    final second = service.evaluateBadges(
      const StatsSnapshot(totalUnits: 2000),
      now: DateTime(2026, 6, 5),
      previous: first,
    );

    expect(
      second.firstWhere((badge) => badge.id == 'first_1k').unlockedAt,
      DateTime(2026, 6, 4),
    );
  });

  test('tracks partial progress for locked badges', () {
    final badges = service.evaluateBadges(const StatsSnapshot(totalUnits: 500));
    final badge = badges.firstWhere((badge) => badge.id == 'first_1k');

    expect(badge.isUnlocked, isFalse);
    expect(badge.progress, 500);
  });
}

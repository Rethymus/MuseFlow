import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/domain/achievement_badge.dart';
import 'package:museflow/features/stats/presentation/achievement_badge_card.dart';

class AchievementBadgeSection extends ConsumerWidget {
  const AchievementBadgeSection({super.key, this.debugBadges});

  final List<AchievementBadge>? debugBadges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugBadges = this.debugBadges;
    if (debugBadges != null) {
      return _AchievementBadgeList(badges: debugBadges);
    }

    final badgesAsync = ref.watch(achievementNotifierProvider);
    return badgesAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (badges) => _AchievementBadgeList(badges: badges),
    );
  }
}

class _AchievementBadgeList extends StatelessWidget {
  const _AchievementBadgeList({required this.badges});

  final List<AchievementBadge> badges;

  @override
  Widget build(BuildContext context) {
    final sorted = [...badges]
      ..sort((a, b) {
        if (a.isUnlocked == b.isUnlocked) {
          return a.threshold.compareTo(b.threshold);
        }
        return a.isUnlocked ? -1 : 1;
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('成就徽章', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              const Text('开始写作后，徽章会在这里慢慢点亮。')
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final badge in sorted)
                    SizedBox(
                      width: 260,
                      child: AchievementBadgeCard(badge: badge),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

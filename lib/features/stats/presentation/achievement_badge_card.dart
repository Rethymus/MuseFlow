import 'package:flutter/material.dart';
import 'package:museflow/features/stats/domain/achievement_badge.dart';

class AchievementBadgeCard extends StatelessWidget {
  const AchievementBadgeCard({super.key, required this.badge});

  final AchievementBadge badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnlocked = badge.isUnlocked;
    final progress = badge.threshold == 0
        ? 0.0
        : (badge.progress / badge.threshold).clamp(0.0, 1.0);

    return Card(
      color: isUnlocked
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUnlocked ? Icons.workspace_premium : Icons.lock_outline,
                  color: isUnlocked
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    badge.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(badge.description),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 6),
            Text(
              isUnlocked ? '已点亮' : '${badge.progress}/${badge.threshold}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

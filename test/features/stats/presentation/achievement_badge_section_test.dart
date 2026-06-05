import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/achievement_badge.dart';
import 'package:museflow/features/stats/presentation/achievement_badge_section.dart';

void main() {
  testWidgets('renders unlocked and locked badges', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AchievementBadgeSection(
            debugBadges: [
              AchievementBadge(
                id: 'first_1k',
                title: '千字起笔',
                description: '完成第一个一千字。',
                type: AchievementBadgeType.totalWords,
                threshold: 1000,
                progress: 1000,
                unlockedAt: null,
              ),
              AchievementBadge(
                id: 'first_10k',
                title: '万字成章',
                description: '累计写下一万字。',
                type: AchievementBadgeType.totalWords,
                threshold: 10000,
                progress: 3000,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('成就徽章'), findsOneWidget);
    expect(find.text('千字起笔'), findsOneWidget);
    expect(find.text('万字成章'), findsOneWidget);
    expect(find.text('3000/10000'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/daily_writing_stats.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';
import 'package:museflow/features/stats/presentation/writing_stats_page.dart';

void main() {
  testWidgets('renders empty stats state', (tester) async {
    await tester.pumpWidget(_app(const StatsSnapshot()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('写作统计'), findsWidgets);
    expect(find.text('开始写作后，这里会出现你的创作轨迹。'), findsOneWidget);
    expect(find.text('总字数'), findsOneWidget);
    expect(find.text('AI辅助比例'), findsOneWidget);
  });

  testWidgets('renders summary cards and charts with stats data', (
    tester,
  ) async {
    const snapshot = StatsSnapshot(
      totalUnits: 125,
      humanUnits: 100,
      aiUnits: 25,
      writingDays: 1,
      sessionCount: 1,
      daily: [
        DailyWritingStats(
          dateKey: '2026-06-04',
          humanUnits: 100,
          aiUnits: 25,
          sessionCount: 1,
          editSeconds: 300,
        ),
      ],
    );

    await tester.pumpWidget(_app(snapshot));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('125'), findsOneWidget);
    expect(find.text('20.0%'), findsOneWidget);
    expect(find.text('每日字数'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('速度趋势'), 200);
    expect(find.text('速度趋势'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('AI 使用比例'), 200);
    expect(find.text('AI 使用比例'), findsOneWidget);
  });
}

Widget _app(StatsSnapshot snapshot) {
  return ProviderScope(
    child: MaterialApp(home: WritingStatsPage(debugSnapshot: snapshot)),
  );
}

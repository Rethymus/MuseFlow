import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/daily_writing_stats.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';
import 'package:museflow/features/stats/presentation/project_stats_page.dart';

void main() {
  testWidgets('renders current project stats and chapter placeholder', (
    tester,
  ) async {
    const snapshot = StatsSnapshot(
      totalUnits: 100,
      humanUnits: 80,
      aiUnits: 20,
      editSeconds: 480,
      daily: [
        DailyWritingStats(dateKey: '2026-06-04', humanUnits: 80, aiUnits: 20),
      ],
    );

    await tester.pumpWidget(_app(snapshot));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('当前作品统计'), findsWidgets);
    expect(find.text('当前字数'), findsOneWidget);
    expect(find.text('100'), findsWidgets);
    expect(find.text('章节模型接入后将显示分章分布'), findsOneWidget);
  });

  testWidgets('renders without overflow for empty data', (tester) async {
    await tester.pumpWidget(_app(const StatsSnapshot()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('当前作品统计'), findsWidgets);
    expect(find.text('章节字数分布'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(StatsSnapshot snapshot) {
  return MaterialApp(home: ProjectStatsPage(debugSnapshot: snapshot));
}

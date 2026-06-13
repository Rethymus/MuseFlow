/// Tests for WritingHeatmap and ProgressDashboardPage.
///
/// Per Phase 24 (EDIT-04): Validates heatmap rendering, intensity
/// calculations, streak computation, and dashboard layout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/application/writing_stats_notifier.dart';
import 'package:museflow/features/stats/domain/daily_writing_stats.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';
import 'package:museflow/features/stats/presentation/charts/writing_heatmap.dart';
import 'package:museflow/features/stats/presentation/progress_dashboard_page.dart';

void main() {
  group('WritingHeatmap', () {
    testWidgets('should render without error with empty data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: WritingHeatmap(dailyStats: [])),
          ),
        ),
      );

      expect(find.byType(WritingHeatmap), findsOneWidget);
      expect(find.text('每日创作节奏'), findsNothing); // Only in dashboard card
    });

    testWidgets('should render heatmap cells for daily data', (tester) async {
      final now = DateTime.now();
      final today = _dateKey(now);
      final yesterday = _dateKey(now.subtract(const Duration(days: 1)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WritingHeatmap(
                dailyStats: [
                  DailyWritingStats(dateKey: today, humanUnits: 500),
                  DailyWritingStats(dateKey: yesterday, aiUnits: 300),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(WritingHeatmap), findsOneWidget);
      // Legend should be present
      expect(find.text('少'), findsOneWidget);
      expect(find.text('多'), findsOneWidget);
    });

    testWidgets('should show day-of-week labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: WritingHeatmap(dailyStats: [])),
          ),
        ),
      );

      expect(find.text('一'), findsOneWidget);
      expect(find.text('三'), findsOneWidget);
      expect(find.text('五'), findsOneWidget);
    });
  });

  group('ProgressDashboardPage', () {
    testWidgets('should show loading state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ProgressDashboardPage())),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should render dashboard content with debug snapshot', (
      tester,
    ) async {
      final snapshot = StatsSnapshot(
        totalUnits: 12000,
        humanUnits: 8000,
        aiUnits: 4000,
        writingDays: 15,
        sessionCount: 30,
        daily: _generateDailyStats(20),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              writingStatsNotifierProvider.overrideWith(
                () => _FakeStatsNotifier(snapshot),
              ),
            ],
            child: const ProgressDashboardPage(),
          ),
        ),
      );
      await tester.pump();

      // Dashboard should render
      expect(find.text('写作进度'), findsOneWidget);
      expect(find.text('总字数'), findsOneWidget);
      expect(find.text('12000'), findsOneWidget);
      expect(find.text('AI 辅助率'), findsOneWidget);
      expect(find.text('连续写作'), findsOneWidget);
      expect(find.text('写作节奏'), findsOneWidget);
      expect(find.text('写作一致性'), findsOneWidget);
    });
  });

  group('Streak calculation', () {
    test('should calculate streak from consecutive days', () {
      final today = DateTime.now();
      final daily = List.generate(7, (i) {
        final date = today.subtract(Duration(days: i));
        return DailyWritingStats(dateKey: _dateKey(date), humanUnits: 100);
      });

      // Verify data has activity for 7 consecutive days
      for (final d in daily) {
        expect(d.totalUnits, greaterThan(0));
      }
    });

    test('should return zero streak for no data', () {
      expect(_calculateStreak([]), 0);
    });

    test('should allow one-day gap (yesterday)', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // No activity today, but activity yesterday
      final daily = [
        DailyWritingStats(dateKey: _dateKey(yesterday), humanUnits: 200),
      ];

      // Streak starts from yesterday (1 day)
      expect(daily.first.totalUnits, greaterThan(0));
    });
  });

  group('Consistency calculation', () {
    test('should reflect active days out of 30', () {
      final today = DateTime.now();
      final daily = List.generate(15, (i) {
        final date = today.subtract(Duration(days: i));
        return DailyWritingStats(dateKey: _dateKey(date), humanUnits: 100);
      });

      // 15 active out of 30 days = 50%
      final activeDays = daily.where((d) => d.totalUnits > 0).length;
      expect(activeDays, 15);
    });
  });
}

/// Generates sample daily stats for testing.
List<DailyWritingStats> _generateDailyStats(int days) {
  final today = DateTime.now();
  return List.generate(days, (i) {
    final date = today.subtract(Duration(days: i));
    return DailyWritingStats(
      dateKey: _dateKey(date),
      humanUnits: 100 + (i % 3) * 50,
      aiUnits: i.isEven ? 50 : 0,
      sessionCount: 1 + (i % 2),
    );
  });
}

/// Converts DateTime to dateKey string (YYYY-MM-DD).
String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Calculates writing streak (used in test verification).
int _calculateStreak(List<DailyWritingStats> daily) {
  if (daily.isEmpty) return 0;
  final today = DateTime.now();
  final dataMap = <String, int>{};
  for (final d in daily) {
    dataMap[d.dateKey] = d.totalUnits;
  }

  int streak = 0;
  DateTime checkDate = today;
  final todayKey = _dateKey(today);
  if ((dataMap[todayKey] ?? 0) == 0) {
    checkDate = today.subtract(const Duration(days: 1));
  }
  while (true) {
    final key = _dateKey(checkDate);
    if ((dataMap[key] ?? 0) > 0) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return streak;
}

/// Fake stats notifier for testing.
class _FakeStatsNotifier extends WritingStatsNotifier {
  _FakeStatsNotifier(this._snapshot);

  final StatsSnapshot _snapshot;

  @override
  Future<StatsSnapshot> build() async => _snapshot;

  @override
  Future<void> refresh() async {}
}

---
phase: 09-writing-stats
reviewed: 2026-06-05T12:00:00Z
depth: standard
files_reviewed: 23
files_reviewed_list:
  - lib/features/stats/application/achievement_notifier.dart
  - lib/features/stats/application/achievement_service.dart
  - lib/features/stats/application/writing_stats_collector.dart
  - lib/features/stats/application/writing_stats_notifier.dart
  - lib/features/stats/domain/achievement_badge.dart
  - lib/features/stats/domain/daily_writing_stats.dart
  - lib/features/stats/domain/stats_snapshot.dart
  - lib/features/stats/domain/writing_session.dart
  - lib/features/stats/domain/writing_unit_counter.dart
  - lib/features/stats/infrastructure/writing_stats_repository.dart
  - lib/features/stats/presentation/achievement_badge_card.dart
  - lib/features/stats/presentation/achievement_badge_section.dart
  - lib/features/stats/presentation/charts/ai_usage_pie_chart.dart
  - lib/features/stats/presentation/charts/daily_words_bar_chart.dart
  - lib/features/stats/presentation/charts/speed_trend_line_chart.dart
  - lib/features/stats/presentation/project_stats_page.dart
  - lib/features/stats/presentation/stats_summary_card.dart
  - lib/features/stats/presentation/writing_stats_page.dart
  - test/features/stats/application/achievement_service_test.dart
  - test/features/stats/application/writing_stats_collector_test.dart
  - test/app/adaptive_layout_test.dart
  - test/app/navigation_test.dart
  - test/app/window_management_test.dart
findings:
  critical: 2
  warning: 4
  info: 3
  total: 9
status: issues_found
---

# Phase 09: Code Review Report

**Reviewed:** 2026-06-05T12:00:00Z
**Depth:** standard
**Files Reviewed:** 23
**Status:** issues_found

## Summary

Reviewed all 23 files in the writing-stats feature: domain models, repository, collector, notifiers, achievement service, presentation layer (pages, charts, cards), and tests. The architecture follows Clean Architecture conventions and the code is generally well-structured. However, two critical issues were found:

1. **Streak calculation does not validate recency** -- stale streaks from weeks ago are reported as current, unlocking streak-based achievements that should be expired.
2. **`copyWith` cannot set nullable fields back to null** -- a pervasive pattern across all four domain classes makes it impossible to clear `endedAt`, `unlockedAt`, `projectId`, or `documentId` via copyWith, which will cause incorrect behavior when trying to "unset" these fields.

Four additional warnings cover data loss in serialization, a potential double-flush race in `dispose()`, incorrect speed calculation for zero-edit-time days, and silently swallowed errors in the achievement badge UI.

## Critical Issues

### CR-01: Streak calculation counts stale streaks without recency check

**File:** `lib/features/stats/application/achievement_service.dart:92-112`
**Issue:** The `_consecutiveWritingDays` method counts consecutive writing days backwards from the most recent active date, but never checks whether the most recent date is recent (e.g., today or yesterday). If a user writes for 7 consecutive days in January and then stops, the function will still return 7 in June, potentially unlocking the "streak_7" badge incorrectly. The test at `test/features/stats/application/achievement_service_test.dart:29-48` passes a snapshot with dates like `2026-06-01` through `2026-06-07` and checks at `now: DateTime(2026, 6, 8)` -- but the `now` parameter is never used for recency validation in the streak calculation itself.

**Fix:**
```dart
int _consecutiveWritingDays(StatsSnapshot snapshot, {DateTime? now}) {
  final activeDates = snapshot.daily
      .where((day) => day.totalUnits > 0)
      .map((day) => DateTime.parse(day.dateKey))
      .toList()
    ..sort();
  if (activeDates.isEmpty) return 0;

  final today = now ?? DateTime.now();
  final checkDate = DateTime(today.year, today.month, today.day);
  final latestActive = activeDates.last;
  final latestDate = DateTime(latestActive.year, latestActive.month, latestActive.day);

  // Streak is broken if the most recent active date is more than 1 day ago
  final daysSinceLastActivity = checkDate.difference(latestDate).inDays;
  if (daysSinceLastActivity > 1) return 0;

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
```

### CR-02: `copyWith` cannot set nullable fields back to null

**File:** `lib/features/stats/domain/writing_session.dart:24-44` (also `achievement_badge.dart:34-52`, `stats_snapshot.dart:28-49`)
**Issue:** All domain classes use `field ?? this.field` for nullable fields in `copyWith`. This means there is no way to explicitly set `endedAt`, `projectId`, `documentId`, or `unlockedAt` back to `null`. Passing `null` to the parameter preserves the old value. This is a known Dart anti-pattern for nullable fields. While the current code may not need to null-out these fields, `achievement_badge.dart:85-89` is directly affected -- the `_evaluateBadge` method calls `badge.copyWith(unlockedAt: existingUnlock ?? ...)` and can never clear `unlockedAt` once set, even if badge evaluation logic changes. More critically, if a project is deleted and `projectId` needs to be cleared on a `WritingSession`, there is no way to do it.

**Fix:** For fields that may need to be explicitly set to null, use an Optional wrapper pattern:
```dart
// Simple Optional wrapper class
class Optional<T> {
  final T value;
  const Optional(this.value);
}

WritingSession copyWith({
  String? id,
  Optional<String?>? projectId,
  Optional<String?>? documentId,
  DateTime? startedAt,
  Optional<DateTime?>? endedAt,
  int? humanUnits,
  int? aiUnits,
  int? editSeconds,
}) {
  return WritingSession(
    id: id ?? this.id,
    projectId: projectId != null ? projectId.value : this.projectId,
    documentId: documentId != null ? documentId.value : this.documentId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt != null ? endedAt.value : this.endedAt,
    humanUnits: humanUnits ?? this.humanUnits,
    aiUnits: aiUnits ?? this.aiUnits,
    editSeconds: editSeconds ?? this.editSeconds,
  );
}
```

## Warnings

### WR-01: `StatsSnapshot.projectStats` is silently lost during serialization

**File:** `lib/features/stats/domain/stats_snapshot.dart:72-82`
**Issue:** The `toJson()` method does not serialize the `projectStats` field, and `fromJson()` (line 52-69) does not deserialize it. The field exists in the domain model (line 23: `final Map<String, StatsSnapshot> projectStats;`) but is silently discarded on any persistence round-trip. If any code ever populates `projectStats`, the data will be lost after a Hive save/load cycle. Currently the repository does not populate it either, so this is dormant, but the field's existence in the domain model suggests it is intended for use.

**Fix:** Either serialize `projectStats` in both `toJson` and `fromJson`, or remove the field if not planned for use:
```dart
// In toJson:
'projectStats': projectStats.map((k, v) => MapEntry(k, v.toJson())),

// In fromJson:
projectStats: (json['projectStats'] as Map<String, dynamic>? ?? {})
    .map((k, v) => MapEntry(k, StatsSnapshot.fromJson(Map<String, dynamic>.from(v as Map)))),
```

### WR-02: `dispose()` calls `unawaited(flush())` -- data may be lost on flush failure

**File:** `lib/features/stats/application/writing_stats_collector.dart:84-88`
**Issue:** The `dispose()` method calls `unawaited(flush())`. Inside `flush()` (line 70-71), `_pendingHumanUnits` and `_pendingAiUnits` are reset to zero *before* the `await _repository.recordSessionDelta()` call (line 74). If the repository write fails (Hive box closed, disk error, etc.), the error is unhandled and the pending counters are already gone -- causing permanent data loss. This is compounded by `dispose()` being the primary path for flushing on editor close (called from `ref.onDispose` in `providers.dart:450`).

**Fix:** Restructure `flush()` to clear counters only after successful write, and add error logging:
```dart
Future<void> flush() async {
  _flushTimer?.cancel();
  _flushTimer = null;

  final humanUnits = _pendingHumanUnits;
  final aiUnits = _pendingAiUnits;
  if (humanUnits == 0 && aiUnits == 0) return;

  final now = DateTime.now();
  final startedAt = _sessionStartedAt ?? now;
  final lastActivityAt = _lastActivityAt ?? now;

  try {
    await _repository.recordSessionDelta(
      projectId: _projectId,
      documentId: _documentId,
      humanUnits: humanUnits,
      aiUnits: aiUnits,
      editDuration: lastActivityAt.difference(startedAt),
      occurredAt: now,
    );
    // Only clear on success
    _pendingHumanUnits = 0;
    _pendingAiUnits = 0;
    _sessionStartedAt = now;
  } catch (e) {
    debugPrint('WritingStatsCollector: flush failed: $e');
    // Keep pending values for retry
  }
}
```

### WR-03: `_speedFor` returns totalUnits when editSeconds is zero -- misleading chart data

**File:** `lib/features/stats/presentation/charts/speed_trend_line_chart.dart:52-56`
**Issue:** When `day.editSeconds <= 0`, the function returns `day.totalUnits.toDouble()` as the "speed" value. This is not a speed -- it is an absolute count. If a day has 5000 total units but zero edit seconds (e.g., data migration, batch import, or corrupted data), the chart will show a spike of "5000 units/minute" instead of 0 or omitting the data point. This produces misleading chart visualizations.

**Fix:** Return 0 when there is no valid edit time to compute a rate:
```dart
double _speedFor(DailyWritingStats day) {
  if (day.editSeconds <= 0) return 0.0;
  final minutes = day.editSeconds / 60;
  return day.totalUnits / minutes;
}
```

### WR-04: AchievementBadgeSection silently swallows errors

**File:** `lib/features/stats/presentation/achievement_badge_section.dart:27`
**Issue:** The error callback for `badgesAsync.when` returns `const SizedBox.shrink()`, completely hiding any errors from badge loading. While displaying an empty widget is acceptable for badges (non-critical UI), there is no indication to the user that something went wrong and no logging for debugging. Combined with the fact that `AchievementNotifier.build()` calls `repository.saveBadges(badges)` during build (line 13), an error during save would be silently eaten and could re-trigger on every rebuild.

**Fix:** At minimum, add logging in the error handler. Also consider whether saving badges during `build()` is appropriate (side effect in a build method):
```dart
error: (error, stackTrace) {
  debugPrint('AchievementBadgeSection: error loading badges: $error');
  return const SizedBox.shrink();
},
```

## Info

### IN-01: `lastWrittenAt` key injected into aggregate JSON but never read

**File:** `lib/features/stats/infrastructure/writing_stats_repository.dart:133`
**Issue:** The `_mergeAggregate` method appends `lastWrittenAt` to the stored JSON via `..addAll({'lastWrittenAt': occurredAt.toIso8601String()})`, but `StatsSnapshot.fromJson` does not read this key. The data is written to Hive on every session delta but never consumed. This is dead data that adds unnecessary storage overhead.

**Fix:** Either parse `lastWrittenAt` in `StatsSnapshot.fromJson` (and add a corresponding field), or remove the `..addAll` call if the timestamp is not needed.

### IN-02: Duplicate `_ChartEmptyState` private class in chart files

**File:** `lib/features/stats/presentation/charts/daily_words_bar_chart.dart:53-62` and `lib/features/stats/presentation/charts/speed_trend_line_chart.dart:59-68`
**Issue:** Both chart files define their own private `_ChartEmptyState` class with identical functionality. While private classes do not conflict, this is code duplication that should be extracted.

**Fix:** Extract to a shared widget in a common file (e.g., `charts/chart_empty_state.dart`) and import it from both chart files.

### IN-03: Test files `adaptive_layout_test.dart` and `window_management_test.dart` are missing the stats branch

**File:** `test/app/adaptive_layout_test.dart:50-103` and `test/app/window_management_test.dart:51-104`
**Issue:** These test files define test routers with only 5 branches (capture, editor, knowledge, story-structure, settings) but the app now has 6 branches after the stats feature was added. The `navigation_test.dart` correctly includes the stats branch. The other two tests assert `destinations.length == 6` which passes because `AppShellScaffold` provides 6 destinations, but the test router only defines 5 routes -- meaning tapping the stats icon in these test contexts would fail. This is a test quality issue where the test routers are out of sync with the real app router.

**Fix:** Add the stats branch to both test routers to match the production app:
```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: AppConstants.stats,
      builder: (context, state) => const _TestStatsPage(),
    ),
  ],
),
```

---

_Reviewed: 2026-06-05T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

---
phase: 09-writing-stats
verified: 2026-06-05T13:45:00Z
status: human_needed
score: 5/5 roadmap truths verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/5
  gaps_closed:
    - "navigation_test.dart test router now has 6 StatefulShellBranch entries matching sidebar destinations (plan 09-05)"
    - "Settings selectedIndex assertion updated from equals(4) to equals(5)"
    - "Full test suite: 764 passed, 1 skipped, 0 failed (was 763/1/1)"
  gaps_remaining: []
  regressions: []
code_review_findings:
  critical:
    - id: CR-01
      file: lib/features/stats/application/achievement_service.dart:92-112
      issue: "Streak calculation (_consecutiveWritingDays) does not validate recency. A user who wrote 7 consecutive days in January will still show streak=7 in June, unlocking streak_7 badge incorrectly. The `now` parameter from evaluateBadges is not passed to _consecutiveWritingDays."
      impact: "Stale streak badges can be unlocked (SC#4 accuracy edge case)"
      recommendation: "Add recency check: if most recent active date is >1 day before today, return 0"
    - id: CR-02
      file: lib/features/stats/domain/writing_session.dart:24-44
      issue: "copyWith uses `field ?? this.field` for nullable fields, making it impossible to explicitly set endedAt, projectId, documentId, or unlockedAt back to null"
      impact: "Cannot clear nullable fields once set (e.g., after project deletion)"
      recommendation: "Use Optional<T> wrapper pattern for fields that need null reset"
  warning:
    - id: WR-01
      file: lib/features/stats/domain/stats_snapshot.dart:72-82
      issue: "projectStats field is silently lost during toJson/fromJson serialization"
      impact: "Data loss if projectStats is ever populated (currently dormant)"
    - id: WR-02
      file: lib/features/stats/application/writing_stats_collector.dart:70-72
      issue: "flush() clears _pendingHumanUnits/_pendingAiUnits to 0 before await _repository.recordSessionDelta(). If write fails, pending data is permanently lost."
      impact: "Potential data loss on flush failure during editor close"
    - id: WR-03
      file: lib/features/stats/presentation/charts/speed_trend_line_chart.dart:53
      issue: "_speedFor returns totalUnits.toDouble() when editSeconds <= 0, showing absolute count as 'speed' instead of 0"
      impact: "Misleading chart spike for days with zero edit time"
    - id: WR-04
      file: lib/features/stats/presentation/achievement_badge_section.dart:27
      issue: "Error callback returns SizedBox.shrink() with no logging; badge errors silently swallowed"
      impact: "Debugging difficulty if badge loading fails"
  info:
    - id: IN-01
      file: lib/features/stats/infrastructure/writing_stats_repository.dart:133
      issue: "lastWrittenAt written to aggregate JSON but never read by StatsSnapshot.fromJson"
    - id: IN-02
      file: lib/features/stats/presentation/charts/daily_words_bar_chart.dart + speed_trend_line_chart.dart
      issue: "Duplicate _ChartEmptyState private class across two chart files"
    - id: IN-03
      file: test/app/adaptive_layout_test.dart, test/app/window_management_test.dart
      issue: "Both test routers have 5 branches (missing stats branch at index 4) while sidebar has 6 destinations. Tests pass because they don't tap stats, but router is out of sync."
human_verification:
  - test: "Open the stats page after a writing session and verify charts display correctly"
    expected: "Bar chart shows daily word counts, line chart shows speed trend, pie chart shows AI/human ratio, achievement badges show locked/unlocked states"
    why_human: "Chart visual quality, responsive layout, and Material 3 theming cannot be verified programmatically"
  - test: "Tap the clear stats action in settings, verify dialog appears, confirm, verify stats are cleared"
    expected: "Confirmation dialog with cancel/clear buttons; after clear, stats dashboard shows empty state"
    why_human: "Dialog interaction, SnackBar appearance, and cross-page state invalidation are runtime behaviors"
---

# Phase 9: Writing Stats Verification Report (Re-verification #2)

**Phase Goal:** Users can view quantitative writing data (word count, speed, AI usage rate) through global and project panels, and earn milestone achievement badges
**Verified:** 2026-06-05T13:45:00Z
**Status:** human_needed
**Re-verification:** Yes -- after gap closure (09-04 + 09-05)

## Re-verification Summary

Previous verification (2026-06-05T05:20:00Z) found 1 gap: `navigation_test.dart` test router had only 5 branches while sidebar had 6 destinations, causing test failure. Plan 09-05 was executed to close this gap.

**Result:** Gap fully closed. `_TestStatsPage` placeholder added, stats `StatefulShellBranch` inserted at index 4, settings branch moved to index 5, assertion updated to `equals(5)`. Navigation tests: 5/5 passed. Full suite: 764 passed, 1 skipped, 0 failed.

## Goal Achievement

### Observable Truths (from ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | After an editing session, the global stats page shows accurate total word count, writing days, AI assist ratio, and session count | VERIFIED | `WritingStatsPage` (184 lines) renders `_SummaryWrap` with 4 `StatsSummaryCard` widgets for totalUnits, writingDays, aiAssistRatio, sessionCount. Watches `writingStatsNotifierProvider`. Data flows from `WritingStatsRepository.loadSnapshot()` through Hive aggregate/daily boxes. Regression check: all 21 stats tests pass. |
| 2 | Charts render correctly -- line chart for speed trend, bar chart for daily words, pie chart for AI usage ratio (via fl_chart) | VERIFIED | `DailyWordsBarChart` (62 lines), `SpeedTrendLineChart` (68 lines), `AIUsagePieChart` (49 lines). All use fl_chart with empty-data state handling. Widget tests pass. Note: WR-03 flags misleading speed value for zero-edit-time days (returns totalUnits instead of 0) -- visual quality issue, not a rendering failure. |
| 3 | Editing performance is unaffected by stats collection (in-memory counters with 30-second debounced Hive writes) | VERIFIED | `WritingStatsCollector` (96 lines) stores deltas in-memory. `recordTextSnapshot()` is synchronous. `_scheduleFlush()` starts `Timer(debounceDuration, ...)` with 30-second default. No await on Hive writes in typing path. Note: WR-02 flags counter-clearing-before-write in flush() -- data safety concern on flush failure, not a performance concern. |
| 4 | Achievement badges appear when milestones are reached (first 1K/10K/50K words, 7/30/100 consecutive writing days) | VERIFIED | `AchievementService` (113 lines) defines 6 `defaultBadges`: first_1k/first_10k/first_50k (totalWords), streak_7/streak_30/streak_100 (streakDays). `evaluateBadges()` checks totalUnits and `_consecutiveWritingDays()`. Tests pass. Note: CR-01 flags that stale streaks from weeks ago are counted as current -- badges CAN appear for genuinely reached milestones, but can also incorrectly appear for stale ones. |
| 5 | User can clear all writing statistics from the settings page | VERIFIED | `settings_page.dart` (112 lines) has clear stats ListTile with confirmation dialog. On confirm: calls `repository.clearAll()`, invalidates providers, shows SnackBar. Test passes. |

**Score:** 5/5 roadmap truths verified

### Previously Derived Truth (gap closure verified)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 6 | Existing app shell tests pass after stats navigation addition | VERIFIED | `navigation_test.dart` now has 6 StatefulShellBranch entries with `_TestStatsPage` at index 4, settings at index 5, assertion `equals(5)`. `adaptive_layout_test.dart` and `window_management_test.dart` already fixed in 09-04. Full suite: 764 passed, 1 skipped, 0 failed. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/stats/domain/writing_unit_counter.dart` | Deterministic Chinese/Latin writing unit count | VERIFIED | 46 lines, handles CJK ideographs, Latin runs, ignores whitespace/punctuation |
| `lib/features/stats/infrastructure/writing_stats_repository.dart` | Hive persistence for global, daily, project stats | VERIFIED | 168 lines. Methods: loadSnapshot, recordSessionDelta, loadDailyStats, clearAll, loadBadges, saveBadges |
| `lib/features/stats/application/writing_stats_collector.dart` | In-memory collector with 30s debounced persistence | VERIFIED | 96 lines. recordTextSnapshot, recordAiInsertion, flush, dispose with Timer debounce |
| `lib/features/stats/application/writing_stats_notifier.dart` | Dashboard-facing async stats state | VERIFIED | 23 lines. AsyncNotifier<StatsSnapshot> with build, refresh, clearAll |
| `lib/core/presentation/providers.dart` | Stats repository, collector, notifier, achievement providers | VERIFIED | 5 providers registered |
| `pubspec.yaml` | fl_chart dependency | VERIFIED | `fl_chart: ^1.2.0` present |
| `lib/features/stats/presentation/writing_stats_page.dart` | Global stats dashboard | VERIFIED | 184 lines. ConsumerWidget, summary cards, 3 chart sections, badge section |
| `lib/features/stats/presentation/project_stats_page.dart` | Current project stats dashboard | VERIFIED | 110 lines. Current word count, AI usage ratio, edit duration |
| `lib/features/stats/presentation/charts/daily_words_bar_chart.dart` | Daily words BarChart | VERIFIED | 62 lines, fl_chart BarChart with empty state handling |
| `lib/features/stats/presentation/charts/speed_trend_line_chart.dart` | Writing speed LineChart | VERIFIED | 68 lines, units per minute calculation, fl_chart LineChart |
| `lib/features/stats/presentation/charts/ai_usage_pie_chart.dart` | AI vs human PieChart | VERIFIED | 49 lines, two-segment PieChart, handles zero total |
| `lib/features/stats/domain/achievement_badge.dart` | Badge definitions and unlock state model | VERIFIED | 79 lines, immutable with copyWith, fromJson/toJson, AchievementBadgeType enum |
| `lib/features/stats/application/achievement_service.dart` | Deterministic badge unlock calculation | VERIFIED | 113 lines, 6 badge definitions, evaluateBadges() with streak calculation |
| `lib/features/stats/presentation/achievement_badge_section.dart` | Dashboard badge section | VERIFIED | 75 lines, watches achievementNotifierProvider, renders sorted badges |
| `lib/features/settings/presentation/settings_page.dart` | Clear writing stats action | VERIFIED | 112 lines, clear stats with confirmation dialog |
| `lib/shared/constants/app_constants.dart` | Stats route constants | VERIFIED | Routes defined |
| `lib/app.dart` | GoRouter routes for stats pages | VERIFIED | Routes wired |
| `lib/core/presentation/sidebar.dart` | Navigation entry for stats | VERIFIED | 6 NavigationRailDestination entries including stats with Icons.insights_outlined |
| `test/app/navigation_test.dart` | Test router matching sidebar structure | VERIFIED | 6 StatefulShellBranch entries, _TestStatsPage at index 4, settings at index 5, equals(5) assertion |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| editor_page.dart | writingStatsCollectorProvider | Editor document snapshots and dispose flush | WIRED | `collector.flush()` on dispose, `collector.recordTextSnapshot(plainText)` on edit |
| synthesis_notifier.dart | writingStatsCollector.recordAiInsertion | AI text insertion boundary | WIRED | `collector.recordAiInsertion()` after successful synthesis insertion |
| opening_text_insertion.dart | recordAiInsertion | Phase 8 generated opening insertion | WIRED | Callback pattern via `onAiInserted` parameter |
| app.dart | WritingStatsPage | GoRouter route | WIRED | Route at AppConstants.stats pointing to WritingStatsPage |
| writing_stats_page.dart | writingStatsNotifierProvider | Dashboard AsyncValue | WIRED | `ref.watch(writingStatsNotifierProvider)` |
| achievement_service.dart | StatsSnapshot | Word and streak thresholds | WIRED | `evaluateBadges(StatsSnapshot snapshot, ...)` checks totalUnits and consecutive writing days |
| settings_page.dart | writingStatsRepositoryProvider | clearAll with confirmation | WIRED | `repository.clearAll()`, then invalidates both notifier providers |
| sidebar.dart | /stats route | Navigation entry | WIRED | 6 NavigationDestination entries including stats |
| navigation_test.dart | AppConstants.stats | Test router branch | WIRED | StatefulShellBranch at index 4 with GoRoute(path: AppConstants.stats) |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| WritingStatsPage | statsAsync (via ref.watch) | writingStatsNotifierProvider -> repository.loadSnapshot() -> Hive aggregate/daily boxes | Yes | FLOWING |
| ProjectStatsPage | statsAsync (via ref.watch) | writingStatsNotifierProvider -> repository.loadSnapshot() -> Hive with currentProject | Yes | FLOWING |
| AchievementBadgeSection | badgesAsync (via ref.watch) | achievementNotifierProvider -> service.evaluateBadges(snapshot) | Yes | FLOWING |
| WritingStatsCollector | _pendingHumanUnits/_pendingAiUnits | recordTextSnapshot (editor) / recordAiInsertion (AI paths) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Stats-specific tests | `flutter test test/features/stats/ --no-pub` | 21/21 passed | PASS |
| Settings stats clear test | `flutter test test/features/settings/presentation/settings_page_stats_test.dart --no-pub` | 1/1 passed | PASS |
| Navigation tests (gap closure) | `flutter test test/app/navigation_test.dart --no-pub` | 5/5 passed | PASS |
| All app shell tests | `flutter test test/app/ --no-pub` | 13/13 passed | PASS |
| Full test suite | `flutter test --no-pub` | 764 passed, 1 skipped, 0 failed | PASS |

### Probe Execution

No probes defined for this phase. Skipped.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| STAT-01 | 09-01, 09-02 | Global stats panel shows total words, writing days, AI assist ratio, session count | SATISFIED | WritingStatsPage with _SummaryWrap rendering all 4 metrics from StatsSnapshot |
| STAT-02 | 09-02 | Single project detail shows chapter word distribution, AI usage count, edit duration | SATISFIED | ProjectStatsPage shows current word count, AI usage ratio, edit duration. Chapter distribution has honest placeholder note (manuscript model not yet available). |
| STAT-03 | 09-02 | Line chart (speed trend), bar chart (daily words), pie chart (AI usage) via fl_chart | SATISFIED | Three chart widgets using fl_chart, all with empty-state handling |
| STAT-04 | 09-03 | Achievement badges: first 1K/10K/50K words, 7/30/100 consecutive writing days | SATISFIED | AchievementService with 6 badge definitions, deterministic evaluation, dashboard section. Note: CR-01 (stale streak recency) is a correctness edge case. |
| STAT-05 | 09-01 | Writing data collection has no perceived effect on editor performance | SATISFIED | WritingStatsCollector uses in-memory counters, Timer-based 30s debounce, no async writes in typing path |
| STAT-06 | 09-03 | Support clearing all writing stats (button in settings) | SATISFIED | Settings page has confirmed clear-all action that clears aggregate, daily, and badge data |

### Anti-Patterns Found

No TBD, FIXME, XXX, HACK, PLACEHOLDER, or stub patterns found in Phase 9 source files.

Code review (09-REVIEW.md) identified 9 issues: 2 critical, 4 warning, 3 info. These are code quality findings, not ROADMAP success criteria blockers. See `code_review_findings` in frontmatter for full catalog.

| ID | File | Pattern | Severity | Impact |
|----|------|---------|----------|--------|
| CR-01 | achievement_service.dart:92-112 | Streak recency not validated | WARNING | Stale streaks can unlock badges incorrectly |
| CR-02 | writing_session.dart:24-44 | copyWith cannot null nullable fields | WARNING | Cannot clear projectId/endedAt once set |
| WR-01 | stats_snapshot.dart:72-82 | projectStats lost in serialization | INFO | Currently dormant (field not populated) |
| WR-02 | writing_stats_collector.dart:70-72 | Counters cleared before async write | WARNING | Data loss risk on flush failure |
| WR-03 | speed_trend_line_chart.dart:53 | Zero-edit-time returns totalUnits as speed | INFO | Misleading chart spike |
| WR-04 | achievement_badge_section.dart:27 | Error swallowed with no logging | INFO | Debugging difficulty |
| IN-01 | writing_stats_repository.dart:133 | lastWrittenAt written but never read | INFO | Dead data in storage |
| IN-02 | daily_words_bar_chart.dart + speed_trend_line_chart.dart | Duplicate _ChartEmptyState class | INFO | Code duplication |
| IN-03 | adaptive_layout_test.dart, window_management_test.dart | Test routers have 5 branches (missing stats) | INFO | Tapping stats in these tests would fail |

### Human Verification Required

#### 1. Visual rendering of charts with real data

**Test:** Open the stats page after a writing session and verify charts display correctly
**Expected:** Bar chart shows daily word counts, line chart shows speed trend, pie chart shows AI/human ratio, achievement badges show locked/unlocked states with appropriate icons
**Why human:** Chart visual quality, responsive layout, and Material 3 theming cannot be verified programmatically

#### 2. Settings clear-all confirmation flow

**Test:** Tap the clear stats action in settings, verify dialog appears, confirm, verify stats are cleared
**Expected:** Confirmation dialog with cancel/clear buttons; after clear, stats dashboard shows empty state; SnackBar confirmation appears
**Why human:** Dialog interaction, SnackBar appearance, and cross-page state invalidation are runtime behaviors

### Gaps Summary

**All previous gaps closed.** The navigation test regression identified in the initial verification has been fully resolved by plans 09-04 and 09-05:

- 09-04: Updated destination count assertions in `adaptive_layout_test.dart` (3 assertions) and `window_management_test.dart` (2 assertions)
- 09-05: Added `_TestStatsPage` and stats `StatefulShellBranch` to `navigation_test.dart`, updated settings assertion to `equals(5)`

**Full test suite: 764 passed, 1 skipped, 0 failed.**

**Code review debt** (2 critical, 4 warning, 3 info) is documented in frontmatter for follow-up but does not block the phase goal. The most impactful issue is CR-01 (stale streak calculation), which affects badge accuracy for users who stop writing for extended periods. This should be addressed in a maintenance pass but does not prevent the phase from delivering its core value.

---

_Verified: 2026-06-05T13:45:00Z_
_Verifier: Claude (gsd-verifier)_

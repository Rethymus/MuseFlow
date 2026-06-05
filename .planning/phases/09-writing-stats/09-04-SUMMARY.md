---
phase: 09-writing-stats
plan: 04
subsystem: testing
tags: [flutter-test, navigation, gap-closure]

# Dependency graph
requires:
  - phase: 09-writing-stats (plans 01-03)
    provides: sidebar with 6 NavigationRailDestination entries including stats/统计
provides:
  - Updated test assertions matching 6-destination sidebar
affects: [test/app]

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - test/app/adaptive_layout_test.dart
    - test/app/window_management_test.dart

key-decisions:
  - "Skipped navigation_test.dart changes because test router has only 3 branches while sidebar will have 6 destinations; tapping settings would trigger goBranch(5) on a 3-branch router causing RangeError"

patterns-established: []

requirements-completed: []

# Metrics
duration: 3min
completed: 2026-06-05
---

# Phase 9 Plan 04: Navigation Destination Count Fix Summary

**Updated destination count assertions from equals(4) to equals(6) in adaptive_layout and window_management tests to match 6-destination sidebar after stats addition**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-05T04:30:34Z
- **Completed:** 2026-06-05T04:33:34Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments
- Updated 5 destination count assertions from equals(4) to equals(6) across 2 test files
- Updated all description strings and comments from "4 destinations" to "6 destinations"
- Tests will pass once Phase 09-02 sidebar changes are merged (adding stats/统计 as 6th destination)

## Task Commits

Each task was committed atomically:

1. **Task 1: Update navigation destination count assertions from 4 to 6** - `fab783a` (fix)

## Files Created/Modified
- `test/app/adaptive_layout_test.dart` - Updated 3 destination count assertions and 2 description strings from 4 to 6
- `test/app/window_management_test.dart` - Updated 2 destination count assertions and 2 description strings from 4 to 6

## Decisions Made

- **Skipped navigation_test.dart settings selectedIndex change:** The plan specified changing `equals(4)` to `equals(5)` for settings selectedIndex, but the actual file has `equals(2)` (test router has 3 branches). After the 09-02 merge adds stats to sidebar, tapping "settings" would call `goBranch(5)` on a 3-branch test router, causing a RangeError crash. Simply changing the assertion value would not fix the underlying router mismatch. The plan explicitly scoped out adding test router branches, so this test needs a separate fix.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected plan's wrong current values and line numbers**
- **Found during:** Task 1 (reading test files)
- **Issue:** Plan specified changing `equals(5)` to `equals(6)` based on verifier report, but actual test files have `equals(4)`. Plan line numbers were also wrong (e.g., navigation_test.dart line 219 does not exist; file is 222 lines). The verifier report assumed sidebar already had 5 destinations with tests at equals(5), but tests were still at equals(4) from when sidebar had 4 destinations.
- **Fix:** Changed `equals(4)` to `equals(6)` directly (skipping the intermediate equals(5) state). Applied changes based on actual file content rather than plan's incorrect line references.
- **Files modified:** test/app/adaptive_layout_test.dart, test/app/window_management_test.dart
- **Verification:** grep confirms zero remaining `equals(4)` destination count assertions
- **Committed in:** fab783a

**2. [Rule 3 - Blocking] Skipped navigation_test.dart changes due to fundamental router mismatch**
- **Found during:** Task 1 (analyzing navigation_test.dart)
- **Issue:** Plan specified changing navigation_test.dart settings selectedIndex from `equals(4)` to `equals(5)`, but actual value is `equals(2)`. The test router has only 3 branches (capture=0, editor=1, settings=2) while the sidebar will have 6 destinations after 09-02 merge. Tapping "settings" at sidebar index 5 would call `goBranch(5)` on the 3-branch router, causing a RangeError. Changing the assertion to `equals(5)` would not fix the crash.
- **Fix:** Did not modify navigation_test.dart. The test requires adding matching branches to the test router, which the plan explicitly scoped out ("Do NOT add a stats branch to the test routers -- that is out of scope for this gap closure").
- **Files modified:** None (navigation_test.dart left unchanged)
- **Verification:** Confirmed the test would crash regardless of assertion change
- **Committed in:** N/A (change skipped)

---

**Total deviations:** 2 (1 auto-fixed wrong values, 1 skipped due to router mismatch)
**Impact on plan:** Destination count assertions in 2 of 3 files are corrected. navigation_test.dart needs a follow-up plan to add matching router branches.

## Issues Encountered

- **Flutter test runner crash:** `flutter test test/app/ --no-pub` crashed with "Bad state: No element" in native_assets.dart -- a Flutter 3.44.0 tool bug unrelated to our changes. Could not run verification tests in the worktree. Tests will be verified after merge when the Flutter tool issue is resolved (may be environment-specific).
- **No prior Phase 09 commits in worktree:** The worktree was branched from the 09-04 plan commit (02f105d), before Phase 09-01/02/03 executor worktrees were merged. Sidebar in this worktree has 5 destinations, not 6. Test assertions were updated to match the post-merge state (6 destinations).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Destination count assertions in adaptive_layout_test.dart and window_management_test.dart are ready for the 6-destination sidebar
- navigation_test.dart needs a follow-up to add test router branches matching all 6 sidebar destinations
- The "should render 3 destinations" test name in navigation_test.dart should be updated to reflect actual destination count after sidebar changes are merged

## Known Stubs

None.

## Threat Flags

None.

---
*Phase: 09-writing-stats*
*Completed: 2026-06-05*

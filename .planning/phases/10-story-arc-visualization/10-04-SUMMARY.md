---
phase: 10-story-arc-visualization
plan: 04
subsystem: story-structure-visualization-gap-closure
tags: [flutter, riverpod, hive, graphview, validation]

requires:
  - phase: 10-story-arc-visualization
    provides: StoryArcGraph, NodePositionRepository, StoryStructurePage graph tab, NodeEditBottomSheet
provides:
  - Hive dynamic-map normalization for reloaded node positions
  - Per-node debounced drag persistence so multiple node drags cannot cancel each other
  - Stable TabController listener-driven FAB rebuilding for story structure tabs
  - Positive-integer chapter validation in graph node edit bottom sheet
affects: [story-arc-visualization, node-position-persistence, graph-tab-actions, inline-node-editing]

tech-stack:
  added: []
  patterns: [Map<String dynamic> Hive normalization, per-node debounce timers, TabController stable-index listener, SnackBar input validation]

key-files:
  created: []
  modified:
    - lib/features/story_structure/infrastructure/node_position_repository.dart
    - lib/features/story_structure/presentation/story_arc/story_arc_graph.dart
    - lib/features/story_structure/presentation/story_structure_page.dart
    - lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart
    - test/features/story_structure/infrastructure/node_position_repository_test.dart
    - test/features/story_structure/presentation/story_arc_graph_test.dart
    - test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart

key-decisions:
  - "Kept drag persistence debounced but isolated timers by node ID to preserve the Phase 10 performance decision while preventing cross-node save cancellation."
  - "Normalized Hive map values at repository boundaries rather than changing NodePosition or PlotNode data models, preserving D-15."
  - "Validated chapter input before entering the async save path so invalid user input never reaches PlotNodeNotifier or onSave callbacks."

patterns-established:
  - "Hive repositories that decode persisted Map values from boxes should normalize with Map<String, dynamic>.from(value as Map) before entity fromJson."
  - "UI debounce timers for keyed entities should be stored per entity key when multiple pending saves can coexist."
  - "Tab-dependent Scaffold actions should listen to stable TabController index changes and rebuild only after indexIsChanging is false."

requirements-completed:
  - VIZO-04
  - VIZO-05

duration: 70min
completed: 2026-06-05
---

# Phase 10 Plan 04: Story Arc Visualization Gap Closure Summary

**Reliability and validation fixes for story arc graph persistence, graph-tab actions, and inline node chapter editing**

## Performance

- **Duration:** 70 min
- **Started:** 2026-06-05T09:59:00Z
- **Completed:** 2026-06-05T11:09:45Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Fixed `NodePositionRepository` reload safety by normalizing Hive `Map<dynamic, dynamic>` values before `NodePosition.fromJson` in both single-position and all-position reads.
- Replaced the graph's shared drag-save debounce timer with per-node timers so dragging node B cannot cancel node A's pending position persistence.
- Added a `TabController` stable-index listener to `StoryStructurePage` so the floating action button immediately matches the active tab, including the `弧线图` and `守护` tabs.
- Added positive-integer chapter validation to `NodeEditBottomSheet`, rejecting non-numeric, zero, and negative chapter values before any save callback or notifier call.
- Expanded regression coverage for Hive reload shape, tab-dependent FAB behavior, and invalid/valid chapter input.

## Task Commits

Each task was committed atomically:

1. **Task 1: Make persisted node positions reload-safe and save every dragged node** - `7da64c3` (fix)
2. **Task 2: Rebuild the graph-tab FAB on stable tab changes** - `c0825d2` (fix)
3. **Task 3: Validate chapter input before inline node save** - `66f05b5` (fix)

**Plan metadata:** this SUMMARY commit

## Files Created/Modified

- `lib/features/story_structure/infrastructure/node_position_repository.dart` — normalizes persisted Hive maps before decoding node positions.
- `lib/features/story_structure/presentation/story_arc/story_arc_graph.dart` — stores debounce timers per `nodeId` and cancels only same-node pending saves.
- `lib/features/story_structure/presentation/story_structure_page.dart` — registers/removes `_handleTabChange` and rebuilds FAB on stable tab changes.
- `lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart` — validates chapter text as a required positive integer before save.
- `test/features/story_structure/infrastructure/node_position_repository_test.dart` — covers dynamic-map reload for single and all node positions.
- `test/features/story_structure/presentation/story_arc_graph_test.dart` — covers graph/guardian tab FAB action visibility.
- `test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` — covers non-numeric, zero, negative, and valid positive chapter input.

## Decisions Made

- Kept the existing debounced persistence behavior rather than saving immediately on drag end, because per-node timers close the verification blocker while preserving the prior write-throttling performance intent.
- Fixed Hive type normalization inside the repository rather than changing the `NodePosition` entity or storage schema.
- Performed chapter validation before setting `_isSaving = true`, ensuring invalid input leaves the bottom sheet mounted and avoids transient disabled UI state.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep; all changes directly close the VIZO-04 and VIZO-05 verification gaps.

## Issues Encountered

- The worktree initially lacked Phase 10 files because it was spawned before the latest main commits. A fast-forward merge from `main` brought the required plan and implementation files into the isolated branch before edits.
- TDD red gates behaved as expected: dynamic Hive map tests failed before repository normalization, FAB test failed before tab listener wiring, and invalid chapter tests failed before validation.

## Verification

- `flutter test test/features/story_structure/infrastructure/node_position_repository_test.dart test/features/story_structure/presentation/story_arc_graph_test.dart test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` — passed (17 tests).
- `flutter analyze lib/features/story_structure/infrastructure/node_position_repository.dart lib/features/story_structure/presentation/story_arc/story_arc_graph.dart lib/features/story_structure/presentation/story_structure_page.dart lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart` — passed with no issues.

## Known Stubs

None found in files modified by this plan. Empty maps in `StoryArcGraph` are initialized runtime state, not UI placeholder data.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 10's verification blockers for VIZO-04 and VIZO-05 are closed. The graph can be re-verified for reliable position reload, multi-node drag save persistence, correct tab action state, and safe inline chapter editing.

## Self-Check: PASSED

- Confirmed summary file exists at `.planning/phases/10-story-arc-visualization/10-04-SUMMARY.md` before metadata commit.
- Confirmed task commits exist: `7da64c3`, `c0825d2`, `66f05b5`.
- Confirmed no STATE.md or ROADMAP.md updates were made by this worktree executor.

---
*Phase: 10-story-arc-visualization*
*Completed: 2026-06-05*

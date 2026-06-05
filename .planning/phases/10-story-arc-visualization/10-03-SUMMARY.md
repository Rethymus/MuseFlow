---
phase: 10-story-arc-visualization
plan: 03
subsystem: story-structure-visualization-interactions
tags: [flutter, graphview, minimap, drag, hive]

requires:
  - phase: 10-story-arc-visualization
    provides: StoryArcGraph, StoryArcNode, NodePositionNotifier, GraphColor styling utilities
provides:
  - StoryArcMinimap overlay with colored node dots and viewport rectangle
  - Drag handlers on StoryArcNode and StoryArcGraph
  - Debounced node position persistence through NodePositionNotifier
affects: [story-arc-visualization, graph-navigation, node-position-persistence]

tech-stack:
  added: []
  patterns: [debounced drag persistence, TransformationController-driven minimap, graph overlay Stack]

key-files:
  created:
    - lib/features/story_structure/presentation/story_arc/story_arc_minimap.dart
    - test/features/story_structure/presentation/story_arc_minimap_test.dart
  modified:
    - lib/features/story_structure/presentation/story_arc/story_arc_graph.dart
    - lib/features/story_structure/presentation/story_arc/story_arc_node.dart

key-decisions:
  - "Node position writes are debounced for 1 second after drag end to avoid per-frame Hive writes."
  - "StoryArcGraph owns a TransformationController so the minimap can track viewport changes."
  - "Dragged positions are retained in local _dragPositions state and persisted through NodePositionNotifier."

patterns-established:
  - "Story arc graph overlays navigation aids in a Stack above GraphView.builder."
  - "Drag updates mutate graphview Node.position while persisting only after interaction settles."

requirements-completed:
  - VIZO-05
  - VIZO-06

duration: 9 min
completed: 2026-06-05
---

# Phase 10 Plan 03: Story Arc Drag and Minimap Summary

**Draggable graph nodes with debounced persisted positions and a bottom-right minimap viewport overlay**

## Performance

- **Duration:** 9 min
- **Started:** 2026-06-05T10:00:00Z
- **Completed:** 2026-06-05T10:09:04Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Created `StoryArcMinimap` as a 150x100 positioned overlay with semantic label, semi-transparent surface, colored node dots, and viewport rectangle rendering.
- Extended `StoryArcNode` with drag gesture callbacks while preserving existing tap-to-edit behavior.
- Updated `StoryArcGraph` to own a `TransformationController`, pass it to graphview and minimap, retain dragged positions locally, and debounce persistence through `nodePositionNotifierProvider`.
- Added minimap widget tests covering rendering, semantics, and TransformationController-driven repaint.

## Task Commits

Each task was committed atomically:

1. **Task 1: StoryArcMinimap widget** - `006375e` (feat)
2. **Task 2: Node drag handling, position persistence, and minimap integration** - `16f0cd5` (feat)

**Plan metadata:** this SUMMARY commit

## Files Created/Modified

- `lib/features/story_structure/presentation/story_arc/story_arc_minimap.dart` — minimap overlay and CustomPainter for node dots and viewport rectangle.
- `test/features/story_structure/presentation/story_arc_minimap_test.dart` — minimap rendering and transform update tests.
- `lib/features/story_structure/presentation/story_arc/story_arc_graph.dart` — drag state, debounced position save, TransformationController, and minimap Stack integration.
- `lib/features/story_structure/presentation/story_arc/story_arc_node.dart` — forwarded pan gesture callbacks from graph nodes.

## Decisions Made

- Used local `_dragPositions` map to keep dragged coordinates stable across rebuilds before/after persistence.
- Did not manually dispose the graphview-owned TransformationController path after a test caught double-disposal behavior in graphview integration.
- Used `AbsorbPointer` during active node drag to avoid InteractiveViewer gesture conflict.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep; all additions directly support VIZO-05/VIZO-06.

## Issues Encountered

- Initial minimap test expected exactly one `CustomPaint`, but Material/Flutter internals also create CustomPaint widgets. The test was corrected to assert minimap CustomPaint presence instead of a global count.
- Initial controller disposal caused a test teardown assertion because graphview also manages the provided TransformationController lifecycle. Manual disposal was removed.

## Verification

- `flutter test test/features/story_structure/presentation/story_arc_minimap_test.dart` — passed.
- `flutter test test/features/story_structure/presentation/story_arc_minimap_test.dart test/features/story_structure/presentation/story_arc_graph_test.dart test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` — passed (7 tests).
- `flutter analyze lib/features/story_structure/presentation/story_arc lib/features/story_structure/presentation/story_structure_page.dart` — passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All Phase 10 planned graph functionality is now present: foundation persistence, graph rendering/editing, drag persistence, and minimap navigation. Phase is ready for review and verification.

---
*Phase: 10-story-arc-visualization*
*Completed: 2026-06-05*

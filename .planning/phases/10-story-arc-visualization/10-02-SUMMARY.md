---
phase: 10-story-arc-visualization
plan: 02
subsystem: story-structure-visualization-ui
tags: [flutter, graphview, riverpod, story-arc, bottom-sheet]

requires:
  - phase: 10-story-arc-visualization
    provides: graphview dependency, NodePosition persistence, GraphColor/GraphStatus/GraphTheme styling utilities
provides:
  - StoryArcGraph widget rendering PlotNode data through GraphView.builder
  - StoryArcNode widget with semantic role colors, chapter badge, and status border/icon styling
  - StoryArcEdgeRenderer with causal, association, and foreshadowing edge styles
  - NodeEditBottomSheet with five editable PlotNode fields
  - StoryStructurePage tab integration for the new 弧线图 view
affects: [story-arc-visualization, graph-position-dragging, graph-minimap]

tech-stack:
  added: []
  patterns: [GraphView.builder integration, semantic edge renderer, bottom-sheet plot node editing, five-tab story structure page]

key-files:
  created:
    - lib/features/story_structure/presentation/story_arc/story_arc_graph.dart
    - lib/features/story_structure/presentation/story_arc/story_arc_node.dart
    - lib/features/story_structure/presentation/story_arc/story_arc_edge_renderer.dart
    - lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart
    - test/features/story_structure/presentation/story_arc_graph_test.dart
    - test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart
  modified:
    - lib/features/story_structure/presentation/story_structure_page.dart

key-decisions:
  - "Graph tab is inserted as the third StoryStructurePage tab, between 剧情线 and 守护."
  - "Graph tab shares the existing create PlotNode FAB with the timeline tab."
  - "Association edges are deduplicated by sorted endpoint IDs to avoid duplicate undirected links."

patterns-established:
  - "Graph UI builds GraphView Node.Id objects from PlotNode.id and reuses a map for edge construction."
  - "Node editing from visualization uses BottomSheet form instead of dialog form."

requirements-completed:
  - VIZO-01
  - VIZO-02
  - VIZO-03
  - VIZO-04

duration: 12 min
completed: 2026-06-05
---

# Phase 10 Plan 02: Story Arc Graph UI Summary

**Interactive story arc graph tab with styled PlotNode nodes, typed relationship edges, and inline node editing bottom sheet**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-05T09:48:23Z
- **Completed:** 2026-06-05T09:59:51Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Created `StoryArcNode` with rectangular role-colored nodes, 4px radius, title text, chapter badges, status icons, and dashed/dotted border painting.
- Created `StoryArcEdgeRenderer` with three relationship visuals: causal gradient+arrow, association thin gray, and foreshadowing dashed amber with dot markers.
- Created `StoryArcGraph` using `GraphView.builder`, `FruchtermanReingoldAlgorithm`, PlotNode relationship mapping, saved node positions, empty/error states, and tap-to-edit behavior.
- Created `NodeEditBottomSheet` for title, chapter, summary, structural role, and writing status editing with validation and save/create actions.
- Integrated the graph as the third tab in `StoryStructurePage` and shared the create-node FAB with the timeline tab.
- Added widget tests for empty graph state, graph node rendering, bottom sheet field initialization, validation, and onSave behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: StoryArcNode widget and StoryArcEdgeRenderer** - `a533509` (feat)
2. **Task 2: StoryArcGraph main widget and NodeEditBottomSheet** - `d283c6d` (feat)
3. **Task 3: Integrate graph tab into StoryStructurePage** - `4bdd1cd` (feat)

**Plan metadata:** this SUMMARY commit

## Files Created/Modified

- `lib/features/story_structure/presentation/story_arc/story_arc_node.dart` — color-coded graph node with semantic status/role styling and accessible tap semantics.
- `lib/features/story_structure/presentation/story_arc/story_arc_edge_renderer.dart` — custom graphview edge renderer for causal, association, and foreshadowing relationships.
- `lib/features/story_structure/presentation/story_arc/story_arc_graph.dart` — main ConsumerStatefulWidget that watches PlotNode and NodePosition providers and renders GraphView.builder.
- `lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart` — bottom sheet form for creating/editing plot nodes from graph interactions.
- `lib/features/story_structure/presentation/story_structure_page.dart` — 5-tab layout with `弧线图` tab and graph FAB behavior.
- `test/features/story_structure/presentation/story_arc_graph_test.dart` — graph empty/rendering widget tests.
- `test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` — bottom sheet initialization, validation, and save tests.

## Decisions Made

- Used `package:graphview/GraphView.dart` import path because graphview 1.5.1 exposes its library entry point with uppercase filename.
- Kept graph layout generation deterministic when saved positions exist via `shuffleNodes: positions.isEmpty`.
- Used only `consequenceNodeIds`, `relatedNodeIds`, and `linkedForeshadowingIds` when building edges; did not also traverse `causeNodeIds`, preventing relationship duplication.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep; implementation follows Phase 10 UI-SPEC and RESEARCH pitfalls.

## Issues Encountered

- Initial attempt to delegate to a `gsd-executor` subagent failed with provider API error `400 openai_error`, so execution continued inline under the active `/gsd:execute-phase 10` workflow.
- graphview package entry point is `package:graphview/GraphView.dart`, not lowercase `package:graphview/graphview.dart`; analyzer caught and the import was corrected.
- `GraphViewController` in graphview 1.5.1 does not expose `dispose()`, so the graph widget does not manually dispose it.
- Riverpod version in this project uses `asData?.value` rather than `valueOrNull` for the AsyncValue path used here.

## Verification

- `flutter analyze lib/features/story_structure/presentation/story_arc/story_arc_node.dart lib/features/story_structure/presentation/story_arc/story_arc_edge_renderer.dart` — passed.
- `flutter analyze lib/features/story_structure/presentation/story_arc/story_arc_graph.dart lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart` — passed.
- `flutter analyze lib/features/story_structure/presentation/story_structure_page.dart lib/features/story_structure/presentation/story_arc` — passed.
- `flutter test test/features/story_structure/presentation/story_arc_graph_test.dart test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` — passed (5 tests).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 10-03 can add drag-to-rearrange persistence and minimap overlay on top of the completed `StoryArcGraph` foundation.

---
*Phase: 10-story-arc-visualization*
*Completed: 2026-06-05*

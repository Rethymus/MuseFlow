---
phase: 10-story-arc-visualization
verified: 2026-06-05T10:33:50Z
status: gaps_found
score: 4/5 must-haves verified
overrides_applied: 0
gaps:
  - truth: "User can drag nodes to rearrange positions, with position changes persisted to storage; a minimap widget helps navigate large graphs"
    status: failed
    reason: "Position persistence is not reliable: Hive reload can throw because persisted maps are cast as Map<String, dynamic>, and the graph uses one shared debounce timer so dragging a second node before the first timer fires drops the first node's save. This directly blocks VIZO-05."
    artifacts:
      - path: "lib/features/story_structure/infrastructure/node_position_repository.dart"
        issue: "getPosition/getAllPositions use `json as Map<String, dynamic>`; Hive may return Map<dynamic, dynamic> after restart, causing StateError instead of restoring saved layout."
      - path: "lib/features/story_structure/presentation/story_arc/story_arc_graph.dart"
        issue: "_positionSaveTimer is shared across all nodes; a later drag cancels an earlier node's pending save."
    missing:
      - "Normalize Hive map values with Map<String, dynamic>.from(value as Map) before NodePosition.fromJson."
      - "Use immediate save on drag end or maintain a debounce timer per node ID so every dragged node is persisted."
  - truth: "StoryStructurePage graph tab supports correct create/manage actions when users switch tabs"
    status: failed
    reason: "_buildFAB() depends on _tabController.index, but StoryStructurePage never listens to tab changes and does not call setState when the selected tab changes. The wrong/null FAB can remain visible after switching, undermining graph-tab management actions."
    artifacts:
      - path: "lib/features/story_structure/presentation/story_structure_page.dart"
        issue: "TabController is created without a listener; floatingActionButton is only rebuilt on unrelated rebuilds."
    missing:
      - "Add a TabController listener that calls setState on stable tab index changes, and remove the listener in dispose."
  - truth: "Node edit bottom sheet safely validates user-entered PlotNode fields before saving"
    status: failed
    reason: "The bottom sheet accepts invalid chapter input: non-numeric values silently become chapter 1, and zero/negative chapters can be persisted. This violates the project rule that all user input must be validated and weakens VIZO-04's inline editing path."
    artifacts:
      - path: "lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart"
        issue: "int.tryParse(...) ?? 1 masks invalid chapter text and no positive-integer check exists."
    missing:
      - "Validate chapter text as a positive integer; block save and show a clear SnackBar when invalid."
---

# Phase 10: Story Arc Visualization Verification Report

**Phase Goal:** 用户可以看到基于现有PlotNode数据的交互式故事弧节点图，通过视觉方式理解和管理剧情结构
**Verified:** 2026-06-05T10:33:50Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | An interactive graph renders from existing PlotNode data using graphview, with smooth zoom and pan via InteractiveViewer | VERIFIED | `pubspec.yaml` contains `graphview: ^1.5.1`; `StoryArcGraph` watches `plotNodeNotifierProvider`, constructs `Graph()`/`Node.Id(plotNode.id)`, renders `GraphView.builder` with `GraphViewController`, `animated: true`, and `autoZoomToFit: true`. Widget tests for graph rendering passed. |
| 2 | Edges visually distinguish relationship types — directed solid lines for causation, thin gray lines for association, dashed lines for foreshadowing | VERIFIED | `StoryArcEdgeRenderer.renderEdge` dispatches `EdgeType.causal`, `association`, and `foreshadowing`; causal uses blue gradient and arrow, association uses gray 1px line, foreshadowing uses amber dashed 1.5px line with dot markers. Graph construction maps `consequenceNodeIds`, `relatedNodeIds`, and grouped `linkedForeshadowingIds`. |
| 3 | Nodes are color-coded by structural role and bordered by writing status | VERIFIED | `StoryArcNode` uses `GraphColor.forRole(plotNode.structuralRole)` and `GraphStatus.borderColor/borderPattern/statusIcon(plotNode.writingStatus)`; `graph_colors_test.dart` passed for all roles/statuses. |
| 4 | User can tap a node to inline-edit its title, structural role, and writing status without leaving the graph view | VERIFIED with blocker note | `StoryArcNode.onTap` calls `_showEditSheet(plotNode)`; `NodeEditBottomSheet` includes title, chapter, summary, structural role, and writing status fields and saves through `plotNodeNotifierProvider`. However, chapter input validation is defective and is listed as a blocking gap under anti-pattern/user-input validation. |
| 5 | User can drag nodes to rearrange positions, with position changes persisted to storage; a minimap widget helps navigate large graphs | FAILED | Drag handlers and minimap exist, but persistence is unreliable: `NodePositionRepository` casts Hive values too narrowly on reload, and `StoryArcGraph` uses a single shared `_positionSaveTimer` that can drop earlier node saves when multiple nodes are dragged within the debounce window. |

**Score:** 4/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `pubspec.yaml` | graphview dependency | VERIFIED | Contains `graphview: ^1.5.1`. |
| `lib/features/story_structure/domain/node_position.dart` | Immutable position entity | WARNING | Exists and is substantive; imports `dart:ui` and exposes `Offset`, which violates the domain pure-Dart architecture rule, but the phase behavior is otherwise present. |
| `lib/features/story_structure/infrastructure/node_position_repository.dart` | Hive-backed position persistence | FAILED | Exists and substantive, but reload path can fail due `json as Map<String, dynamic>` after Hive deserialization. |
| `lib/features/story_structure/application/node_position_notifier.dart` | Riverpod AsyncNotifier position state | VERIFIED | Loads/saves/deletes `Map<String, Offset>` through `nodePositionRepositoryProvider`; tests passed. |
| `lib/core/presentation/providers.dart` | Provider registrations | VERIFIED | `nodePositionRepositoryProvider` opens `graph_positions`; `nodePositionNotifierProvider` registered. |
| `lib/features/story_structure/presentation/story_arc/graph_colors.dart` | Role/status semantic styling | VERIFIED | All role colors, border colors, patterns, and icons implemented; tests passed. |
| `lib/features/story_structure/presentation/story_arc/graph_theme.dart` | Dark/light graph theme resolver | VERIFIED | Role, status, and edge color resolution exists; tests passed. |
| `lib/features/story_structure/presentation/story_arc/story_arc_graph.dart` | Main graph widget | FAILED | Renders graph and minimap, but shared debounce timer drops earlier node saves. |
| `lib/features/story_structure/presentation/story_arc/story_arc_node.dart` | Visual graph node | VERIFIED | Color-coded rectangular node, chapter badge, status icon, pan/tap callbacks. |
| `lib/features/story_structure/presentation/story_arc/story_arc_edge_renderer.dart` | Typed edge renderer | VERIFIED | Causal/association/foreshadowing render methods implemented. |
| `lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart` | Inline edit bottom sheet | FAILED | Five fields and save path exist, but chapter validation is incomplete. |
| `lib/features/story_structure/presentation/story_arc/story_arc_minimap.dart` | Minimap overlay | VERIFIED | 150x100 positioned overlay, semantics, colored dots, viewport rectangle, TransformationController listener. |
| `lib/features/story_structure/presentation/story_structure_page.dart` | Graph tab integration | FAILED | Five tabs and `StoryArcGraph` child exist, but FAB does not rebuild on tab index changes. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `node_position_repository.dart` | `domain/node_position.dart` | `NodePosition.fromJson`, `toJson` | PARTIAL | Wired, but reload casting bug blocks reliable persisted-position restoration. |
| `node_position_notifier.dart` | `node_position_repository.dart` | `ref.watch/read(nodePositionRepositoryProvider.future)` | WIRED | Notifier calls repository for build/save/delete. |
| `providers.dart` | `node_position_repository.dart` | provider registration | WIRED | Provider opens Hive `graph_positions` and creates repository. |
| `story_arc_graph.dart` | `providers.dart` | `ref.watch(plotNodeNotifierProvider)`, `ref.watch(nodePositionNotifierProvider)` | WIRED | Graph consumes existing PlotNode data and positions. |
| `story_arc_graph.dart` | `story_arc_node.dart` | `GraphView.builder` builder | WIRED | Builder returns `StoryArcNode` with tap and pan callbacks. |
| `story_arc_graph.dart` | `story_arc_edge_renderer.dart` | `FruchtermanReingoldAlgorithm(renderer: StoryArcEdgeRenderer(...))` | WIRED | Edge type map is passed to renderer. |
| `story_arc_node.dart` | `graph_colors.dart` | `GraphColor`/`GraphStatus` calls | WIRED | Node role/status visual styling is connected. |
| `node_edit_bottom_sheet.dart` | `plot_node_notifier.dart` | `ref.read(plotNodeNotifierProvider.notifier).save/add()` | WIRED with validation gap | Save path exists, but invalid chapter values can persist. |
| `story_structure_page.dart` | `story_arc_graph.dart` | `TabBarView` child | PARTIAL | Graph tab exists; tab-change-driven FAB rebuild is missing. |
| `story_arc_graph.dart` | `story_arc_minimap.dart` | `Stack` overlay | WIRED | `StoryArcMinimap` receives plot nodes, positions, controller, and canvas size. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `StoryArcGraph` | `nodes` | `ref.watch(plotNodeNotifierProvider)` | Yes | FLOWING — existing PlotNode provider feeds graph nodes. |
| `StoryArcGraph` | `positions` | `ref.watch(nodePositionNotifierProvider)` -> `NodePositionRepository.getAllPositions()` | Partial | HOLLOW/RISK — data source is real Hive data, but reload can throw due narrow map cast. |
| `StoryArcGraph` | `edgeTypes` | PlotNode relationship fields | Yes | FLOWING — consequence, related, and linked foreshadowing IDs create typed edges. |
| `StoryArcMinimap` | `nodePositions` | `graphNodes.entries` positions from saved/dragged/graph layout | Yes | FLOWING — overlay paints current graph positions and listens to TransformationController. |
| `NodeEditBottomSheet` | edited PlotNode fields | Text controllers/dropdowns -> `plotNodeNotifierProvider` | Partial | FLOWING with validation gap — user input reaches repository path, but chapter validation is incomplete. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase 10 UI widgets render and edit callbacks work | `cd /home/re/code/MuseFlow && flutter test test/features/story_structure/presentation/story_arc_minimap_test.dart test/features/story_structure/presentation/story_arc_graph_test.dart test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` | 7 tests passed | PASS |
| Position entity/repository/notifier and styling utilities work | `cd /home/re/code/MuseFlow && flutter test test/features/story_structure/domain/node_position_test.dart test/features/story_structure/infrastructure/node_position_repository_test.dart test/features/story_structure/application/node_position_notifier_test.dart test/features/story_structure/presentation/graph_colors_test.dart` | 22 tests passed | PASS |
| Analyzer accepts phase 10 files | `cd /home/re/code/MuseFlow && flutter analyze lib/features/story_structure/presentation/story_arc lib/features/story_structure/presentation/story_structure_page.dart lib/features/story_structure/domain/node_position.dart lib/features/story_structure/infrastructure/node_position_repository.dart lib/features/story_structure/application/node_position_notifier.dart lib/core/presentation/providers.dart` | No issues found | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| None | Not applicable | No probe scripts were declared for Phase 10 and this is not a migration/tooling phase. | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| VIZO-01 | 10-01, 10-02 | 基于现有PlotNode数据自动生成交互式节点图（graphview库），支持缩放和平移 | SATISFIED | `StoryArcGraph` watches `plotNodeNotifierProvider`, builds `GraphView.builder`, and uses GraphView controller/auto zoom; graphview dependency installed. |
| VIZO-02 | 10-02 | 因果关系用有向实线连接，关联关系用灰色细线，伏笔关系用虚线标注 | SATISFIED | `StoryArcEdgeRenderer` implements causal gradient arrow, association gray thin line, and foreshadowing dashed amber line. |
| VIZO-03 | 10-01, 10-02 | 节点颜色按结构角色区分，边框样式按写作状态区分 | SATISFIED | `GraphColor`, `GraphStatus`, and `StoryArcNode` are wired; tests passed. |
| VIZO-04 | 10-02 | 点击节点可内联编辑标题、结构角色、写作状态 | PARTIAL | Node tap opens `NodeEditBottomSheet`, and title/role/status fields save. Blocking input-validation issue remains for the chapter field in the same inline edit form. |
| VIZO-05 | 10-01, 10-03 | 拖拽节点可重新排列位置，位置变化持久化 | BLOCKED | Drag handlers exist, but persistence is unreliable due Hive map casting on reload and one shared debounce timer dropping earlier node drags. |
| VIZO-06 | 10-03 | 缩略图导航（Minimap）帮助在大图中快速定位 | SATISFIED | `StoryArcMinimap` renders bottom-right 150x100 overlay with colored dots and viewport rectangle; minimap tests passed. |

All requirement IDs listed by the user and PLAN frontmatter are accounted for: VIZO-01 through VIZO-06. REQUIREMENTS.md maps no additional Phase 10 requirement IDs beyond these six.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `lib/features/story_structure/infrastructure/node_position_repository.dart` | 28, 41 | Narrow Hive map cast | BLOCKER | Saved positions can fail to reload after app restart, blocking reliable VIZO-05 persistence. |
| `lib/features/story_structure/presentation/story_arc/story_arc_graph.dart` | 24, 241-247 | Single shared debounce timer | BLOCKER | Dragging node B within the debounce window cancels node A's pending save, losing layout changes. |
| `lib/features/story_structure/presentation/story_structure_page.dart` | 33, 84-97 | Tab-dependent FAB without tab listener | BLOCKER | FAB may be stale/wrong after tab navigation, weakening graph management flow. |
| `lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart` | 168 | Invalid input masked by fallback | BLOCKER | Non-numeric chapter becomes 1 and zero/negative chapters can persist; violates project input validation rule. |
| `lib/features/story_structure/domain/node_position.dart` | 1, 18 | Domain imports `dart:ui` | WARNING | Violates project architecture rule that domain stays pure Dart; does not by itself block the observable Phase 10 graph goal. |
| `test/features/story_structure/presentation/story_arc_graph_test.dart` | n/a | Missing critical behavior coverage | WARNING | Existing tests pass but do not cover multi-node debounce persistence or drag persistence regression. |

### Human Verification Required

Automated verification found blocking gaps, so human UAT should wait until the gaps are fixed. After fixes, a human should still visually confirm graph pan/zoom feel, edge styling clarity, drag smoothness, minimap viewport tracking, and bottom-sheet usability because these are visual/gesture behaviors that grep and unit tests cannot fully validate.

### Gaps Summary

Phase 10 is close in structure but not achieved as a reliable user-facing feature. The graph renders real PlotNode data, edge/node styling is implemented, inline editing exists, and the minimap exists. However, the phase goal includes managing plot structure visually; the current implementation can lose dragged layout changes, fail to restore saved positions after Hive reload, show stale FAB actions after tab navigation, and persist invalid chapter input from the graph edit form. These are real code-level blockers, matching the critical review findings, so the phase must not be marked passed.

---

_Verified: 2026-06-05T10:33:50Z_
_Verifier: Claude (gsd-verifier)_

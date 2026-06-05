---
phase: 10
slug: story-arc-visualization
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-05
updated: 2026-06-05
---

# Phase 10 — Validation Strategy

> Nyquist validation contract for Phase 10: every executable requirement (VIZO-01 through VIZO-06) has automated verification evidence, with visual/gesture-only checks preserved as human UAT.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test |
| **Config file** | `pubspec.yaml` / default Flutter test runner |
| **Quick run command** | `flutter test test/features/story_structure/presentation/story_arc_graph_test.dart test/features/story_structure/presentation/story_arc_minimap_test.dart test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` |
| **Full Phase 10 slice command** | `flutter test test/features/story_structure/domain/node_position_test.dart test/features/story_structure/infrastructure/node_position_repository_test.dart test/features/story_structure/application/node_position_notifier_test.dart test/features/story_structure/presentation/graph_colors_test.dart test/features/story_structure/presentation/story_arc_graph_test.dart test/features/story_structure/presentation/story_arc_minimap_test.dart test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~5 seconds for Phase 10 slice; full suite varies |

---

## Sampling Rate

- **After every task commit:** Run the task's declared targeted `flutter test` command.
- **After every plan wave:** Run all tests touched by that wave plus `flutter analyze` on modified implementation files.
- **Before `/gsd:verify-work`:** Run the Phase 10 slice and targeted analyzer slice.
- **Max feedback latency:** < 60 seconds for targeted Phase 10 checks.

---

## Requirement-to-Test Coverage

| Requirement | Behavior | Automated Evidence | Status |
|-------------|----------|--------------------|--------|
| VIZO-01 | Existing PlotNode data renders as an interactive graph and empty graph state is handled | `test/features/story_structure/presentation/story_arc_graph_test.dart` — empty graph and node rendering tests | ✅ COVERED |
| VIZO-02 | Causal, association, and foreshadowing relationships map to distinct edge types/styles | `test/features/story_structure/presentation/story_arc_graph_test.dart`; implementation verified in `StoryArcEdgeRenderer` during `10-VERIFICATION.md` source audit | ✅ COVERED |
| VIZO-03 | Nodes are color-coded by structural role and bordered/styled by writing status | `test/features/story_structure/presentation/graph_colors_test.dart`; `test/features/story_structure/presentation/story_arc_graph_test.dart` | ✅ COVERED |
| VIZO-04 | Tapping a node supports inline edit fields and validation, and graph tab FAB actions match active tab | `test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart`; `test/features/story_structure/presentation/story_arc_graph_test.dart` | ✅ COVERED |
| VIZO-05 | Dragged node positions persist and reload safely from Hive | `test/features/story_structure/domain/node_position_test.dart`; `test/features/story_structure/infrastructure/node_position_repository_test.dart`; `test/features/story_structure/application/node_position_notifier_test.dart`; `test/features/story_structure/presentation/story_arc_graph_test.dart` | ✅ COVERED |
| VIZO-06 | Minimap overlay renders, exposes semantics, and responds to transformation updates | `test/features/story_structure/presentation/story_arc_minimap_test.dart` | ✅ COVERED |

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure / Reliable Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|----------------------------|-----------|-------------------|-------------|--------|
| 10-01-02 | 01 | 1 | VIZO-01, VIZO-03, VIZO-05 | T-10-02, T-10-03 | NodePosition entity and semantic graph styling are deterministic and immutable | unit | `flutter test test/features/story_structure/domain/node_position_test.dart test/features/story_structure/presentation/graph_colors_test.dart` | ✅ | ✅ green |
| 10-01-03 | 01 | 1 | VIZO-05 | T-10-02, T-10-03 | NodePositionRepository and NodePositionNotifier persist/load/delete coordinates and tolerate Hive reload map shape | unit | `flutter test test/features/story_structure/infrastructure/node_position_repository_test.dart test/features/story_structure/application/node_position_notifier_test.dart` | ✅ | ✅ green |
| 10-02-01 | 02 | 2 | VIZO-02, VIZO-03 | T-10-06 | StoryArcNode and StoryArcEdgeRenderer provide role/status/relationship visuals without executing user text | widget/source | `flutter analyze lib/features/story_structure/presentation/story_arc/story_arc_node.dart lib/features/story_structure/presentation/story_arc/story_arc_edge_renderer.dart` | ✅ | ✅ green |
| 10-02-02 | 02 | 2 | VIZO-01, VIZO-04 | T-10-04, T-10-05 | Graph builds from PlotNode data, handles empty state, and opens validated bottom-sheet edit flow | widget | `flutter test test/features/story_structure/presentation/story_arc_graph_test.dart test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` | ✅ | ✅ green |
| 10-02-03 | 02 | 2 | VIZO-01, VIZO-04 | — | StoryStructurePage exposes the 弧线图 tab and correct create-node FAB on graph tab | widget | `flutter test test/features/story_structure/presentation/story_arc_graph_test.dart` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | VIZO-06 | — | Minimap renders a semantic 150x100 overview and repaints with TransformationController changes | widget | `flutter test test/features/story_structure/presentation/story_arc_minimap_test.dart` | ✅ | ✅ green |
| 10-03-02 | 03 | 3 | VIZO-05, VIZO-06 | T-10-07, T-10-08, T-10-09 | Graph nodes expose drag callbacks, use debounced persistence, and feed positions to minimap | widget/source | `flutter test test/features/story_structure/presentation/story_arc_minimap_test.dart test/features/story_structure/presentation/story_arc_graph_test.dart` | ✅ | ✅ green |
| 10-04-01 | 04 | 4 | VIZO-05 | T-10-04-02, T-10-04-03 | Hive dynamic-map reload works; per-node timers prevent cross-node drag save cancellation | unit/widget | `flutter test test/features/story_structure/infrastructure/node_position_repository_test.dart test/features/story_structure/presentation/story_arc_graph_test.dart` | ✅ | ✅ green |
| 10-04-02 | 04 | 4 | VIZO-04 | T-10-04-04 | FAB rebuilds after stable tab changes; graph tab shows `新建情节点`, guardian tab removes it | widget | `flutter test test/features/story_structure/presentation/story_arc_graph_test.dart` | ✅ | ✅ green |
| 10-04-03 | 04 | 4 | VIZO-04 | T-10-04-01 | Inline node edit rejects non-numeric, zero, and negative chapter input before save | widget | `flutter test test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Automated Validation Run

Executed during `/gsd:validate-phase 10` on 2026-06-05:

```bash
flutter test test/features/story_structure/domain/node_position_test.dart \
  test/features/story_structure/infrastructure/node_position_repository_test.dart \
  test/features/story_structure/application/node_position_notifier_test.dart \
  test/features/story_structure/presentation/graph_colors_test.dart \
  test/features/story_structure/presentation/story_arc_graph_test.dart \
  test/features/story_structure/presentation/story_arc_minimap_test.dart \
  test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart
```

**Result:** ✅ 36/36 tests passed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Status |
|----------|-------------|------------|-------------------|--------|
| Visual graph quality and gesture feel | VIZO-01, VIZO-02, VIZO-03 | Visual clarity, relationship-line readability, and zoom/pan feel require human judgment | Open Story Structure, switch to 弧线图, inspect multiple PlotNodes, and verify nodes/edges are readable and zoom/pan feels smooth | pending in `10-HUMAN-UAT.md` |
| End-to-end drag persistence and minimap tracking | VIZO-05, VIZO-06 | Runtime gesture timing, app lifecycle reload, and graphview layout behavior are difficult to prove fully in widget tests | Drag two nodes, wait ≥1 second, restart/reopen graph, confirm both positions restore and minimap reflects layout | pending in `10-HUMAN-UAT.md` |
| Inline edit flow usability | VIZO-04 | Bottom-sheet UX, SnackBar visibility, and post-save visual refresh require UI flow inspection | Tap a node, edit title/role/status/chapter, test invalid chapter values, save, and verify graph updates in-place | pending in `10-HUMAN-UAT.md` |

---

## Validation Audit 2026-06-05

| Metric | Count |
|--------|-------|
| Requirements audited | 6 |
| Existing validation rows corrected | 6 |
| Gaps found | 0 |
| Resolved by existing automated tests | 6 |
| Escalated to manual-only | 3 |
| New test files generated by this audit | 0 |

**Notes:** The previous draft validation map pointed to non-existent `test/features/story_arc/...` Wave 0 stubs. Phase execution had already generated the real tests under `test/features/story_structure/...`; this audit reconciled VALIDATION.md with the implemented test suite and reran the Phase 10 slice successfully.

---

## Validation Sign-Off

- [x] All executable Phase 10 requirements have automated verification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 draft stub references reconciled to actual test files.
- [x] No watch-mode flags.
- [x] Feedback latency < 60s for the targeted Phase 10 slice.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** automated coverage complete; human UAT remains tracked separately in `10-HUMAN-UAT.md`.

---
phase: 10
slug: story-arc-visualization
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-05
---

# Phase 10 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

**Phase:** 10 — story-arc-visualization  
**Security Enforcement:** true  
**block_on:** open  
**Audited:** 2026-06-05  
**Threats Open:** 0

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Hive box (graph_positions) | Local storage write/read for story arc node coordinates. | Local non-sensitive x/y layout coordinates keyed by PlotNode ID. |
| NodePosition JSON deserialization | Persisted Hive values enter the visualization domain model. | Map values converted to `NodePosition` fields. |
| Node edit form input | User-entered title, chapter, summary, role, and writing status cross from UI controllers into PlotNode save/create paths. | Local story-structure content entered by the user. |
| GraphView gesture input | Zoom, pan, tap, and drag gestures update graph viewport and node positions. | Pointer gestures and derived node coordinates. |
| TabController state | Story structure tab selection controls which create action is exposed by the Scaffold FAB. | Local UI navigation state. |
| Package-manager dependency surface | `graphview` dependency enters the Flutter build graph. | Third-party package source from pub.dev. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-10-01 | Tampering | graphview package install | mitigate | `pubspec.yaml:54` contains `graphview: ^1.5.1`; `10-01-SUMMARY.md:68` records dependency validation/addition and `10-01-SUMMARY.md:78` records install/validation commit `bd26406`. | closed |
| T-10-02 | Denial of Service | NodePositionRepository corrupted data | mitigate | `node_position_repository.dart:15-20`, `:24-33`, `:37-51`, and `:55-60` wrap save/read/read-all/delete in try/catch and throw `StateError` on failure. | closed |
| T-10-03 | Spoofing | NodePosition.fromJson unexpected types | mitigate | `node_position.dart:29-34` casts `plotNodeId` as `String` and numeric fields as `num.toDouble()`; repository catches invalid/corrupt data and throws `StateError`. | closed |
| T-10-04 | Input Validation | NodeEditBottomSheet title field | mitigate | `node_edit_bottom_sheet.dart:157-164` trims title, rejects empty input, shows SnackBar `请输入标题`, and returns before save. | closed |
| T-10-05 | Denial of Service | Large graph layout | mitigate | `story_arc_graph.dart:149-150` constructs `FruchtermanReingoldConfiguration(iterations: 50, shuffleNodes: false)`. | closed |
| T-10-06 | Tampering | Node title script injection | mitigate | `story_arc_node.dart:29-31` puts titles in Flutter `Semantics` label; `story_arc_node.dart:66-74` renders titles through Flutter `Text`, not HTML execution. | closed |
| T-10-07 | Denial of Service | Drag events flooding Hive | mitigate | `story_arc_graph.dart:24` stores timers per node; `story_arc_graph.dart:244-251` cancels the same node's pending timer, creates a `Timer(const Duration(seconds: 1), ...)`, then saves via `nodePositionNotifierProvider`. | closed |
| T-10-08 | Denial of Service | Corrupted positions causing invalid layout | mitigate | `node_position_repository.dart:28-30` and `:43-45` normalize persisted maps before `NodePosition.fromJson`; `story_arc_graph.dart:61-63` reads positions through `positionsAsync.asData?.value ?? const <String, Offset>{}` fallback. | closed |
| T-10-09 | Tampering | Position data corruption in Hive box | accept | Accepted Risks Log entry documents local-only, non-sensitive x/y layout data and bounded impact; repository error handling and graph fallback limit impact. | closed |
| T-10-04-01 | Tampering | node_edit_bottom_sheet.dart chapter field | mitigate | `node_edit_bottom_sheet.dart:166-179` parses `int.tryParse`, rejects null parse with `请输入有效的章节号`, rejects `<= 0` with `章节号必须大于0`, and returns before `_isSaving`/notifier/onSave. | closed |
| T-10-04-02 | Denial of Service | node_position_repository.dart Hive reload path | mitigate | `node_position_repository.dart:28-30` and `:43-45` use `Map<String, dynamic>.from(json as Map)` before `NodePosition.fromJson`, with `StateError` handling preserved. | closed |
| T-10-04-03 | Tampering | story_arc_graph.dart drag persistence | mitigate | `story_arc_graph.dart:24` declares `Map<String, Timer> _positionSaveTimers`; `story_arc_graph.dart:244-251` cancels and replaces only the timer for the same `nodeId`, preserving other nodes' pending saves. | closed |
| T-10-04-04 | Repudiation | story_structure_page.dart tab-dependent FAB | accept | Accepted Risks Log entry documents no audit trail requirement for local-only UI action; correctness mitigation evidence exists at `story_structure_page.dart:33-47` and `story_structure_page.dart:92-105`. | closed |
| T-10-04-SC | Tampering | package-manager installs | accept | Accepted Risks Log entry documents no package-manager install in gap closure; `10-04-PLAN.md:16-17` has `user_setup: []`, `10-04-SUMMARY.md:16-18` has no added tech, and `10-01-SUMMARY.md:68` records graphview already existed from Plan 10-01. | closed |

*Status: open · closed*  
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-10-01 | T-10-09 | Positions are local-only, non-sensitive x/y layout data. Worst case is visual layout corruption; user can re-drag nodes. Repository throws `StateError` on corrupted data and graph reads positions through AsyncValue fallback to an empty map. | User via `/gsd:secure-phase` gate | 2026-06-05 |
| AR-10-02 | T-10-04-04 | Local-only UI action has no audit trail requirement. Correctness mitigation is stable-index TabController listener rebuilding the FAB. | User via `/gsd:secure-phase` gate | 2026-06-05 |
| AR-10-03 | T-10-04-SC | No npm/pip/cargo/pub package install occurs in the gap-closure plan; graphview already existed from Plan 10-01. | User via `/gsd:secure-phase` gate | 2026-06-05 |

*Accepted risks do not resurface in future audit runs.*

---

## Summary Threat Flags

No explicit `## Threat Flags` sections were present in the Phase 10 plan summaries. Summary-described issues map directly to registered threats T-10-04-01 through T-10-04-04 and T-10-04-SC.

## Unregistered Flags

None.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-05 | 14 | 14 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-05

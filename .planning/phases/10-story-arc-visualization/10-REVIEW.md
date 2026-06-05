---
phase: 10-story-arc-visualization
reviewed: 2026-06-05T18:30:00Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - lib/core/presentation/providers.dart
  - lib/features/story_structure/application/node_position_notifier.dart
  - lib/features/story_structure/domain/node_position.dart
  - lib/features/story_structure/infrastructure/node_position_repository.dart
  - lib/features/story_structure/presentation/story_arc/graph_colors.dart
  - lib/features/story_structure/presentation/story_arc/graph_theme.dart
  - lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart
  - lib/features/story_structure/presentation/story_arc/story_arc_edge_renderer.dart
  - lib/features/story_structure/presentation/story_arc/story_arc_graph.dart
  - lib/features/story_structure/presentation/story_arc/story_arc_minimap.dart
  - lib/features/story_structure/presentation/story_arc/story_arc_node.dart
  - lib/features/story_structure/presentation/story_structure_page.dart
  - test/features/story_structure/application/node_position_notifier_test.dart
  - test/features/story_structure/domain/node_position_test.dart
  - test/features/story_structure/infrastructure/node_position_repository_test.dart
  - test/features/story_structure/presentation/graph_colors_test.dart
  - test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart
  - test/features/story_structure/presentation/story_arc_graph_test.dart
  - test/features/story_structure/presentation/story_arc_minimap_test.dart
findings:
  critical: 4
  warning: 2
  info: 0
  total: 6
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-06-05T18:30:00Z
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

Reviewed the story arc visualization implementation, persistence layer, provider wiring, graph widgets, and associated tests. The submitted implementation still has correctness defects that can lose user layout changes, fail to reload persisted positions, expose the wrong floating action button after tab navigation, and accept invalid chapter data. There are also architecture/test reliability issues that should be corrected before the phase is closed.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Saved graph positions can crash on reload because Hive maps are cast too narrowly

**File:** `lib/features/story_structure/infrastructure/node_position_repository.dart:26-42`

**Issue:** `getPosition()` and `getAllPositions()` cast Hive values with `json as Map<String, dynamic>`. Hive boxes commonly deserialize maps as `Map<dynamic, dynamic>` (or another runtime map type), even when the original value was produced from a `Map<String, dynamic>`. After an app restart, valid saved positions can therefore throw `StateError` and make the position provider fail instead of restoring the graph layout.

**Fix:** Normalize the persisted map before passing it to the domain factory.

```dart
NodePosition _decodePosition(Object? value) {
  if (value == null) {
    throw const FormatException('Missing node position');
  }
  return NodePosition.fromJson(Map<String, dynamic>.from(value as Map));
}

Offset? getPosition(String plotNodeId) {
  try {
    final json = _box.get(plotNodeId);
    if (json == null) return null;
    return _decodePosition(json).toOffset();
  } catch (e) {
    throw StateError('Failed to read node position $plotNodeId: $e');
  }
}
```

### CR-02: Debounced saving drops earlier node drags

**File:** `lib/features/story_structure/presentation/story_arc/story_arc_graph.dart:241-247`

**Issue:** `_positionSaveTimer` is a single shared timer. Dragging node A schedules a save, but dragging node B within one second cancels the pending timer and only saves B. The user sees both nodes move in memory, but A's position is silently lost on rebuild/restart.

**Fix:** Save immediately on drag end, or keep one debounce timer per node ID.

```dart
final Map<String, Timer> _positionSaveTimers = {};

void _debouncedSavePosition(String nodeId, Offset position) {
  _positionSaveTimers.remove(nodeId)?.cancel();
  _positionSaveTimers[nodeId] = Timer(const Duration(seconds: 1), () {
    ref.read(nodePositionNotifierProvider.notifier).savePosition(nodeId, position);
    _positionSaveTimers.remove(nodeId);
  });
}

@override
void dispose() {
  for (final timer in _positionSaveTimers.values) {
    timer.cancel();
  }
  _transformationController.dispose();
  super.dispose();
}
```

### CR-03: Story structure FAB does not rebuild when the selected tab changes

**File:** `lib/features/story_structure/presentation/story_structure_page.dart:33-69`

**Issue:** `_buildFAB()` depends on `_tabController.index`, but the state never listens to tab index changes. Switching from the plot tabs to Guardian/Export can leave the plot-node FAB visible, and switching into the graph tab can leave the wrong/null FAB until another rebuild happens. This is incorrect UI behavior and can expose create actions in sections where they do not belong.

**Fix:** Add a tab-controller listener that calls `setState()` when the tab index changes.

```dart
@override
void initState() {
  super.initState();
  _tabController = TabController(length: 5, vsync: this)
    ..addListener(_handleTabChanged);
}

void _handleTabChanged() {
  if (!_tabController.indexIsChanging && mounted) {
    setState(() {});
  }
}

@override
void dispose() {
  _tabController.removeListener(_handleTabChanged);
  _tabController.dispose();
  super.dispose();
}
```

### CR-04: Node edit form accepts invalid chapter numbers

**File:** `lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart:166-186`

**Issue:** The chapter field uses `int.tryParse(...) ?? 1`, so non-numeric input is silently converted to chapter 1, and zero/negative chapters are accepted. This violates the project's user-input validation rule and can persist invalid story structure data.

**Fix:** Validate that chapter is a positive integer and block saving with a clear error if not.

```dart
final chapterText = _chapterController.text.trim();
final chapter = int.tryParse(chapterText);
if (chapter == null || chapter < 1) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('请输入有效的章节号')),
  );
  return;
}
```

## Warnings

### WR-01: Domain entity imports Flutter UI types

**File:** `lib/features/story_structure/domain/node_position.dart:1-18`

**Issue:** The domain layer imports `dart:ui` and exposes `Offset` via `toOffset()`. Project architecture rules require the domain layer to be pure Dart and not depend on Flutter/UI libraries. This couples narrative/domain state to Flutter rendering primitives and makes the domain model less portable.

**Fix:** Keep `NodePosition` as pure coordinates and move `Offset` conversion to presentation/application code or an extension outside the domain layer.

```dart
// domain/node_position.dart
class NodePosition {
  final String plotNodeId;
  final double x;
  final double y;
  // no dart:ui import
}

// presentation/application adapter
extension NodePositionOffsetX on NodePosition {
  Offset toOffset() => Offset(x, y);
}
```

### WR-02: Tests do not cover the critical graph behaviors that regressed

**File:** `test/features/story_structure/presentation/story_arc_graph_test.dart:47-72`

**Issue:** The graph test only asserts that node labels render. It does not exercise foreshadowing edge construction, drag persistence, or the debounce behavior. As a result, the single-timer data-loss bug and previous foreshadowing mapping bug can pass the test suite.

**Fix:** Add widget/unit tests that simulate dragging two different nodes within the debounce window and verify both saves occur, plus a test that constructs two plot nodes sharing a `linkedForeshadowingIds` entry and verifies a foreshadowing edge is created/rendered.

---

_Reviewed: 2026-06-05T18:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

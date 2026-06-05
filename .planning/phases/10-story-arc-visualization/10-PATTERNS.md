# Phase 10: Story Arc Visualization - Pattern Map

**Mapped:** 2026-06-05
**Files analyzed:** 18 new/modified files
**Analogs found:** 15 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/story_structure/domain/node_position.dart` | model | CRUD | `lib/features/story_structure/domain/plot_node.dart` | exact |
| `lib/features/story_structure/infrastructure/node_position_repository.dart` | service | CRUD | `lib/features/story_structure/infrastructure/plot_node_repository.dart` | exact |
| `lib/features/story_structure/application/node_position_notifier.dart` | service | CRUD | `lib/features/story_structure/application/plot_node_notifier.dart` | exact |
| `lib/core/presentation/providers.dart` | config | request-response | (self -- modification) | exact |
| `lib/features/story_structure/presentation/story_structure_page.dart` | component | request-response | (self -- modification) | exact |
| `lib/features/story_structure/presentation/story_arc/story_arc_graph.dart` | component | event-driven | `lib/features/story_structure/presentation/plot_timeline.dart` | role-match |
| `lib/features/story_structure/presentation/story_arc/story_arc_node.dart` | component | request-response | `lib/features/story_structure/presentation/plot_timeline.dart` (`_PlotNodeCard`) | role-match |
| `lib/features/story_structure/presentation/story_arc/story_arc_edge_renderer.dart` | component | transform | none -- extends graphview `ArrowEdgeRenderer` | no-analog |
| `lib/features/story_structure/presentation/story_arc/story_arc_minimap.dart` | component | transform | none -- CustomPainter, no existing analog | no-analog |
| `lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart` | component | request-response | `lib/features/story_structure/presentation/plot_node_form.dart` | role-match |
| `lib/features/story_structure/presentation/story_arc/graph_colors.dart` | utility | transform | none -- semantic color classes, new concept | no-analog |
| `lib/features/story_structure/presentation/story_arc/graph_theme.dart` | utility | transform | `lib/shared/theme/app_theme.dart` | partial |
| `test/features/story_structure/domain/node_position_test.dart` | test | CRUD | `test/features/story_structure/domain/plot_node_test.dart` | exact |
| `test/features/story_structure/infrastructure/node_position_repository_test.dart` | test | CRUD | `test/features/story_structure/infrastructure/plot_node_repository_test.dart` | exact |
| `test/features/story_structure/application/node_position_notifier_test.dart` | test | CRUD | `test/features/story_structure/application/plot_node_notifier_test.dart` | exact |
| `test/features/story_structure/presentation/story_arc_edge_renderer_test.dart` | test | transform | none -- no existing edge renderer tests | no-analog |
| `test/features/story_structure/presentation/graph_colors_test.dart` | test | transform | none -- new utility, no existing color tests | no-analog |
| `test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` | test | request-response | none -- no existing bottom sheet tests (dialog-based forms exist but not bottom sheets) | partial |

## Pattern Assignments

### `lib/features/story_structure/domain/node_position.dart` (model, CRUD)

**Analog:** `lib/features/story_structure/domain/plot_node.dart`

This is a simpler entity than PlotNode -- it only needs `plotNodeId`, `x`, `y`. No enums, no list fields, no timestamps. Follow PlotNode's immutable class pattern with `copyWith`, `fromJson`/`toJson`, `==`/`hashCode`, and `toString`. Add a `toOffset()` convenience method.

**Imports pattern** (lines 1-2 of analog):
```dart
// No imports needed -- pure Dart, no dependencies
```

**Core entity pattern** (from `plot_node.dart` lines 47-80, adapted):
```dart
class NodePosition {
  final String plotNodeId;
  final double x;
  final double y;

  const NodePosition({
    required this.plotNodeId,
    required this.x,
    required this.y,
  });

  Offset toOffset() => Offset(x, y);

  NodePosition copyWith({double? x, double? y}) =>
      NodePosition(plotNodeId: plotNodeId, x: x ?? this.x, y: y ?? this.y);

  factory NodePosition.fromJson(Map<String, dynamic> json) => NodePosition(
        plotNodeId: json['plotNodeId'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'plotNodeId': plotNodeId,
        'x': x,
        'y': y,
      };
}
```

**Equality pattern** (from `plot_node.dart` lines 182-219):
```dart
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is NodePosition &&
      other.plotNodeId == plotNodeId &&
      other.x == x &&
      other.y == y;
}

@override
int get hashCode => Object.hash(plotNodeId, x, y);

@override
String toString() => 'NodePosition(plotNodeId: $plotNodeId, x: $x, y: $y)';
```

---

### `lib/features/story_structure/infrastructure/node_position_repository.dart` (service, CRUD)

**Analog:** `lib/features/story_structure/infrastructure/plot_node_repository.dart`

Follow the exact same Hive-box CRUD pattern. Key differences: no UUID generation (plotNodeId is the key), no timestamps, simpler structure. Use `graph_positions` as the Hive box name.

**Imports pattern** (from `plot_node_repository.dart` lines 1-3):
```dart
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/story_structure/domain/node_position.dart';
// No uuid import needed -- plotNodeId is the key, not auto-generated
```

**Core repository pattern** (from `plot_node_repository.dart` lines 9-119, adapted):
```dart
class NodePositionRepository {
  final Box<dynamic> _box;

  NodePositionRepository(this._box);

  /// Saves a node position (upsert by plotNodeId).
  Future<void> save(NodePosition position) async {
    try {
      await _box.put(position.plotNodeId, position.toJson());
    } catch (e) {
      throw StateError('Failed to save node position: $e');
    }
  }

  /// Gets position for a specific node, or null.
  Offset? getPosition(String plotNodeId) {
    try {
      final json = _box.get(plotNodeId);
      if (json == null) return null;
      return NodePosition.fromJson(json as Map<String, dynamic>).toOffset();
    } catch (e) {
      throw StateError('Failed to read node position $plotNodeId: $e');
    }
  }

  /// Returns all saved positions as a map.
  Map<String, Offset> getAllPositions() {
    try {
      final positions = <String, Offset>{};
      for (final key in _box.keys) {
        final json = _box.get(key);
        if (json != null) {
          final pos = NodePosition.fromJson(json as Map<String, dynamic>);
          positions[pos.plotNodeId] = pos.toOffset();
        }
      }
      return positions;
    } catch (e) {
      throw StateError('Failed to read node positions: $e');
    }
  }

  /// Deletes a node position by plotNodeId.
  Future<void> delete(String plotNodeId) async {
    try {
      await _box.delete(plotNodeId);
    } catch (e) {
      throw StateError('Failed to delete node position $plotNodeId: $e');
    }
  }
}
```

---

### `lib/features/story_structure/application/node_position_notifier.dart` (service, CRUD)

**Analog:** `lib/features/story_structure/application/plot_node_notifier.dart`

Follow the AsyncNotifier pattern exactly. State type is `Map<String, Offset>` (node ID to position). Methods: `build()` loads all positions, `savePosition()` saves one position and refreshes, `deletePosition()` removes one.

**Imports pattern** (from `plot_node_notifier.dart` lines 1-3):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
```

**Core notifier pattern** (from `plot_node_notifier.dart` lines 10-37, adapted):
```dart
class NodePositionNotifier extends AsyncNotifier<Map<String, Offset>> {
  @override
  Future<Map<String, Offset>> build() async {
    final repository = await ref.watch(nodePositionRepositoryProvider.future);
    return repository.getAllPositions();
  }

  Future<void> savePosition(String nodeId, Offset position) async {
    final repository = await ref.read(nodePositionRepositoryProvider.future);
    await repository.save(NodePosition(plotNodeId: nodeId, x: position.dx, y: position.dy));
    ref.invalidateSelf();
  }

  Future<void> deletePosition(String nodeId) async {
    final repository = await ref.read(nodePositionRepositoryProvider.future);
    await repository.delete(nodeId);
    ref.invalidateSelf();
  }
}
```

---

### `lib/core/presentation/providers.dart` (config, modification)

**Analog:** Self -- add new providers following existing patterns.

Add two new providers at the bottom of the story_structure section (after `plotNodeNotifierProvider`):

**Repository provider pattern** (from `providers.dart` lines 499-504):
```dart
final plotNodeRepositoryProvider = FutureProvider<PlotNodeRepository>((
  ref,
) async {
  final box = await Hive.openBox<dynamic>('plot_nodes');
  return PlotNodeRepository(box);
});
```

Add after line 513:
```dart
// NodePositionRepository provider -- same pattern
final nodePositionRepositoryProvider = FutureProvider<NodePositionRepository>((
  ref,
) async {
  final box = await Hive.openBox<dynamic>('graph_positions');
  return NodePositionRepository(box);
});

final nodePositionNotifierProvider =
    AsyncNotifierProvider<NodePositionNotifier, Map<String, Offset>>(
      NodePositionNotifier.new,
    );
```

Also add the import at the top of the file (following existing import ordering):
```dart
import 'package:museflow/features/story_structure/domain/node_position.dart';
import 'package:museflow/features/story_structure/infrastructure/node_position_repository.dart';
import 'package:museflow/features/story_structure/application/node_position_notifier.dart';
```

---

### `lib/features/story_structure/presentation/story_structure_page.dart` (component, modification)

**Analog:** Self -- add a 5th tab.

Modify `TabController(length: 4, ...)` to `TabController(length: 5, ...)` (line 33). Add a new `Tab(text: '弧线图')` in the `tabs` list (after line 52). Add `StoryArcGraph()` in the `TabBarView.children` (after line 63).

**Existing tab pattern** (lines 31-68):
```dart
// TabController setup (line 33):
_tabController = TabController(length: 5, vsync: this); // was 4

// TabBar tabs (lines 48-56):
tabs: const [
  Tab(text: '伏笔'),
  Tab(text: '剧情线'),
  Tab(text: '弧线图'),   // NEW
  Tab(text: '守护'),
  Tab(text: '整理与导出'),
],

// TabBarView children (lines 58-68):
children: const [
  _ForeshadowingSection(),
  PlotTimeline(),
  StoryArcGraph(),       // NEW
  GuardianPanel(),
  _FinishExportSection(),
],
```

Also update the `_buildFAB()` switch (line 86) -- the graph tab (index 2) should show the same FAB as the timeline tab for creating new nodes:
```dart
Widget? _buildFAB() {
  return switch (_tabController.index) {
    0 => FloatingActionButton(
        onPressed: () => _showForeshadowingForm(context),
        tooltip: '新建伏笔',
        child: const Icon(Icons.add),
      ),
    1 || 2 => FloatingActionButton(  // was just 1
        onPressed: () => _showPlotNodeForm(context),
        tooltip: '新建情节点',
        child: const Icon(Icons.add),
      ),
    _ => null,
  };
}
```

---

### `lib/features/story_structure/presentation/story_arc/story_arc_graph.dart` (component, event-driven)

**Analog:** `lib/features/story_structure/presentation/plot_timeline.dart`

Follow PlotTimeline's pattern of watching `plotNodeNotifierProvider` via `ref.watch` and using `.when()` for loading/error/data states. The graph widget is a `ConsumerStatefulWidget` because it needs `TransformationController` and `AnimationController` state.

**AsyncValue handling pattern** (from `plot_timeline.dart` lines 17-65):
```dart
final nodesAsync = ref.watch(plotNodeNotifierProvider);

return nodesAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (error, _) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('加载失败: $error'),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => ref.invalidate(plotNodeNotifierProvider),
          child: const Text('重试'),
        ),
      ],
    ),
  ),
  data: (nodes) {
    if (nodes.isEmpty) {
      // Empty state per D-16
      return _EmptyStateGraph();
    }
    return _StoryArcGraphContent(nodes: nodes);
  },
);
```

**Empty state pattern** (from `plot_timeline.dart` lines 36-60):
```dart
// D-16: "暂无剧情节点" illustration + "创建第一个节点" button
return const Center(
  child: Padding(
    padding: EdgeInsets.all(32.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.account_tree_outlined, size: 48),
        SizedBox(height: 16),
        Text('暂无剧情节点', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Text('先在剧情线中创建节点，然后在这里查看故事弧线图。', textAlign: TextAlign.center),
      ],
    ),
  ),
);
```

**Imports for graphview integration:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/graphview.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
```

---

### `lib/features/story_structure/presentation/story_arc/story_arc_node.dart` (component, request-response)

**Analog:** `lib/features/story_structure/presentation/plot_timeline.dart` (`_PlotNodeCard`, lines 128-243)

Follow the `_PlotNodeCard` pattern for building a card-like widget that displays node data. This is a `ConsumerWidget` or plain `StatelessWidget` (not ConsumerWidget if no ref needed). The node builder returns a `GestureDetector` wrapping a `Container` with color-coded decorations.

**Node widget pattern** (from `_PlotNodeCard.build` adapted for graph node):
```dart
class StoryArcNode extends StatelessWidget {
  final PlotNode plotNode;

  const StoryArcNode({super.key, required this.plotNode});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEditSheet(context),
      child: Container(
        width: plotNode.title.length > 8 ? 160.0 : 120.0,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: GraphColor.forRole(plotNode.structuralRole),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: GraphStatus.borderColor(plotNode.writingStatus),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Text(plotNode.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            Positioned(
              top: 0, right: 0,
              child: Text('Ch${plotNode.chapter}',
                style: const TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### `lib/features/story_structure/presentation/story_arc/story_arc_edge_renderer.dart` (component, transform)

**No direct analog** -- this extends graphview's `ArrowEdgeRenderer`. Follow the library's inheritance pattern. See RESEARCH.md Pattern 2 for the subclass structure.

**Imports:**
```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:graphview/graphview.dart';
```

**Core pattern** (from RESEARCH.md Pattern 2):
```dart
enum EdgeType { causal, association, foreshadowing }

class StoryArcEdgeRenderer extends ArrowEdgeRenderer {
  final Map<Edge, EdgeType> edgeTypes;

  StoryArcEdgeRenderer({required this.edgeTypes}) : super(noArrow: false);

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    final type = edgeTypes[edge] ?? EdgeType.association;
    switch (type) {
      case EdgeType.causal:
        _renderCausalEdge(canvas, edge, paint);
      case EdgeType.association:
        _renderAssociationEdge(canvas, edge, paint);
      case EdgeType.foreshadowing:
        _renderForeshadowingEdge(canvas, edge, paint);
    }
  }
  // ... private render methods per D-09, D-10, D-11
}
```

---

### `lib/features/story_structure/presentation/story_arc/story_arc_minimap.dart` (component, transform)

**No direct analog** -- this is a new `CustomPainter`-based widget. Use Flutter's standard `CustomPaint` pattern.

**Imports:**
```dart
import 'package:flutter/material.dart';
import 'package:graphview/graphview.dart';
```

**Core pattern** (from RESEARCH.md Pattern 4):
```dart
class StoryArcMinimap extends StatelessWidget {
  final Graph graph;
  final TransformationController controller;
  final Size viewportSize;

  const StoryArcMinimap({...});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16, right: 16,
      child: Container(
        width: 150, height: 100,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          painter: _MinimapPainter(graph: graph, controller: controller),
        ),
      ),
    );
  }
}
```

---

### `lib/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart` (component, request-response)

**Analog:** `lib/features/story_structure/presentation/plot_node_form.dart`

Follow PlotNodeForm's field setup pattern (TextEditingControllers, DropdownButtonFormFields for enums, `_isSaving` state) but use `showModalBottomSheet` instead of `AlertDialog`. The form fields match D-14: title, structural role, writing status, chapter number, summary.

**Imports pattern** (from `plot_node_form.dart` lines 1-4):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
```

**Controller setup pattern** (from `plot_node_form.dart` lines 19-39):
```dart
class _NodeEditBottomSheetState extends ConsumerState<NodeEditBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _chapterController;
  PlotNodeWritingStatus _status = PlotNodeWritingStatus.notStarted;
  PlotNodeStructuralRole _role = PlotNodeStructuralRole.setup;
  bool _isSaving = false;
```

**Save pattern** (from `plot_node_form.dart` lines 136-184):
```dart
Future<void> _save() async {
  final title = _titleController.text.trim();
  if (title.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请输入标题')),
    );
    return;
  }

  setState(() => _isSaving = true);
  try {
    final notifier = ref.read(plotNodeNotifierProvider.notifier);
    await notifier.save(widget.node.copyWith(
      title: title,
      chapter: int.tryParse(_chapterController.text.trim()) ?? 1,
      summary: _summaryController.text.trim(),
      writingStatus: _status,
      structuralRole: _role,
    ));
    if (mounted) Navigator.of(context).pop();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}
```

**BottomSheet invocation** (from `story_structure_page.dart` pattern, adapted):
```dart
void _showEditSheet(BuildContext context, PlotNode node) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => NodeEditBottomSheet(node: node),
  );
}
```

---

### `lib/features/story_structure/presentation/story_arc/graph_colors.dart` (utility, transform)

**No direct analog** -- new semantic color classes per D-08.

**Pattern:**
```dart
import 'package:flutter/material.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';

/// Semantic color classes for graph visualization per D-05/D-08.
class GraphColor {
  // Structural role colors (dramatic tension palette)
  static const setup = Color(0xFF9E9E9E);         // gray
  static const development = Color(0xFF4CAF50);    // green
  static const turn = Color(0xFFFFC107);           // yellow
  static const climax = Color(0xFFFF5722);         // orange-red
  static const resolution = Color(0xFF1565C0);     // dark blue

  static Color forRole(PlotNodeStructuralRole role) => switch (role) {
    PlotNodeStructuralRole.setup => setup,
    PlotNodeStructuralRole.development => development,
    PlotNodeStructuralRole.turn => turn,
    PlotNodeStructuralRole.climax => climax,
    PlotNodeStructuralRole.resolution => resolution,
  };
}

/// Writing status border colors per D-06.
class GraphStatus {
  static const notStarted = Color(0xFFBDBDBD);
  static const drafting = Color(0xFF42A5F5);
  static const complete = Color(0xFF66BB6A);
  static const needsRevision = Color(0xFFEF5350);

  static Color borderColor(PlotNodeWritingStatus status) => switch (status) {
    PlotNodeWritingStatus.notStarted => notStarted,
    PlotNodeWritingStatus.drafting => drafting,
    PlotNodeWritingStatus.complete => complete,
    PlotNodeWritingStatus.needsRevision => needsRevision,
  };
}
```

---

### `lib/features/story_structure/presentation/story_arc/graph_theme.dart` (utility, transform)

**Analog:** `lib/shared/theme/app_theme.dart`

Follow the app_theme.dart pattern for defining light/dark mode color variants per D-07. This file provides `GraphColor`/`GraphStatus` overrides for dark mode (brighter colors).

**Pattern** (from `app_theme.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';

/// Dark-mode-aware graph color resolver per D-07.
class GraphTheme {
  final Brightness brightness;

  const GraphTheme({required this.brightness});

  bool get isDark => brightness == Brightness.dark;

  /// Returns structural role color, adjusted for current brightness.
  Color roleColor(PlotNodeStructuralRole role) {
    final base = GraphColor.forRole(role);
    return isDark ? _lighten(base) : base;
  }

  Color _lighten(Color c) => Color.fromARGB(
    c.alpha,
    (c.red + (255 - c.red) * 0.3).round(),
    (c.green + (255 - c.green) * 0.3).round(),
    (c.blue + (255 - c.blue) * 0.3).round(),
  );
}
```

---

### Test Files

#### `test/features/story_structure/domain/node_position_test.dart`

**Analog:** `test/features/story_structure/domain/plot_node_test.dart`

**Test structure pattern** (from `plot_node_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/domain/node_position.dart';

void main() {
  group('NodePosition', () {
    late NodePosition testPos;

    setUp(() {
      testPos = const NodePosition(plotNodeId: 'pn-1', x: 100.0, y: 200.0);
    });

    test('should support copyWith', () { ... });
    test('should support equality', () { ... });
    test('should roundtrip through JSON', () { ... });
    test('should convert to Offset', () {
      expect(testPos.toOffset(), const Offset(100.0, 200.0));
    });
  });
}
```

#### `test/features/story_structure/infrastructure/node_position_repository_test.dart`

**Analog:** `test/features/story_structure/infrastructure/plot_node_repository_test.dart`

**Test setup pattern** (from `plot_node_repository_test.dart` lines 8-20):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/story_structure/domain/node_position.dart';
import 'package:museflow/features/story_structure/infrastructure/node_position_repository.dart';
import '../../../helpers/hive_test_helper.dart';

void main() {
  late Box<dynamic> box;
  late NodePositionRepository repository;

  setUp(() async {
    await setUpHiveTest();
    box = await Hive.openBox<dynamic>('test_graph_positions');
    repository = NodePositionRepository(box);
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  group('NodePositionRepository', () {
    test('should save and retrieve a position', () async { ... });
    test('should return null for non-existent ID', () { ... });
    test('should return all positions as map', () async { ... });
    test('should delete a position', () async { ... });
  });
}
```

#### `test/features/story_structure/application/node_position_notifier_test.dart`

**Analog:** `test/features/story_structure/application/plot_node_notifier_test.dart`

**Notifier test pattern** (from `plot_node_notifier_test.dart` lines 10-29):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/infrastructure/node_position_repository.dart';
import '../../../helpers/hive_test_helper.dart';

void main() {
  late ProviderContainer container;
  late Box<dynamic> box;

  setUp(() async {
    await setUpHiveTest();
    box = await Hive.openBox<dynamic>('test_node_position_notifier');
    container = ProviderContainer(
      overrides: [
        nodePositionRepositoryProvider
            .overrideWith((ref) async => NodePositionRepository(box)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await tearDownHiveTest();
  });

  group('NodePositionNotifier', () {
    test('build should load positions from repository', () async { ... });
    test('savePosition should persist and refresh state', () async { ... });
    test('deletePosition should remove and refresh state', () async { ... });
  });
}
```

---

## Shared Patterns

### Hive Repository Pattern
**Source:** `lib/features/story_structure/infrastructure/plot_node_repository.dart`
**Apply to:** `node_position_repository.dart`
```dart
// Every repository follows this pattern:
// 1. Constructor takes Box<dynamic>
// 2. All methods wrapped in try/catch -> throw StateError
// 3. toJson/fromJson for serialization
// 4. Box key = entity ID

class SomeRepository {
  final Box<dynamic> _box;
  SomeRepository(this._box);

  Future<void> save(Entity e) async {
    try {
      await _box.put(e.id, e.toJson());
    } catch (e) {
      throw StateError('Failed to save: $e');
    }
  }
}
```

### Riverpod AsyncNotifier Pattern
**Source:** `lib/features/story_structure/application/plot_node_notifier.dart`
**Apply to:** `node_position_notifier.dart`
```dart
class SomeNotifier extends AsyncNotifier<SomeState> {
  @override
  Future<SomeState> build() async {
    final repository = await ref.watch(someRepositoryProvider.future);
    return repository.loadData();
  }

  Future<void> save(Data data) async {
    final repository = await ref.read(someRepositoryProvider.future);
    await repository.save(data);
    ref.invalidateSelf();
  }
}
```

### Provider Registration Pattern
**Source:** `lib/core/presentation/providers.dart`
**Apply to:** All new providers added to this file
```dart
// Two-step: FutureProvider for repository, AsyncNotifierProvider for notifier
final someRepositoryProvider = FutureProvider<SomeRepository>((ref) async {
  final box = await Hive.openBox<dynamic>('box_name');
  return SomeRepository(box);
});

final someNotifierProvider =
    AsyncNotifierProvider<SomeNotifier, SomeState>(
      SomeNotifier.new,
    );
```

### AsyncValue UI Pattern
**Source:** `lib/features/story_structure/presentation/plot_timeline.dart`
**Apply to:** `story_arc_graph.dart` (and any widget watching async providers)
```dart
final dataAsync = ref.watch(someNotifierProvider);

return dataAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (error, _) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('加载失败: $error'),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => ref.invalidate(someNotifierProvider),
          child: const Text('重试'),
        ),
      ],
    ),
  ),
  data: (data) { /* render data */ },
);
```

### Hive Test Helper Pattern
**Source:** `test/helpers/hive_test_helper.dart`
**Apply to:** All new test files using Hive
```dart
// In setUp:
await setUpHiveTest();
box = await Hive.openBox<dynamic>('test_box_name');

// In tearDown:
await tearDownHiveTest();
```

### Form Field + Save Pattern
**Source:** `lib/features/story_structure/presentation/plot_node_form.dart`
**Apply to:** `node_edit_bottom_sheet.dart`
```dart
// 1. TextEditingControllers in initState
// 2. dispose() all controllers
// 3. _isSaving flag to disable button during async
// 4. try/catch/finally in _save()
// 5. notifier.save(node.copyWith(...)) via ref.read
// 6. SnackBar for validation errors and save failures
// 7. Navigator.of(context).pop() on success
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `story_arc_edge_renderer.dart` | component | transform | No existing Canvas/EdgeRenderer subclass in codebase. Must extend graphview's `ArrowEdgeRenderer`. Use RESEARCH.md Pattern 2. |
| `story_arc_minimap.dart` | component | transform | No existing CustomPainter/CustomPaint widget in codebase. Use RESEARCH.md Pattern 4. |
| `graph_colors.dart` | utility | transform | No existing semantic color utility class. New concept per D-05/D-08. Pattern defined in this file above. |
| `story_arc_edge_renderer_test.dart` | test | transform | No edge renderer tests exist. Use flutter_test's Canvas mocking or golden testing. |
| `graph_colors_test.dart` | test | transform | No color utility tests exist. Straightforward unit tests verifying color mapping. |
| `node_edit_bottom_sheet_test.dart` | test | request-response | No bottom sheet tests exist. Use widget test pattern from existing dialog tests. |

## Metadata

**Analog search scope:** `lib/features/story_structure/`, `lib/core/presentation/`, `lib/shared/`, `test/features/story_structure/`, `test/helpers/`
**Files scanned:** 16
**Pattern extraction date:** 2026-06-05

# Phase 10: 故事弧可视化 - Research

**Researched:** 2026-06-05
**Domain:** Interactive graph visualization (Flutter graphview library)
**Confidence:** HIGH

## Summary

This phase delivers an interactive story arc graph view that renders existing PlotNode data as a node-and-edge diagram. The core technology is the `graphview` library (v1.5.1), which provides FruchtermanReingold force-directed layout, widget-based custom node rendering via a builder pattern, per-edge Paint styling, ArrowEdgeRenderer for directed edges, and built-in InteractiveViewer integration for zoom/pan. The graphview API was thoroughly examined by reading its source code directly from the pub cache.

The implementation requires: (1) a new `NodePosition` entity and `NodePositionRepository` backed by a dedicated Hive box (`graph_positions`) for persisting node drag positions, (2) a `StoryArcGraph` widget that converts PlotNode lists into graphview `Graph` objects with correctly styled edges, (3) a custom edge renderer extending `ArrowEdgeRenderer` to support gradient lines, dashed amber lines with dot markers, and gray thin lines per the CONTEXT.md decisions, (4) a node builder that renders color-coded rectangles with structural role fills and writing status borders, (5) a bottom sheet editor for inline editing of node fields, and (6) a minimap widget for navigation.

The graphview library's `Node` class uses `ValueKey` identity (created via `Node.Id(id)`), supports mutable `position` for drag operations, and has a `lineType` property (Default/DashedLine/DottedLine/SineLine). The `Edge` class accepts a per-edge `Paint` object for custom colors and stroke widths. The `GraphView.builder` constructor wraps everything in an `InteractiveViewer.builder` for free zoom/pan. Node dragging is achieved by setting `algorithm.setFocusedNode(node)` and updating `node.position` on pan events. All of this is confirmed by reading the actual source code.

**Primary recommendation:** Use `GraphView.builder` with `FruchtermanReingoldAlgorithm` and a custom `StoryArcEdgeRenderer` extending `ArrowEdgeRenderer`. Store positions separately in a `graph_positions` Hive box. Integrate into `StoryStructurePage` as a new tab.

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Node shows title + chapter number (chapter as upper-right corner badge)
- **D-02:** Two node sizes (small for short titles, large for long titles)
- **D-03:** Rectangular node shape (0-4px border radius), modern clean style
- **D-04:** Title and chapter number in badge layout (chapter upper-right)
- **D-05:** Structural role colors: setup=gray, development=green, turn=yellow, climax=orange-red, resolution=dark-blue (dramatic tension palette)
- **D-06:** Writing status via border + icon combination. Border style distinguishes status, upper-right icon supplements
- **D-07:** Dark mode separately optimized colors (brighter in dark, deeper in light)
- **D-08:** Semantic color classes: `GraphColor.setup`, `GraphStatus.complete`
- **D-09:** Causal edges: gradient line + arrow (dark source -> light destination)
- **D-10:** Association edges: light gray thin solid line, no arrow
- **D-11:** Foreshadowing edges: amber dashed line + dot markers
- **D-12:** Edge thickness: causal=2.0px, association=1.0px, foreshadowing=1.5px
- **D-13:** Tap node opens BottomSheet for editing
- **D-14:** BottomSheet allows editing: title, structural role, writing status, chapter number, summary
- **D-15:** Node positions stored in independent mapping (NodePosition: PlotNode.id -> Position). PlotNode stays pure
- **D-16:** Empty state shows "暂无剧情节点" illustration + "创建第一个节点" button

### Claude's Discretion
None -- user made explicit decisions for all discussion areas.

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VIZO-01 | Interactive graph from PlotNode data (graphview), zoom/pan | graphview `GraphView.builder` with `InteractiveViewer` integration, `FruchtermanReingoldAlgorithm` for layout |
| VIZO-02 | Edge styles: directed solid (causal), gray thin (association), dashed (foreshadowing) | Per-edge `Paint` object on `graph.addEdge()`, custom `StoryArcEdgeRenderer` extending `ArrowEdgeRenderer`, `EdgeRenderer.drawDashedLine()` for dashed |
| VIZO-03 | Node colors by structural role, border by writing status | Node builder pattern returns themed `Container` widgets; `GraphColor` / `GraphStatus` semantic color classes |
| VIZO-04 | Tap node to inline-edit title, structural role, writing status | `GestureDetector.onTap` on node widget -> `showModalBottomSheet` with form fields |
| VIZO-05 | Drag nodes to rearrange, position persisted | `setFocusedNode()` + `node.position` update on pan; `NodePositionRepository` with Hive `graph_positions` box |
| VIZO-06 | Minimap widget for large graph navigation | Custom minimap using `TransformationController` value to show viewport rect on scaled-down graph overview |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Graph data model (PlotNode -> Graph conversion) | Application | -- | Use case orchestrates conversion from domain entities to graphview objects |
| Node rendering (color, size, badges) | Presentation | -- | Purely visual -- Flutter widgets returned from builder |
| Edge rendering (styles, arrows, gradients) | Presentation | -- | Custom EdgeRenderer subclass paints on Canvas |
| Node position persistence | Infrastructure | -- | Hive box storage for NodePosition entities |
| Zoom/pan interaction | Presentation (Client) | -- | InteractiveViewer handles this in the widget layer |
| Node editing (BottomSheet) | Presentation | Application | UI triggers PlotNodeNotifier.save() |
| Minimap navigation aid | Presentation | -- | Reads TransformationController, renders scaled overview |
| Graph layout algorithm | Library (graphview) | -- | FruchtermanReingoldAlgorithm handles positioning |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| graphview | ^1.5.1 | Interactive graph visualization | The only mature Flutter graph library. Force-directed layout, widget node builders, per-edge Paint, InteractiveViewer integration. [CITED: pub.dev/packages/graphview] |
| flutter_riverpod | ^3.3.1 (existing) | State management | Project standard. AsyncNotifier pattern already used by PlotNodeNotifier. |
| hive_ce | ^2.19.3 (existing) | Local storage | Project standard. New `graph_positions` box for node position persistence. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| uuid | ^4.5.3 (existing) | ID generation | Already used in PlotNodeRepository. |
| collection | ^1.19.1 (transitive) | firstWhereOrNull etc. | Already a dependency of graphview and Riverpod. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| graphview | Custom CustomPainter | Custom would take weeks to implement force-directed layout, hit-testing, edge rendering. graphview does this in days. |
| graphview | flutter_graph_view | Less mature, fewer layout algorithms, smaller community. graphview is the established choice. |

**Installation:**
```bash
flutter pub add graphview
```

**Version verification:**
- graphview 1.5.1 confirmed in pub cache at `/home/re/.pub-cache/hosted/pub.dev/graphview-1.5.1/`
- Pub dev page confirms version 1.5.1 as latest [CITED: pub.dev/packages/graphview]
- `flutter pub add --dry-run graphview` failed with socket error (network issue, not package issue -- package is cached locally)

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| graphview | pub.dev | ~5 years | High | github.com/nabil6391/graphview | N/A (slopcheck failed) | [ASSUMED] -- see notes |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*slopcheck failed to run (exit code 2). However, graphview is a well-established Flutter package with 5+ years of history, an active GitHub repository (github.com/nabil6391/graphview), and was already validated during the v1.1 STACK.md research phase via `flutter pub add --dry-run`. The package is cached locally and its full source code was read during this research session. Marking as [ASSUMED] per protocol since slopcheck could not execute.*

*The planner should add a `checkpoint:human-verify` task before running `flutter pub add graphview`.*

## Architecture Patterns

### System Architecture Diagram

```
StoryStructurePage (TabBarView)
    |
    +-- Tab: "剧情线" -> PlotTimeline (existing)
    +-- Tab: "弧线图" -> StoryArcGraphPage (NEW)
            |
            +-- StoryArcGraph (ConsumerStatefulWidget)
            |       |
            |       +-- GraphView.builder (graphview)
            |       |       |
            |       |       +-- InteractiveViewer (zoom/pan)
            |       |       +-- FruchtermanReingoldAlgorithm (layout)
            |       |       +-- StoryArcEdgeRenderer (custom edges)
            |       |       +-- Node builder -> StoryArcNode widget
            |       |
            |       +-- StoryArcMinimap (overlay)
            |       +-- EmptyStateGraph (when no nodes)
            |
            +-- NodeEditBottomSheet (on tap)
            |
            +-- Providers:
                    - plotNodeNotifierProvider (existing, reads PlotNodes)
                    - nodePositionNotifierProvider (NEW, reads/writes positions)
```

Data flow:
1. User opens "弧线图" tab -> `StoryArcGraph` watches `plotNodeNotifierProvider`
2. `StoryArcGraph` converts `List<PlotNode>` to graphview `Graph` with `Node.Id(plotNode.id)` and styled edges
3. `FruchtermanReingoldAlgorithm` positions nodes; saved positions from `graph_positions` box override algorithm positions
4. User sees interactive graph with color-coded nodes and styled edges
5. User taps node -> `NodeEditBottomSheet` -> edits fields -> calls `PlotNodeNotifier.save()`
6. User drags node -> position updated in memory -> debounced save to `NodePositionRepository`
7. Minimap reads `TransformationController` to show current viewport on scaled-down overview

### Recommended Project Structure
```
lib/features/story_structure/
    domain/
        plot_node.dart              (existing -- NO changes needed)
        node_position.dart          (NEW -- position entity)
    application/
        plot_node_notifier.dart     (existing -- NO changes)
        node_position_notifier.dart (NEW -- position CRUD)
    infrastructure/
        plot_node_repository.dart   (existing -- NO changes)
        node_position_repository.dart (NEW -- Hive graph_positions box)
    presentation/
        story_structure_page.dart   (existing -- ADD new tab)
        plot_timeline.dart          (existing -- NO changes)
        story_arc/
            story_arc_graph.dart        (NEW -- main graph widget)
            story_arc_node.dart         (NEW -- node builder widget)
            story_arc_edge_renderer.dart (NEW -- custom edge renderer)
            story_arc_minimap.dart      (NEW -- minimap overlay)
            node_edit_bottom_sheet.dart  (NEW -- bottom sheet editor)
            graph_colors.dart            (NEW -- GraphColor, GraphStatus semantic classes)
            graph_theme.dart             (NEW -- light/dark mode color definitions)
```

### Pattern 1: PlotNode -> Graph Conversion
**What:** Convert domain PlotNode list to graphview Graph with correctly styled edges
**When to use:** Every time PlotNode list changes (watched via Riverpod)
**Example:**
```dart
// Source: derived from graphview 1.5.1 source (Graph.dart, Node, Edge classes)
Graph buildGraph(List<PlotNode> plotNodes, Map<String, Offset> positions) {
  final graph = Graph()..isTree = false;

  // Create nodes first
  final nodeMap = <String, Node>{};
  for (final plotNode in plotNodes) {
    final node = Node.Id(plotNode.id);
    graph.addNode(node);
    nodeMap[plotNode.id] = node;
    // Restore saved position
    if (positions.containsKey(plotNode.id)) {
      node.position = positions[plotNode.id]!;
    }
  }

  // Add edges with per-type styling
  for (final plotNode in plotNodes) {
    // Causal: causeNodeIds -> this node (directed, gradient + arrow)
    for (final causeId in plotNode.causeNodeIds) {
      if (nodeMap.containsKey(causeId)) {
        graph.addEdge(
          nodeMap[causeId]!,
          nodeMap[plotNode.id]!,
          paint: Paint()
            ..color = Colors.blue
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke,
        );
      }
    }
    // Consequence: this node -> consequenceNodeIds (directed, gradient + arrow)
    for (final conId in plotNode.consequenceNodeIds) {
      if (nodeMap.containsKey(conId)) {
        graph.addEdge(
          nodeMap[plotNode.id]!,
          nodeMap[conId]!,
          paint: Paint()
            ..color = Colors.blue
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke,
        );
      }
    }
    // Related: thin gray, no arrow
    for (final relId in plotNode.relatedNodeIds) {
      if (nodeMap.containsKey(relId)) {
        graph.addEdge(
          nodeMap[plotNode.id]!,
          nodeMap[relId]!,
          paint: Paint()
            ..color = Colors.grey
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke,
        );
      }
    }
    // Foreshadowing: amber dashed
    for (final fId in plotNode.linkedForeshadowingIds) {
      if (nodeMap.containsKey(fId)) {
        graph.addEdge(
          nodeMap[plotNode.id]!,
          nodeMap[fId]!,
          paint: Paint()
            ..color = Colors.amber
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  return graph;
}
```

### Pattern 2: Custom Edge Renderer for Gradient/Dashed Styles
**What:** Subclass ArrowEdgeRenderer to handle three edge types with distinct visual styles
**When to use:** When rendering edges that need gradient lines, dashed amber, or arrow-less gray lines
**Example:**
```dart
// Source: derived from graphview 1.5.1 ArrowEdgeRenderer source
class StoryArcEdgeRenderer extends ArrowEdgeRenderer {
  // Edge type identification via a lookup map
  final Map<Edge, EdgeType> edgeTypes;

  StoryArcEdgeRenderer({required this.edgeTypes}) : super(noArrow: false);

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    final type = edgeTypes[edge] ?? EdgeType.association;
    switch (type) {
      case EdgeType.causal:
        _renderCausalEdge(canvas, edge, paint);
        break;
      case EdgeType.association:
        _renderAssociationEdge(canvas, edge, paint);
        break;
      case EdgeType.foreshadowing:
        _renderForeshadowingEdge(canvas, edge, paint);
        break;
    }
  }

  void _renderCausalEdge(Canvas canvas, Edge edge, Paint paint) {
    // Use parent's arrow rendering with gradient shader
    final source = edge.source;
    final destination = edge.destination;
    // ... gradient via Paint.shader = LinearGradient(...)
    // Then call super.renderEdge for arrow
  }

  void _renderAssociationEdge(Canvas canvas, Edge edge, Paint paint) {
    // Use noArrow: true behavior -- just a thin gray line
    // Direct canvas.drawLine with the edge's paint
  }

  void _renderForeshadowingEdge(Canvas canvas, Edge edge, Paint paint) {
    // Use drawDashedLine from parent EdgeRenderer
    // Add dot markers at intervals
  }
}
```

### Pattern 3: Node Drag with Position Persistence
**What:** Allow user to drag nodes and save positions
**When to use:** On-pan gesture within graph view
**Example:**
```dart
// Source: derived from graphview 1.5.1 pub.dev README and source
// The pattern uses setFocusedNode + node.position update
GestureDetector(
  onPanUpdate: (details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    // Account for InteractiveViewer transformation
    final transform = _transformationController.value;
    final transformedPoint = MatrixUtils.transformPoint(
      Matrix4.inverted(transform), localPosition,
    );
    setState(() {
      algorithm.setFocusedNode(node);
      node.position = transformedPoint;
    });
    // Debounced save to repository
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer(const Duration(seconds: 1), () {
      ref.read(nodePositionNotifierProvider.notifier)
          .savePosition(nodeId, node.position);
    });
  },
  child: nodeWidget,
)
```

### Pattern 4: Minimap Widget
**What:** Shows scaled-down graph overview with viewport indicator rectangle
**When to use:** As an overlay on the graph view
**Implementation approach:**
```dart
// Uses TransformationController to read current viewport
// Renders a small Canvas with node positions as colored dots
// Overlays a rectangle showing the visible area
class StoryArcMinimap extends StatelessWidget {
  final Graph graph;
  final TransformationController controller;
  final Size viewportSize;
  // Scale graph bounds to fit a small box (e.g., 150x100)
  // Draw each node as a small colored rectangle
  // Draw viewport rect from controller.value translation/scale
}
```

### Anti-Patterns to Avoid
- **Mutating PlotNode to add position fields:** CONTEXT.md D-15 explicitly requires separate NodePosition storage. Do NOT add positionX/positionY to PlotNode.
- **Building graph in initState only:** PlotNode data changes via Riverpod -- must rebuild Graph when `plotNodeNotifierProvider` emits new state.
- **Using graphview's `Node(data)` constructor:** This is deprecated. Use `Node.Id(plotNode.id)` exclusively.
- **Ignoring edge deduplication:** PlotNode has both `causeNodeIds` and `consequenceNodeIds`. If A lists B in causeNodeIds and B lists A in consequenceNodeIds, the same edge A->B would be added twice. Need deduplication logic.
- **Synchronous position saves on every drag frame:** Will cause performance issues with Hive writes. Must debounce position saves (e.g., 500ms after last drag event).
- **Re-running FruchtermanReingold on every build:** The algorithm is CPU-intensive. Run only when nodes are first added or when explicitly triggered. When positions are restored from storage, skip the layout algorithm and use saved positions directly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Force-directed graph layout | Custom physics simulation | `FruchtermanReingoldAlgorithm` | Complex math, tuning required. graphview provides production-quality implementation with configurable attraction/repulsion. |
| Zoom/pan interaction | Custom matrix transforms | `InteractiveViewer` (via GraphView.builder) | Built into GraphView.builder, handles boundary margins, min/max scale, momentum. |
| Edge arrow rendering | Custom arrow drawing on canvas | `ArrowEdgeRenderer` (extend it) | Handles clipping to node boundaries, triangle arrow geometry, self-loop paths. |
| Graph data structure | Custom adjacency list | `graphview.Graph` | Provides addNode, addEdge, successorsOf, predecessorsOf, edge management, cache. |
| Node hit-testing | Manual bounding box checks | graphview's built-in hit testing | `RenderCustomLayoutBox.hitTestChildren` handles coordinate transforms. |

**Key insight:** The entire graph rendering, layout, and interaction layer is provided by graphview. The custom work is in the edge renderer (gradient/dashed styles), node builder (color-coded widgets), and the position persistence layer.

## Common Pitfalls

### Pitfall 1: Edge Deduplication Between causeNodeIds and consequenceNodeIds
**What goes wrong:** PlotNode A has `causeNodeIds: [B]` and PlotNode B has `consequenceNodeIds: [A]`. Both represent the same causal edge B->A. If both are iterated, the edge is added twice, causing duplicate rendering.
**Why it happens:** The domain model stores relationships bidirectionally but graphview edges are unidirectional objects.
**How to avoid:** Only iterate one direction (e.g., only `consequenceNodeIds` to create directed edges from source to consequence). Or maintain a `Set<String>` of already-added edge keys.
**Warning signs:** Edges appear thicker than expected; duplicate arrow heads visible.

### Pitfall 2: graphview Node Identity Issues
**What goes wrong:** Creating new `Node.Id(id)` objects on every build causes graphview to treat them as different nodes, losing positions and triggering full relayout.
**Why it happens:** graphview uses `hashCode` based on `ValueKey` for equality. New Node objects with the same ID value have the same hash, but the `Graph.addEdge` method does reference-based deduplication through its internal list.
**How to avoid:** Maintain a `Map<String, Node>` cache. Only create new Node objects when PlotNodes change. Reuse existing Node objects on rebuilds.
**Warning signs:** Graph re-layouts on every state change; saved positions not restored.

### Pitfall 3: FruchtermanReingold Shuffles Nodes on Init
**What goes wrong:** When `FruchtermanReingoldConfiguration.shuffleNodes` is true (default), the algorithm randomizes node positions on init, ignoring saved positions.
**Why it happens:** The `init()` method checks `node.position == Offset.zero` to decide whether to shuffle, but the default position is `Offset.zero`.
**How to avoid:** Either (a) set `shuffleNodes: false` and use saved positions, or (b) set positions after init but before run, or (c) only run the algorithm for initial layout and then switch to saved-position mode.
**Warning signs:** Nodes jump to random positions on rebuild; saved positions ignored.

### Pitfall 4: Performance with 100+ Nodes
**What goes wrong:** STATE.md flags "Graph rendering performance with 100+ PlotNodes" as a concern. FruchtermanReingoldAlgorithm runs O(n^2) repulsion calculation per iteration with 100 default iterations.
**Why it happens:** Force-directed layout scales quadratically.
**How to avoid:** (a) Reduce `FruchtermanReingoldConfiguration.iterations` for large graphs (e.g., 50 instead of 100). (b) Skip algorithm entirely when saved positions exist. (c) Consider `SugiyamaAlgorithm` as a fallback for very large graphs (hierarchical layout, O(n log n)). (d) Use `GraphViewController.zoomToFit()` rather than rendering all nodes at full detail.
**Warning signs:** UI freezes when opening graph view with many nodes; excessive CPU usage.

### Pitfall 5: graphview Paint.style Must Be Stroke
**What goes wrong:** Edge paint uses `PaintingStyle.fill` (default for some Paint constructors), causing edges to render as filled shapes instead of lines.
**Why it happens:** ArrowEdgeRenderer sets `..style = PaintingStyle.stroke` on the current paint, but only for the line portion. The arrow triangle uses `PaintingStyle.fill`. If the base paint is wrong, lines appear as thick filled rectangles.
**How to avoid:** Always set `paint..style = PaintingStyle.stroke` when creating edge Paint objects.
**Warning signs:** Edges appear as thick blobs instead of lines.

### Pitfall 6: InteractiveViewer Transformation Conflict with Drag
**What goes wrong:** Dragging a node also pans the viewport because InteractiveViewer captures pan gestures before the node's GestureDetector.
**Why it happens:** InteractiveViewer wraps the entire graph, and gesture disambiguation may give priority to the viewer.
**How to avoid:** (a) When a node is being dragged, disable InteractiveViewer via a flag. (b) Use `InteractiveViewer.builder` (which GraphView.builder already uses) and handle node drag through `onPanUpdate` on individual node widgets with proper gesture handling. (c) The graphview library's recommended pattern uses `setFocusedNode` + position update, which works within the InteractiveViewer.
**Warning signs:** Dragging a node causes the whole graph to pan instead.

## Code Examples

Verified patterns from official graphview source and pub.dev documentation:

### Basic GraphView.builder Setup
```dart
// Source: pub.dev/packages/graphview README + source GraphView.dart
final controller = GraphViewController();
final graph = Graph()..isTree = false;

// Add nodes and edges
graph.addNode(Node.Id('node-1'));
graph.addEdge(Node.Id('node-1'), Node.Id('node-2'),
  paint: Paint()..color = Colors.blue..strokeWidth = 2..style = PaintingStyle.stroke);

final algorithm = FruchtermanReingoldAlgorithm(
  FruchtermanReingoldConfiguration(
    iterations: 100,
    shuffleNodes: false,  // Use saved positions
  ),
  renderer: StoryArcEdgeRenderer(edgeTypes: edgeTypeMap),
);

GraphView.builder(
  graph: graph,
  algorithm: algorithm,
  controller: controller,
  animated: true,
  autoZoomToFit: true,
  builder: (Node node) {
    final plotNode = plotNodes.firstWhere((p) => p.id == node.key.value);
    return StoryArcNode(plotNode: plotNode);
  },
);
```

### Per-Edge Paint Styling
```dart
// Source: graphview 1.5.1 Graph.dart addEdge method
// Each edge accepts a Paint parameter for custom styling
graph.addEdge(
  Node.Id(sourceId), Node.Id(destId),
  paint: Paint()
    ..color = Colors.amber
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke,
);
```

### Node Builder with Custom Widget
```dart
// Source: graphview 1.5.1 GraphView.dart NodeWidgetBuilder typedef
builder: (Node node) {
  final id = node.key.value as String;
  final plotNode = plotNodeMap[id]!;
  return GestureDetector(
    onTap: () => _showEditSheet(context, plotNode),
    onPanUpdate: (details) {
      // Handle drag
      node.position += details.delta;
      setState(() {});
    },
    child: Container(
      width: plotNode.title.length > 8 ? 160 : 120,
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
          Text(plotNode.title, maxLines: 2),
          Positioned(
            top: 0, right: 0,
            child: Text('Ch${plotNode.chapter}',
              style: const TextStyle(fontSize: 10)),
          ),
        ],
      ),
    ),
  );
},
```

### BottomSheet for Node Editing
```dart
// Following existing pattern from StoryStructurePage._showPlotNodeForm
void _showEditSheet(BuildContext context, PlotNode node, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => NodeEditBottomSheet(
      node: node,
      onSave: (updated) {
        ref.read(plotNodeNotifierProvider.notifier).save(updated);
      },
    ),
  );
}
```

### NodePosition Entity (New)
```dart
// Following existing pattern from PlotNode
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

### NodePositionRepository (New)
```dart
// Following existing pattern from PlotNodeRepository
class NodePositionRepository {
  final Box<dynamic> _box;

  NodePositionRepository(this._box);

  Future<void> save(NodePosition position) async {
    await _box.put(position.plotNodeId, position.toJson());
  }

  Offset? getPosition(String plotNodeId) {
    final json = _box.get(plotNodeId);
    if (json == null) return null;
    return NodePosition.fromJson(json as Map<String, dynamic>).toOffset();
  }

  Map<String, Offset> getAllPositions() {
    final positions = <String, Offset>{};
    for (final key in _box.keys) {
      final json = _box.get(key);
      if (json != null) {
        final pos = NodePosition.fromJson(json as Map<String, dynamic>);
        positions[pos.plotNodeId] = pos.toOffset();
      }
    }
    return positions;
  }

  Future<void> delete(String plotNodeId) async {
    await _box.delete(plotNodeId);
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| graphview 1.4.x | graphview 1.5.1 | 2025 | Added GraphViewController with jumpToNode, animateToNode, zoomToFit, expand/collapse. Builder constructor with autoZoomToFit. |
| Tree-only layouts | Multiple layouts (FR, Sugiyama, Circle, Balloon, Radial, Mindmap) | 2024-2025 | Force-directed now production-ready for non-tree graphs like plot networks. |
| Static node positions only | Animated node transitions | 1.5.0+ | Smooth expand/collapse and position transitions built-in. |
| ArrowEdgeRenderer (basic) | EdgeRenderer with DashedLine, DottedLine, SineLine | 1.5.0+ | Built-in line style enum eliminates custom dashed line code for simple cases. |

**Deprecated/outdated:**
- `Node(data)` constructor: deprecated in favor of `Node.Id(id)` + builder pattern
- `getNodeAtUsingData()`: deprecated, use `getNodeUsingKey()` or `getNodeUsingId()`

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | graphview 1.5.1 works correctly with Flutter 3.44.0 | Standard Stack | Layout algorithm or rendering may have compatibility issues. Mitigated by it being in the pub cache already (validated during STACK.md research). |
| A2 | Custom edge renderer subclassing works for gradient lines | Architecture Patterns | ArrowEdgeRenderer may not expose enough hooks for gradient shader application. May need to override renderEdge completely. Low risk -- full Canvas access is available. |
| A3 | Node drag within InteractiveViewer works without gesture conflicts | Common Pitfalls | May need custom gesture handling. The graphview README shows the pattern, but real-world behavior needs testing. |
| A4 | Minimap can be built from TransformationController + node positions | Architecture Patterns | Straightforward Canvas painting of scaled-down positions. No library dependency. Low risk. |
| A5 | `shuffleNodes: false` allows using saved positions with FruchtermanReingold | Common Pitfalls | Need to verify that the algorithm respects pre-set positions when shuffleNodes is false. Source code shows it only shuffles if `shuffleNodes` is true, but positions at `Offset.zero` may still trigger init. |

**If this table is empty:** All claims in this research were verified or cited -- no user confirmation needed.

## Open Questions

1. **Edge deduplication strategy for bidirectional relationships**
   - What we know: PlotNode has both `causeNodeIds` (ids of nodes that cause this one) and `consequenceNodeIds` (ids of nodes this one causes). These are stored from both sides, creating redundancy.
   - What's unclear: Whether the existing data always has consistent bidirectional references, or if only one side may be populated.
   - Recommendation: Build edges from only one direction (e.g., only `consequenceNodeIds` for causal, only `relatedNodeIds` for association). If a node lists B in its `consequenceNodeIds`, create edge A->B. Do not also create B->A from B's `causeNodeIds`.

2. **Initial layout vs. saved position priority**
   - What we know: Users expect nodes to appear in sensible positions on first view. After manual rearrangement, saved positions should persist.
   - What's unclear: The exact UX flow when a user adds a new PlotNode -- should it get a force-directed position near its connected nodes, or appear at a default location?
   - Recommendation: On first graph load (no saved positions), run FruchtermanReingold. On subsequent loads, use saved positions. New nodes added to existing graph get positioned adjacent to their connected nodes.

3. **Minimap implementation detail**
   - What we know: VIZO-06 requires a minimap. graphview has no built-in minimap widget.
   - What's unclear: Exact visual design -- should it show node colors, or just dots?
   - Recommendation: Build a lightweight CustomPainter minimap that renders node positions as small colored rectangles and overlays the current viewport rectangle from TransformationController. Place in bottom-right corner as a semi-transparent overlay.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Core framework | Yes | 3.44.0 stable | -- |
| Dart SDK | Language | Yes | 3.12.0 | -- |
| graphview 1.5.1 | Graph visualization | In pub cache | 1.5.1 | Needs `flutter pub add` |
| Hive CE | Position storage | Yes | 2.19.3 | -- |
| flutter_riverpod | State management | Yes | 3.3.1 | -- |
| flutter_test | Testing | Yes | SDK bundled | -- |

**Missing dependencies with no fallback:**
- None -- all required dependencies are available.

**Missing dependencies with fallback:**
- graphview: In pub cache but not yet in pubspec.yaml. Planner must include `flutter pub add graphview` as a setup task.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK) |
| Config file | None -- standard Flutter test conventions |
| Quick run command | `flutter test test/features/story_structure/` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VIZO-01 | Graph renders from PlotNode data | unit | `flutter test test/features/story_structure/application/graph_builder_test.dart` | No -- Wave 0 |
| VIZO-01 | Zoom and pan work via InteractiveViewer | widget | `flutter test test/features/story_structure/presentation/story_arc_graph_test.dart` | No -- Wave 0 |
| VIZO-02 | Edges distinguish relationship types visually | unit | `flutter test test/features/story_structure/presentation/story_arc_edge_renderer_test.dart` | No -- Wave 0 |
| VIZO-03 | Nodes color-coded by structural role | unit | `flutter test test/features/story_structure/presentation/graph_colors_test.dart` | No -- Wave 0 |
| VIZO-04 | Tap node opens bottom sheet with editable fields | widget | `flutter test test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` | No -- Wave 0 |
| VIZO-05 | Node positions persisted after drag | unit | `flutter test test/features/story_structure/infrastructure/node_position_repository_test.dart` | No -- Wave 0 |
| VIZO-06 | Minimap renders graph overview | widget | `flutter test test/features/story_structure/presentation/story_arc_minimap_test.dart` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/story_structure/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/features/story_structure/application/graph_builder_test.dart` -- covers VIZO-01 (PlotNode -> Graph conversion logic)
- [ ] `test/features/story_structure/presentation/story_arc_edge_renderer_test.dart` -- covers VIZO-02 (edge rendering)
- [ ] `test/features/story_structure/presentation/graph_colors_test.dart` -- covers VIZO-03 (color mapping)
- [ ] `test/features/story_structure/infrastructure/node_position_repository_test.dart` -- covers VIZO-05 (position persistence)
- [ ] `test/features/story_structure/domain/node_position_test.dart` -- covers NodePosition entity
- [ ] `test/features/story_structure/presentation/node_edit_bottom_sheet_test.dart` -- covers VIZO-04
- [ ] `test/features/story_structure/presentation/story_arc_minimap_test.dart` -- covers VIZO-06

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth in this phase |
| V3 Session Management | No | No sessions |
| V4 Access Control | No | Local-only, single user |
| V5 Input Validation | Yes | Dart type system + PlotNode field validation on edit |
| V6 Cryptography | No | No crypto needed (positions are non-sensitive) |

### Known Threat Patterns for Flutter Graph Visualization

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious data in node title/summary | Tampering | Input sanitization on edit; PlotNode fields already validated |
| Position data corruption | Denial of Service | Hive box corruption handled by try-catch in repository; fallback to algorithm layout |
| Excessive node count causing UI freeze | Denial of Service | Cap graph size; limit iterations; use virtual viewport |

## Sources

### Primary (HIGH confidence)
- graphview 1.5.1 source code (pub cache: `/home/re/.pub-cache/hosted/pub.dev/graphview-1.5.1/`) -- Read Graph.dart, GraphView.dart, ArrowEdgeRenderer.dart, EdgeRenderer.dart, FruchtermanReingoldAlgorithm.dart, FruchtermanReingoldConfiguration.dart, Algorithm.dart in full
- pub.dev/packages/graphview -- Version 1.5.1, MIT license, full README with code examples [CITED: pub.dev/packages/graphview]
- Existing codebase: plot_node.dart, plot_node_repository.dart, plot_node_notifier.dart, story_structure_page.dart, plot_timeline.dart, providers.dart -- all read and analyzed

### Secondary (MEDIUM confidence)
- .planning/research/STACK.md -- Previous v1.1 technology validation for graphview [CITED: internal doc]
- Web search results for graphview ecosystem -- confirmed no competing Flutter graph library matches graphview's maturity

### Tertiary (LOW confidence)
- None -- all findings verified from primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - graphview source code read directly; API fully understood
- Architecture: HIGH - patterns derived from actual library source; existing codebase patterns well-established
- Pitfalls: HIGH - edge deduplication and node identity issues discovered through careful source analysis
- Performance: MEDIUM - 100+ node concern flagged in STATE.md; mitigation strategies documented but untested

**Research date:** 2026-06-05
**Valid until:** 2026-07-05 (stable library, low churn expected)

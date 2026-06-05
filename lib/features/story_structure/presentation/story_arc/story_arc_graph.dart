import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/presentation/story_arc/node_edit_bottom_sheet.dart';
import 'package:museflow/features/story_structure/presentation/story_arc/story_arc_edge_renderer.dart';
import 'package:museflow/features/story_structure/presentation/story_arc/story_arc_minimap.dart';
import 'package:museflow/features/story_structure/presentation/story_arc/story_arc_node.dart';

/// Interactive story arc graph built from [PlotNode] relationships.
class StoryArcGraph extends ConsumerStatefulWidget {
  const StoryArcGraph({super.key});

  @override
  ConsumerState<StoryArcGraph> createState() => _StoryArcGraphState();
}

class _StoryArcGraphState extends ConsumerState<StoryArcGraph> {
  final TransformationController _transformationController =
      TransformationController();
  late final GraphViewController _controller;
  Timer? _positionSaveTimer;
  bool _isDraggingNode = false;
  final Map<String, Offset> _dragPositions = {};

  @override
  void initState() {
    super.initState();
    _controller = GraphViewController(
      transformationController: _transformationController,
    );
  }

  @override
  void dispose() {
    _positionSaveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(plotNodeNotifierProvider);
    final positionsAsync = ref.watch(nodePositionNotifierProvider);

    return nodesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        error: error,
        onRetry: () => ref.invalidate(plotNodeNotifierProvider),
      ),
      data: (nodes) {
        if (nodes.isEmpty) {
          return _EmptyGraphState(onCreate: () => _showEditSheet(null));
        }

        final positions =
            positionsAsync.asData?.value ?? const <String, Offset>{};
        return _buildGraph(nodes, positions);
      },
    );
  }

  Widget _buildGraph(List<PlotNode> nodes, Map<String, Offset> positions) {
    final graph = Graph()..isTree = false;
    final graphNodes = <String, Node>{};
    final edgeTypes = <Edge, EdgeType>{};
    final addedEdges = <String>{};

    for (final plotNode in nodes) {
      final node = Node.Id(plotNode.id);
      final savedPosition =
          _dragPositions[plotNode.id] ?? positions[plotNode.id];
      if (savedPosition != null) node.position = savedPosition;
      graphNodes[plotNode.id] = node;
      graph.addNode(node);
    }

    for (final source in nodes) {
      final sourceNode = graphNodes[source.id];
      if (sourceNode == null) continue;

      for (final targetId in source.consequenceNodeIds) {
        _addTypedEdge(
          graph: graph,
          graphNodes: graphNodes,
          addedEdges: addedEdges,
          edgeTypes: edgeTypes,
          sourceNode: sourceNode,
          sourceId: source.id,
          targetId: targetId,
          type: EdgeType.causal,
          paint: _edgePaint(Colors.blue.shade700, 2),
        );
      }

      for (final targetId in source.relatedNodeIds) {
        final ordered = [source.id, targetId]..sort();
        _addTypedEdge(
          graph: graph,
          graphNodes: graphNodes,
          addedEdges: addedEdges,
          edgeTypes: edgeTypes,
          sourceNode: sourceNode,
          sourceId: ordered.first,
          targetId: ordered.last,
          type: EdgeType.association,
          paint: _edgePaint(
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade600
                : Colors.grey.shade400,
            1,
          ),
        );
      }

      for (final targetId in source.linkedForeshadowingIds) {
        _addTypedEdge(
          graph: graph,
          graphNodes: graphNodes,
          addedEdges: addedEdges,
          edgeTypes: edgeTypes,
          sourceNode: sourceNode,
          sourceId: source.id,
          targetId: targetId,
          type: EdgeType.foreshadowing,
          paint: _edgePaint(Colors.amber.shade500, 1.5),
        );
      }
    }

    final nodeById = {for (final node in nodes) node.id: node};
    final algorithm = FruchtermanReingoldAlgorithm(
      FruchtermanReingoldConfiguration(iterations: 50, shuffleNodes: false),
      renderer: StoryArcEdgeRenderer(
        edgeTypes: edgeTypes,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: _isDraggingNode,
          child: GraphView.builder(
            graph: graph,
            algorithm: algorithm,
            controller: _controller,
            animated: true,
            autoZoomToFit: true,
            builder: (node) {
              final id = node.key?.value as String;
              final plotNode = nodeById[id]!;
              return StoryArcNode(
                plotNode: plotNode,
                onTap: () => _showEditSheet(plotNode),
                onPanStart: (_) => setState(() => _isDraggingNode = true),
                onPanUpdate: (details) => _updateNodePosition(
                  nodeId: id,
                  node: node,
                  delta: details.delta,
                ),
                onPanEnd: (_) {
                  setState(() => _isDraggingNode = false);
                  _debouncedSavePosition(id, node.position);
                },
              );
            },
          ),
        ),
        StoryArcMinimap(
          plotNodes: nodes,
          nodePositions: {
            for (final entry in graphNodes.entries)
              entry.key: entry.value.position,
          },
          transformationController: _transformationController,
          graphCanvasSize: MediaQuery.sizeOf(context),
        ),
      ],
    );
  }

  Paint _edgePaint(Color color, double width) {
    return Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
  }

  void _addTypedEdge({
    required Graph graph,
    required Map<String, Node> graphNodes,
    required Set<String> addedEdges,
    required Map<Edge, EdgeType> edgeTypes,
    required Node sourceNode,
    required String sourceId,
    required String targetId,
    required EdgeType type,
    required Paint paint,
  }) {
    final source = graphNodes[sourceId] ?? sourceNode;
    final target = graphNodes[targetId];
    if (target == null) return;

    final key = '$sourceId->$targetId';
    if (!addedEdges.add(key)) return;

    final edge = graph.addEdge(source, target, paint: paint);
    edgeTypes[edge] = type;
  }

  void _updateNodePosition({
    required String nodeId,
    required Node node,
    required Offset delta,
  }) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final adjustedDelta = scale == 0 ? delta : delta / scale;
    setState(() {
      node.position = node.position + adjustedDelta;
      _dragPositions[nodeId] = node.position;
    });
    _controller.focusedNode = node;
    _controller.forceRecalculation();
  }

  void _debouncedSavePosition(String nodeId, Offset position) {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer(const Duration(seconds: 1), () {
      ref
          .read(nodePositionNotifierProvider.notifier)
          .savePosition(nodeId, position);
    });
  }

  void _showEditSheet(PlotNode? node) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => NodeEditBottomSheet(node: node),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('加载剧情节点失败，请重试: $error'),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _EmptyGraphState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyGraphState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: '暂无剧情节点',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 48,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                '暂无剧情节点',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  '创建情节点来可视化你的故事弧线结构',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: onCreate, child: const Text('创建第一个节点')),
            ],
          ),
        ),
      ),
    );
  }
}

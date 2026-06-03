import 'package:hive_ce/hive.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing [PlotNode] entities in a Hive box.
///
/// Provides CRUD operations with chapter-scoped queries and manual ordering.
/// All operations are wrapped in error handling to prevent silent failures.
class PlotNodeRepository {
  final Box<dynamic> _box;
  final _uuid = const Uuid();

  PlotNodeRepository(this._box);

  /// Adds a new plot node to the box.
  ///
  /// If the node has an empty [id], a new UUID is generated.
  /// Sets [createdAt] to now if not already set.
  /// Returns the node with ID and timestamps assigned.
  Future<PlotNode> add(PlotNode node) async {
    try {
      final id = node.id.isEmpty ? _uuid.v4() : node.id;
      final now = DateTime.now();
      final newNode = PlotNode(
        id: id,
        title: node.title,
        chapter: node.chapter,
        summary: node.summary,
        involvedCharacterIds: node.involvedCharacterIds,
        involvedCharacterNames: node.involvedCharacterNames,
        linkedForeshadowingIds: node.linkedForeshadowingIds,
        writingStatus: node.writingStatus,
        structuralRole: node.structuralRole,
        causeNodeIds: node.causeNodeIds,
        consequenceNodeIds: node.consequenceNodeIds,
        relatedNodeIds: node.relatedNodeIds,
        manualOrder: node.manualOrder,
        createdAt: now,
      );
      await _box.put(id, newNode.toJson());
      return newNode;
    } catch (e) {
      throw StateError('Failed to save plot node: $e');
    }
  }

  /// Returns all plot nodes sorted by chapter, then manualOrder.
  List<PlotNode> getAll() {
    try {
      final nodes = _box.values
          .map((json) => PlotNode.fromJson(json as Map<String, dynamic>))
          .toList();
      nodes.sort((a, b) {
        final chapterCompare = a.chapter.compareTo(b.chapter);
        if (chapterCompare != 0) return chapterCompare;
        return a.manualOrder.compareTo(b.manualOrder);
      });
      return nodes;
    } catch (e) {
      throw StateError('Failed to read plot nodes: $e');
    }
  }

  /// Returns a plot node by its ID, or null if not found.
  PlotNode? getById(String id) {
    try {
      final json = _box.get(id);
      if (json == null) return null;
      return PlotNode.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      throw StateError('Failed to read plot node $id: $e');
    }
  }

  /// Updates an existing plot node.
  ///
  /// Sets [updatedAt] to the current time before persisting.
  Future<void> update(PlotNode node) async {
    try {
      final updated = node.copyWith(updatedAt: DateTime.now());
      await _box.put(node.id, updated.toJson());
    } catch (e) {
      throw StateError('Failed to update plot node ${node.id}: $e');
    }
  }

  /// Deletes a plot node by its ID.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StateError('Failed to delete plot node $id: $e');
    }
  }

  /// Returns plot nodes for a specific chapter, sorted by manualOrder.
  List<PlotNode> getByChapter(int chapter) {
    return getAll().where((node) => node.chapter == chapter).toList();
  }

  /// Saves the display order for a list of node IDs.
  ///
  /// Updates each node's [manualOrder] based on its position in the list.
  Future<void> saveOrder(List<String> orderedIds) async {
    try {
      for (var i = 0; i < orderedIds.length; i++) {
        final node = getById(orderedIds[i]);
        if (node != null) {
          await _box.put(
            node.id,
            node.copyWith(manualOrder: i, updatedAt: DateTime.now()).toJson(),
          );
        }
      }
    } catch (e) {
      throw StateError('Failed to save plot node order: $e');
    }
  }
}

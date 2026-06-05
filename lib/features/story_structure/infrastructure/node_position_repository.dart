import 'dart:ui';

import 'package:hive_ce/hive.dart';
import 'package:museflow/features/story_structure/domain/node_position.dart';

/// Repository for managing saved graph positions in a Hive box.
///
/// Positions are keyed by PlotNode.id and stored separately from PlotNode so
/// narrative data remains independent from visualization layout concerns.
class NodePositionRepository {
  final Box<dynamic> _box;

  NodePositionRepository(this._box);

  /// Saves or replaces a node position by [NodePosition.plotNodeId].
  Future<void> save(NodePosition position) async {
    try {
      await _box.put(position.plotNodeId, position.toJson());
    } catch (e) {
      throw StateError('Failed to save node position: $e');
    }
  }

  /// Returns the saved position for a plot node, or null if none exists.
  Offset? getPosition(String plotNodeId) {
    try {
      final json = _box.get(plotNodeId);
      if (json == null) return null;
      return NodePosition.fromJson(json as Map<String, dynamic>).toOffset();
    } catch (e) {
      throw StateError('Failed to read node position $plotNodeId: $e');
    }
  }

  /// Returns all saved positions keyed by plot node ID.
  Map<String, Offset> getAllPositions() {
    try {
      final positions = <String, Offset>{};
      for (final key in _box.keys) {
        final json = _box.get(key);
        if (json == null) continue;
        final position = NodePosition.fromJson(json as Map<String, dynamic>);
        positions[position.plotNodeId] = position.toOffset();
      }
      return positions;
    } catch (e) {
      throw StateError('Failed to read node positions: $e');
    }
  }

  /// Deletes the saved position for a plot node.
  Future<void> delete(String plotNodeId) async {
    try {
      await _box.delete(plotNodeId);
    } catch (e) {
      throw StateError('Failed to delete node position $plotNodeId: $e');
    }
  }
}

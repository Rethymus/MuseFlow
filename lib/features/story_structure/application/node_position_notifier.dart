import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/node_position.dart';

/// AsyncNotifier managing saved plot node graph positions.
class NodePositionNotifier extends AsyncNotifier<Map<String, Offset>> {
  @override
  Future<Map<String, Offset>> build() async {
    final repository = await ref.watch(nodePositionRepositoryProvider.future);
    return repository.getAllPositions();
  }

  /// Saves a graph position and refreshes the state.
  Future<void> savePosition(String nodeId, Offset position) async {
    final repository = await ref.read(nodePositionRepositoryProvider.future);
    await repository.save(
      NodePosition(plotNodeId: nodeId, x: position.dx, y: position.dy),
    );
    ref.invalidateSelf();
  }

  /// Deletes a graph position and refreshes the state.
  Future<void> deletePosition(String nodeId) async {
    final repository = await ref.read(nodePositionRepositoryProvider.future);
    await repository.delete(nodeId);
    ref.invalidateSelf();
  }
}

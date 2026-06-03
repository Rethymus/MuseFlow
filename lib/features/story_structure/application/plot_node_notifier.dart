import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';

/// AsyncNotifier managing the list of [PlotNode] entities.
///
/// Loads nodes from [PlotNodeRepository] on build, exposes
/// [AsyncValue] for the presentation layer. CRUD methods delegate
/// to the repository and refresh state via [ref.invalidateSelf].
class PlotNodeNotifier extends AsyncNotifier<List<PlotNode>> {
  @override
  Future<List<PlotNode>> build() async {
    final repository = await ref.watch(plotNodeRepositoryProvider.future);
    return repository.getAll();
  }

  /// Adds a new plot node and refreshes the state.
  Future<void> add(PlotNode node) async {
    final repository = await ref.read(plotNodeRepositoryProvider.future);
    await repository.add(node);
    ref.invalidateSelf();
  }

  /// Updates an existing plot node and refreshes the state.
  Future<void> save(PlotNode node) async {
    final repository = await ref.read(plotNodeRepositoryProvider.future);
    await repository.update(node);
    ref.invalidateSelf();
  }

  /// Deletes a plot node by ID and refreshes the state.
  Future<void> delete(String id) async {
    final repository = await ref.read(plotNodeRepositoryProvider.future);
    await repository.delete(id);
    ref.invalidateSelf();
  }
}

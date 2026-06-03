import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/infrastructure/hive_adapters.dart';
import 'package:museflow/features/story_structure/application/plot_node_notifier.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    await Hive.initTest();
    Hive.registerAdapter(PlotNodeAdapter());

    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await Hive.deleteBoxFromDisk('plot_nodes');
  });

  group('PlotNodeNotifier', () {
    test('should start with empty list', () async {
      // Allow async providers to resolve
      await container.read(plotNodeNotifierProvider.future);

      final state = container.read(plotNodeNotifierProvider);
      expect(state.asData?.value ?? [], isEmpty);
    });

    test('should add a plot node and refresh state', () async {
      final notifier = container.read(plotNodeNotifierProvider.notifier);

      final node = PlotNode(
        id: '',
        title: 'Test node',
        chapter: 1,
        summary: 'Test summary',
        writingStatus: PlotNodeWritingStatus.notStarted,
        structuralRole: PlotNodeStructuralRole.setup,
        manualOrder: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      await notifier.add(node);

      final state = await container.read(plotNodeNotifierProvider.future);
      expect(state, hasLength(1));
      expect(state.first.title, 'Test node');
    });

    test('should save/update a plot node', () async {
      final notifier = container.read(plotNodeNotifierProvider.notifier);

      final node = PlotNode(
        id: '',
        title: 'Original',
        chapter: 1,
        writingStatus: PlotNodeWritingStatus.drafting,
        structuralRole: PlotNodeStructuralRole.setup,
        manualOrder: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      await notifier.add(node);

      var state = await container.read(plotNodeNotifierProvider.future);
      final added = state.first;

      await notifier.save(added.copyWith(title: 'Updated'));
      state = await container.read(plotNodeNotifierProvider.future);
      expect(state.first.title, 'Updated');
    });

    test('should delete a plot node', () async {
      final notifier = container.read(plotNodeNotifierProvider.notifier);

      final node = PlotNode(
        id: 'pn-del',
        title: 'To delete',
        chapter: 1,
        writingStatus: PlotNodeWritingStatus.notStarted,
        structuralRole: PlotNodeStructuralRole.setup,
        manualOrder: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      await notifier.add(node);
      var state = await container.read(plotNodeNotifierProvider.future);
      expect(state, hasLength(1));

      await notifier.delete('pn-del');
      state = await container.read(plotNodeNotifierProvider.future);
      expect(state, isEmpty);
    });
  });
}

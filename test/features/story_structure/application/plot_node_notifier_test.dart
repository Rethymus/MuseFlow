import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/infrastructure/plot_node_repository.dart';

import '../../../../helpers/hive_test_helper.dart';

void main() {
  late ProviderContainer container;
  late Box<dynamic> box;

  setUp(() async {
    await setUpHiveTest();
    box = await Hive.openBox<dynamic>('test_plot_node_notifier');

    container = ProviderContainer(
      overrides: [
        plotNodeRepositoryProvider
            .overrideWith((ref) async => PlotNodeRepository(box)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await tearDownHiveTest();
  });

  PlotNode _makeNode({
    required String id,
    String title = 'Test node',
    int chapter = 1,
    PlotNodeWritingStatus status = PlotNodeWritingStatus.notStarted,
    PlotNodeStructuralRole role = PlotNodeStructuralRole.setup,
    int manualOrder = 0,
  }) {
    return PlotNode(
      id: id,
      title: title,
      chapter: chapter,
      writingStatus: status,
      structuralRole: role,
      manualOrder: manualOrder,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('PlotNodeNotifier', () {
    test('build should load nodes from repository', () async {
      // Pre-populate
      final repo = PlotNodeRepository(box);
      await repo.add(_makeNode(id: 'pn-1'));
      await repo.add(_makeNode(id: 'pn-2'));

      final notifier = container.read(plotNodeNotifierProvider.notifier);
      final nodes = await notifier.future;

      expect(nodes, hasLength(2));
    });

    test('add should persist and refresh state', () async {
      final notifier = container.read(plotNodeNotifierProvider.notifier);

      await notifier.add(_makeNode(id: ''));
      final nodes = await notifier.future;

      expect(nodes, hasLength(1));
      expect(nodes.first.id, isNotEmpty);
    });

    test('save should update existing node and refresh state', () async {
      final notifier = container.read(plotNodeNotifierProvider.notifier);

      await notifier.add(_makeNode(id: 'pn-1', title: 'Original'));
      final original = (await notifier.future).first;

      await notifier.save(original.copyWith(title: 'Updated'));
      final updated = (await notifier.future).first;

      expect(updated.title, 'Updated');
    });

    test('delete should remove node and refresh state', () async {
      final notifier = container.read(plotNodeNotifierProvider.notifier);

      await notifier.add(_makeNode(id: 'pn-1'));
      var nodes = await notifier.future;
      expect(nodes, hasLength(1));

      await notifier.delete('pn-1');
      nodes = await notifier.future;
      expect(nodes, isEmpty);
    });
  });
}

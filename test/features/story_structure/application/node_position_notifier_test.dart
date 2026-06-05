import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/node_position.dart';
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
        nodePositionRepositoryProvider.overrideWith(
          (ref) async => NodePositionRepository(box),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await tearDownHiveTest();
  });

  group('NodePositionNotifier', () {
    test('build should load positions from repository', () async {
      final repository = NodePositionRepository(box);
      await repository.save(
        const NodePosition(plotNodeId: 'pn-1', x: 100, y: 200),
      );
      await repository.save(
        const NodePosition(plotNodeId: 'pn-2', x: 300, y: 400),
      );

      final notifier = container.read(nodePositionNotifierProvider.notifier);
      final positions = await notifier.future;

      expect(positions, hasLength(2));
      expect(positions['pn-1'], const Offset(100, 200));
    });

    test('savePosition should persist and refresh state', () async {
      final notifier = container.read(nodePositionNotifierProvider.notifier);

      await notifier.savePosition('pn-1', const Offset(100, 200));
      final positions = await notifier.future;

      expect(positions, hasLength(1));
      expect(positions['pn-1'], const Offset(100, 200));
    });

    test('deletePosition should remove and refresh state', () async {
      final notifier = container.read(nodePositionNotifierProvider.notifier);

      await notifier.savePosition('pn-1', const Offset(100, 200));
      var positions = await notifier.future;
      expect(positions, hasLength(1));

      await notifier.deletePosition('pn-1');
      positions = await notifier.future;
      expect(positions, isEmpty);
    });
  });
}

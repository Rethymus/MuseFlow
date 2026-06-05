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
    const testPosition = NodePosition(plotNodeId: 'pn-1', x: 100, y: 200);

    test('should save and retrieve a position', () async {
      await repository.save(testPosition);

      final retrieved = repository.getPosition('pn-1');
      expect(retrieved, const Offset(100, 200));
    });

    test('should return null for non-existent ID', () {
      final result = repository.getPosition('missing');
      expect(result, isNull);
    });

    test('should return all positions as map', () async {
      await repository.save(testPosition);
      await repository.save(
        const NodePosition(plotNodeId: 'pn-2', x: 300, y: 400),
      );

      final positions = repository.getAllPositions();
      expect(positions, hasLength(2));
      expect(positions['pn-1'], const Offset(100, 200));
      expect(positions['pn-2'], const Offset(300, 400));
    });

    test('should delete a position', () async {
      await repository.save(testPosition);
      await repository.delete('pn-1');

      final retrieved = repository.getPosition('pn-1');
      expect(retrieved, isNull);
    });

    test('should throw StateError on corrupted data', () async {
      await box.put('pn-1', {'plotNodeId': 'pn-1', 'x': 'bad', 'y': 200});

      expect(() => repository.getPosition('pn-1'), throwsA(isA<StateError>()));
    });
  });
}

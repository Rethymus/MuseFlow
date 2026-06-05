import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/domain/node_position.dart';

void main() {
  group('NodePosition', () {
    const testPosition = NodePosition(plotNodeId: 'pn-1', x: 100, y: 200);

    test('should store plot node id and coordinates', () {
      expect(testPosition.plotNodeId, 'pn-1');
      expect(testPosition.x, 100);
      expect(testPosition.y, 200);
    });

    test('should support copyWith for x only', () {
      final updated = testPosition.copyWith(x: 150);

      expect(updated.plotNodeId, 'pn-1');
      expect(updated.x, 150);
      expect(updated.y, 200);
    });

    test('should support copyWith for y only', () {
      final updated = testPosition.copyWith(y: 250);

      expect(updated.plotNodeId, 'pn-1');
      expect(updated.x, 100);
      expect(updated.y, 250);
    });

    test('should roundtrip through JSON', () {
      final json = testPosition.toJson();
      final restored = NodePosition.fromJson(json);

      expect(restored, testPosition);
      expect(json, {'plotNodeId': 'pn-1', 'x': 100.0, 'y': 200.0});
    });

    test('should support equality', () {
      const same = NodePosition(plotNodeId: 'pn-1', x: 100, y: 200);
      const different = NodePosition(plotNodeId: 'pn-2', x: 100, y: 200);

      expect(testPosition, same);
      expect(testPosition, isNot(different));
    });

    test('should convert to Offset', () {
      expect(testPosition.toOffset().dx, 100);
      expect(testPosition.toOffset().dy, 200);
    });
  });
}

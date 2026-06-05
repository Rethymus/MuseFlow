import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/domain/entity_type.dart';
import 'package:museflow/features/knowledge/infrastructure/name_index.dart';

void main() {
  group('NameIndex', () {
    late NameIndex index;

    setUp(() {
      index = NameIndex();
    });

    test('should find CJK entity name matches with position and length', () {
      index.addEntity('char-1', EntityType.character, ['李白', '诗仙']);

      final matches = index.findMatches('少年遇见李白，又听人称他为诗仙。');

      expect(matches.length, equals(2));
      expect(matches[0].entityId, equals('char-1'));
      expect(matches[0].entityName, equals('李白'));
      expect(matches[0].position, equals(4));
      expect(matches[0].length, equals(2));
      expect(matches[1].entityName, equals('诗仙'));
    });

    test('should skip names shorter than two runes', () {
      index.addEntity('char-1', EntityType.character, ['李', '李白']);

      final matches = index.findMatches('李在远处，李白在桥边。');

      expect(matches.length, equals(1));
      expect(matches.first.entityName, equals('李白'));
    });

    test('should remove entity matches', () {
      index.addEntity('char-1', EntityType.character, ['李白']);
      index.removeEntity('char-1');

      expect(index.findMatches('李白举杯邀月'), isEmpty);
      expect(index.allEntityIds, isEmpty);
    });

    test('should return multiple entities with same name', () {
      index.addEntity('char-1', EntityType.character, ['青莲']);
      index.addEntity('setting-1', EntityType.setting, ['青莲']);

      final matches = index.findMatches('青莲山下');

      expect(matches.map((match) => match.entityId), containsAll(['char-1', 'setting-1']));
      expect(index.typeOf('setting-1'), equals(EntityType.setting));
    });

    test('should return empty list for empty text', () {
      index.addEntity('char-1', EntityType.character, ['李白']);

      expect(index.findMatches(''), isEmpty);
    });
  });
}

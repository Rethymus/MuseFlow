import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';

void main() {
  group('PlotNodeWritingStatus', () {
    test('should serialize to JSON string', () {
      expect(PlotNodeWritingStatus.notStarted.toJsonString(), 'notStarted');
      expect(PlotNodeWritingStatus.drafting.toJsonString(), 'drafting');
      expect(PlotNodeWritingStatus.complete.toJsonString(), 'complete');
      expect(
        PlotNodeWritingStatus.needsRevision.toJsonString(),
        'needsRevision',
      );
    });

    test('should deserialize from JSON string', () {
      expect(
        PlotNodeWritingStatus.fromJsonString('notStarted'),
        PlotNodeWritingStatus.notStarted,
      );
      expect(
        PlotNodeWritingStatus.fromJsonString('complete'),
        PlotNodeWritingStatus.complete,
      );
    });

    test('should default to notStarted for unknown value', () {
      expect(
        PlotNodeWritingStatus.fromJsonString('unknown'),
        PlotNodeWritingStatus.notStarted,
      );
    });
  });

  group('PlotNodeStructuralRole', () {
    test('should serialize to JSON string', () {
      expect(PlotNodeStructuralRole.setup.toJsonString(), 'setup');
      expect(PlotNodeStructuralRole.development.toJsonString(), 'development');
      expect(PlotNodeStructuralRole.turn.toJsonString(), 'turn');
      expect(PlotNodeStructuralRole.climax.toJsonString(), 'climax');
      expect(PlotNodeStructuralRole.resolution.toJsonString(), 'resolution');
    });

    test('should deserialize from JSON string', () {
      expect(
        PlotNodeStructuralRole.fromJsonString('climax'),
        PlotNodeStructuralRole.climax,
      );
      expect(
        PlotNodeStructuralRole.fromJsonString('resolution'),
        PlotNodeStructuralRole.resolution,
      );
    });

    test('should default to setup for unknown value', () {
      expect(
        PlotNodeStructuralRole.fromJsonString('bogus'),
        PlotNodeStructuralRole.setup,
      );
    });
  });

  group('PlotNode', () {
    late PlotNode testNode;

    setUp(() {
      testNode = PlotNode(
        id: 'pn-1',
        title: 'The inciting incident',
        chapter: 1,
        summary: 'A mysterious stranger arrives',
        involvedCharacterIds: const ['char-1', 'char-2'],
        involvedCharacterNames: const ['Alice', 'Bob'],
        linkedForeshadowingIds: const ['fs-1'],
        writingStatus: PlotNodeWritingStatus.drafting,
        structuralRole: PlotNodeStructuralRole.setup,
        causeNodeIds: const [],
        consequenceNodeIds: const ['pn-2'],
        relatedNodeIds: const [],
        manualOrder: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
    });

    test('should support copyWith', () {
      final copy = testNode.copyWith(
        title: 'Updated title',
        writingStatus: PlotNodeWritingStatus.complete,
      );

      expect(copy.title, 'Updated title');
      expect(copy.writingStatus, PlotNodeWritingStatus.complete);
      expect(copy.id, testNode.id);
      expect(copy.chapter, testNode.chapter);
    });

    test('should support equality', () {
      final same = PlotNode(
        id: 'pn-1',
        title: 'The inciting incident',
        chapter: 1,
        summary: 'A mysterious stranger arrives',
        involvedCharacterIds: const ['char-1', 'char-2'],
        involvedCharacterNames: const ['Alice', 'Bob'],
        linkedForeshadowingIds: const ['fs-1'],
        writingStatus: PlotNodeWritingStatus.drafting,
        structuralRole: PlotNodeStructuralRole.setup,
        causeNodeIds: const [],
        consequenceNodeIds: const ['pn-2'],
        relatedNodeIds: const [],
        manualOrder: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      expect(testNode, equals(same));
      expect(testNode.hashCode, equals(same.hashCode));
    });

    test('should not equal a node with different id', () {
      final other = testNode.copyWith(id: 'pn-999');
      expect(testNode, isNot(equals(other)));
    });

    test('should roundtrip through JSON', () {
      final json = testNode.toJson();
      final restored = PlotNode.fromJson(json);

      expect(restored, equals(testNode));
      expect(restored.id, 'pn-1');
      expect(restored.title, 'The inciting incident');
      expect(restored.chapter, 1);
      expect(restored.involvedCharacterIds, ['char-1', 'char-2']);
      expect(restored.involvedCharacterNames, ['Alice', 'Bob']);
      expect(restored.linkedForeshadowingIds, ['fs-1']);
      expect(restored.writingStatus, PlotNodeWritingStatus.drafting);
      expect(restored.structuralRole, PlotNodeStructuralRole.setup);
      expect(restored.causeNodeIds, isEmpty);
      expect(restored.consequenceNodeIds, ['pn-2']);
      expect(restored.manualOrder, 0);
    });

    test('should handle nullable updatedAt in JSON roundtrip', () {
      final noUpdate = testNode.copyWith(clearUpdatedAt: true);
      final json = noUpdate.toJson();
      final restored = PlotNode.fromJson(json);

      expect(restored.updatedAt, isNull);
    });

    test('should handle empty default collections', () {
      final minimal = PlotNode(
        id: 'pn-min',
        title: 'Minimal node',
        chapter: 1,
        summary: '',
        writingStatus: PlotNodeWritingStatus.notStarted,
        structuralRole: PlotNodeStructuralRole.setup,
        manualOrder: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(minimal.involvedCharacterIds, isEmpty);
      expect(minimal.involvedCharacterNames, isEmpty);
      expect(minimal.linkedForeshadowingIds, isEmpty);
      expect(minimal.causeNodeIds, isEmpty);
      expect(minimal.consequenceNodeIds, isEmpty);
      expect(minimal.relatedNodeIds, isEmpty);

      // JSON roundtrip
      final restored = PlotNode.fromJson(minimal.toJson());
      expect(restored, equals(minimal));
    });

    test('should have meaningful toString', () {
      final str = testNode.toString();
      expect(str, contains('PlotNode'));
      expect(str, contains('pn-1'));
      expect(str, contains('The inciting incident'));
    });
  });
}

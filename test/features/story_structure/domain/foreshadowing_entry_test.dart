import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';

void main() {
  group('ForeshadowingMode', () {
    test('should have simple and detailed values', () {
      expect(
        ForeshadowingMode.values,
        containsAll([ForeshadowingMode.simple, ForeshadowingMode.detailed]),
      );
    });
  });

  group('ForeshadowingStatus', () {
    test('should have planted, developing, resolved, abandoned values', () {
      expect(
        ForeshadowingStatus.values,
        containsAll([
          ForeshadowingStatus.planted,
          ForeshadowingStatus.developing,
          ForeshadowingStatus.resolved,
          ForeshadowingStatus.abandoned,
        ]),
      );
    });
  });

  group('SourceLocation', () {
    test('should serialize and deserialize correctly', () {
      const location = SourceLocation(
        nodeId: 'node1',
        startOffset: 10,
        endOffset: 25,
      );
      final json = location.toJson();
      final restored = SourceLocation.fromJson(json);
      expect(restored, equals(location));
    });

    test('should support optional chapter field', () {
      const location = SourceLocation(
        nodeId: 'node1',
        startOffset: 0,
        endOffset: 10,
        chapter: 3,
      );
      expect(location.chapter, 3);
      final json = location.toJson();
      final restored = SourceLocation.fromJson(json);
      expect(restored.chapter, 3);
    });
  });

  group('ForeshadowingEntry', () {
    late ForeshadowingEntry sampleEntry;

    setUp(() {
      sampleEntry = ForeshadowingEntry(
        id: 'test-id-1',
        title: 'Mysterious letter',
        mode: ForeshadowingMode.detailed,
        status: ForeshadowingStatus.planted,
        plantedChapter: 1,
        targetResolutionChapter: 10,
        sourceExcerpt: 'A sealed letter arrived at midnight.',
        sourceLocation: const SourceLocation(
          nodeId: 'para1',
          startOffset: 0,
          endOffset: 35,
          chapter: 1,
        ),
        notes: 'This is the inciting incident hook.',
        linkedPlotNodeIds: ['plot-1'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
    });

    test('should be created with required fields', () {
      expect(sampleEntry.id, 'test-id-1');
      expect(sampleEntry.title, 'Mysterious letter');
      expect(sampleEntry.mode, ForeshadowingMode.detailed);
      expect(sampleEntry.status, ForeshadowingStatus.planted);
      expect(sampleEntry.plantedChapter, 1);
    });

    test('should support copyWith', () {
      final updated = sampleEntry.copyWith(
        title: 'The black envelope',
        status: ForeshadowingStatus.developing,
      );
      expect(updated.title, 'The black envelope');
      expect(updated.status, ForeshadowingStatus.developing);
      expect(updated.id, sampleEntry.id); // unchanged
    });

    test('should roundtrip through JSON serialization', () {
      final json = sampleEntry.toJson();
      final restored = ForeshadowingEntry.fromJson(json);
      expect(restored, equals(sampleEntry));
    });

    test('isOpen should be true for planted and developing status', () {
      expect(
        ForeshadowingEntry(
          id: 'a',
          title: 't',
          mode: ForeshadowingMode.simple,
          status: ForeshadowingStatus.planted,
          plantedChapter: 1,
          createdAt: DateTime(2026),
        ).isOpen,
        isTrue,
      );
      expect(
        ForeshadowingEntry(
          id: 'a',
          title: 't',
          mode: ForeshadowingMode.simple,
          status: ForeshadowingStatus.developing,
          plantedChapter: 1,
          createdAt: DateTime(2026),
        ).isOpen,
        isTrue,
      );
    });

    test('isOpen should be false for resolved and abandoned status', () {
      expect(
        ForeshadowingEntry(
          id: 'a',
          title: 't',
          mode: ForeshadowingMode.simple,
          status: ForeshadowingStatus.resolved,
          plantedChapter: 1,
          createdAt: DateTime(2026),
        ).isOpen,
        isFalse,
      );
      expect(
        ForeshadowingEntry(
          id: 'a',
          title: 't',
          mode: ForeshadowingMode.simple,
          status: ForeshadowingStatus.abandoned,
          plantedChapter: 1,
          createdAt: DateTime(2026),
        ).isOpen,
        isFalse,
      );
    });

    test('isResolved should be true only for resolved status', () {
      for (final status in ForeshadowingStatus.values) {
        final entry = ForeshadowingEntry(
          id: 'a',
          title: 't',
          mode: ForeshadowingMode.simple,
          status: status,
          plantedChapter: 1,
          createdAt: DateTime(2026),
        );
        expect(
          entry.isResolved,
          equals(status == ForeshadowingStatus.resolved),
        );
      }
    });

    test('isOverdue should be true when currentChapter exceeds threshold', () {
      final entry = ForeshadowingEntry(
        id: 'a',
        title: 't',
        mode: ForeshadowingMode.simple,
        status: ForeshadowingStatus.planted,
        plantedChapter: 1,
        createdAt: DateTime(2026),
      );
      // Planted at chapter 1, threshold 3, current chapter 5 => overdue
      expect(entry.isOverdue(currentChapter: 5, defaultThreshold: 3), isTrue);
    });

    test('isOverdue should be false when within threshold', () {
      final entry = ForeshadowingEntry(
        id: 'a',
        title: 't',
        mode: ForeshadowingMode.simple,
        status: ForeshadowingStatus.planted,
        plantedChapter: 1,
        createdAt: DateTime(2026),
      );
      expect(entry.isOverdue(currentChapter: 3, defaultThreshold: 5), isFalse);
    });

    test('isOverdue should consider targetResolutionChapter when set', () {
      final entry = ForeshadowingEntry(
        id: 'a',
        title: 't',
        mode: ForeshadowingMode.detailed,
        status: ForeshadowingStatus.developing,
        plantedChapter: 1,
        targetResolutionChapter: 5,
        createdAt: DateTime(2026),
      );
      // Target chapter 5, current chapter 6 => overdue by target
      expect(entry.isOverdue(currentChapter: 6, defaultThreshold: 100), isTrue);
    });

    test('isOverdue should be false for resolved or abandoned entries', () {
      for (final status in [
        ForeshadowingStatus.resolved,
        ForeshadowingStatus.abandoned,
      ]) {
        final entry = ForeshadowingEntry(
          id: 'a',
          title: 't',
          mode: ForeshadowingMode.simple,
          status: status,
          plantedChapter: 1,
          createdAt: DateTime(2026),
        );
        expect(
          entry.isOverdue(currentChapter: 999, defaultThreshold: 1),
          isFalse,
        );
      }
    });

    test('should handle optional fields with defaults', () {
      final minimal = ForeshadowingEntry(
        id: 'minimal',
        title: 'Simple entry',
        mode: ForeshadowingMode.simple,
        status: ForeshadowingStatus.planted,
        plantedChapter: 1,
        createdAt: DateTime(2026),
      );
      expect(minimal.targetResolutionChapter, isNull);
      expect(minimal.resolvedChapter, isNull);
      expect(minimal.sourceExcerpt, isEmpty);
      expect(minimal.sourceLocation, isNull);
      expect(minimal.notes, isEmpty);
      expect(minimal.linkedPlotNodeIds, isEmpty);
      expect(minimal.updatedAt, isNull);
    });

    test('equality should compare all fields', () {
      final entry1 = ForeshadowingEntry(
        id: 'a',
        title: 't',
        mode: ForeshadowingMode.simple,
        status: ForeshadowingStatus.planted,
        plantedChapter: 1,
        createdAt: DateTime(2026),
      );
      final entry2 = ForeshadowingEntry(
        id: 'a',
        title: 't',
        mode: ForeshadowingMode.simple,
        status: ForeshadowingStatus.planted,
        plantedChapter: 1,
        createdAt: DateTime(2026),
      );
      expect(entry1, equals(entry2));
      expect(entry1.hashCode, equals(entry2.hashCode));
    });
  });
}

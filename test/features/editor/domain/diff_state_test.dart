import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/domain/diff_state.dart';

void main() {
  group('DiffStatus', () {
    test('should have pending, accepted, rejected values', () {
      expect(DiffStatus.values, hasLength(3));
      expect(DiffStatus.pending.name, 'pending');
      expect(DiffStatus.accepted.name, 'accepted');
      expect(DiffStatus.rejected.name, 'rejected');
    });
  });

  group('SentenceDiff', () {
    test(
      'isDeletion should return true when originalText is not null and newText is null',
      () {
        const diff = SentenceDiff(
          originalText: '原文',
          newText: null,
          status: DiffStatus.pending,
          nodeId: 'node1',
          startOffset: 0,
          endOffset: 2,
        );
        expect(diff.isDeletion, isTrue);
        expect(diff.isInsertion, isFalse);
        expect(diff.isModification, isFalse);
      },
    );

    test(
      'isInsertion should return true when originalText is null and newText is not null',
      () {
        const diff = SentenceDiff(
          originalText: null,
          newText: '新文',
          status: DiffStatus.pending,
          nodeId: 'node1',
          startOffset: 0,
          endOffset: 2,
        );
        expect(diff.isInsertion, isTrue);
        expect(diff.isDeletion, isFalse);
        expect(diff.isModification, isFalse);
      },
    );

    test('isModification should return true when both texts are not null', () {
      const diff = SentenceDiff(
        originalText: '原文',
        newText: '新文',
        status: DiffStatus.pending,
        nodeId: 'node1',
        startOffset: 0,
        endOffset: 2,
      );
      expect(diff.isModification, isTrue);
      expect(diff.isDeletion, isFalse);
      expect(diff.isInsertion, isFalse);
    });

    test('copyWith should preserve fields not passed', () {
      const diff = SentenceDiff(
        originalText: '原文',
        newText: '新文',
        status: DiffStatus.pending,
        nodeId: 'node1',
        startOffset: 0,
        endOffset: 2,
      );
      final updated = diff.copyWith(status: DiffStatus.accepted);
      expect(updated.originalText, '原文');
      expect(updated.newText, '新文');
      expect(updated.status, DiffStatus.accepted);
      expect(updated.nodeId, 'node1');
    });

    test('equality should compare all fields', () {
      const a = SentenceDiff(
        originalText: '原文',
        newText: '新文',
        status: DiffStatus.pending,
        nodeId: 'node1',
        startOffset: 0,
        endOffset: 2,
      );
      const b = SentenceDiff(
        originalText: '原文',
        newText: '新文',
        status: DiffStatus.pending,
        nodeId: 'node1',
        startOffset: 0,
        endOffset: 2,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('DiffResult', () {
    test('pendingCount should return count of pending sentences', () {
      const result = DiffResult(
        sentences: [
          SentenceDiff(
            originalText: 'A',
            newText: 'B',
            status: DiffStatus.pending,
            nodeId: 'n1',
            startOffset: 0,
            endOffset: 1,
          ),
          SentenceDiff(
            originalText: 'C',
            newText: 'D',
            status: DiffStatus.accepted,
            nodeId: 'n1',
            startOffset: 1,
            endOffset: 2,
          ),
          SentenceDiff(
            originalText: 'E',
            newText: 'F',
            status: DiffStatus.pending,
            nodeId: 'n1',
            startOffset: 2,
            endOffset: 3,
          ),
        ],
        nodeId: 'n1',
      );
      expect(result.pendingCount, 2);
    });

    test('allResolved should return true when pendingCount is 0', () {
      const result = DiffResult(
        sentences: [
          SentenceDiff(
            originalText: 'A',
            newText: 'B',
            status: DiffStatus.accepted,
            nodeId: 'n1',
            startOffset: 0,
            endOffset: 1,
          ),
        ],
        nodeId: 'n1',
      );
      expect(result.allResolved, isTrue);
    });

    test('allResolved should return false when pending sentences exist', () {
      const result = DiffResult(
        sentences: [
          SentenceDiff(
            originalText: 'A',
            newText: 'B',
            status: DiffStatus.pending,
            nodeId: 'n1',
            startOffset: 0,
            endOffset: 1,
          ),
        ],
        nodeId: 'n1',
      );
      expect(result.allResolved, isFalse);
    });

    test('equality should compare all fields', () {
      const a = DiffResult(sentences: [], nodeId: 'n1');
      const b = DiffResult(sentences: [], nodeId: 'n1');
      expect(a, equals(b));
    });
  });
}

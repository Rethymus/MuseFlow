/// Tests for SelectiveUndoService.
///
/// Validates the AI undo stack that is separate from the document's
/// built-in undo/redo system (Ctrl+Z undoes human edits, not AI accepts).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/selective_undo.dart';

void main() {
  group('UndoEntry', () {
    test('should be immutable with all fields', () {
      final now = DateTime(2026, 6, 2);
      final entry = UndoEntry(
        originalText: '原文',
        replacementText: 'AI改写',
        nodeId: 'node-1',
        startOffset: 0,
        endOffset: 2,
        timestamp: now,
      );

      expect(entry.originalText, '原文');
      expect(entry.replacementText, 'AI改写');
      expect(entry.nodeId, 'node-1');
      expect(entry.startOffset, 0);
      expect(entry.endOffset, 2);
      expect(entry.timestamp, now);
    });

    test('equality should compare all fields', () {
      final now = DateTime(2026, 6, 2);
      final a = UndoEntry(
        originalText: '原文',
        replacementText: 'AI',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 2,
        timestamp: now,
      );
      final b = UndoEntry(
        originalText: '原文',
        replacementText: 'AI',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 2,
        timestamp: now,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('SelectiveUndoService', () {
    late SelectiveUndoService service;

    setUp(() {
      service = SelectiveUndoService();
    });

    test('canUndo should be false when stack is empty', () {
      expect(service.canUndo, false);
    });

    test('record should add entry to stack', () {
      service.record(
        originalText: '原文',
        replacementText: 'AI改写',
        nodeId: 'node-1',
        startOffset: 0,
        endOffset: 2,
      );

      expect(service.canUndo, true);
      expect(service.stackLength, 1);
    });

    test('record should add multiple entries', () {
      service.record(
        originalText: '第一段原文',
        replacementText: '第一段AI',
        nodeId: 'node-1',
        startOffset: 0,
        endOffset: 5,
      );
      service.record(
        originalText: '第二段原文',
        replacementText: '第二段AI',
        nodeId: 'node-2',
        startOffset: 0,
        endOffset: 5,
      );

      expect(service.stackLength, 2);
    });

    test('clear should empty the stack', () {
      service.record(
        originalText: '原文',
        replacementText: 'AI',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 2,
      );
      expect(service.canUndo, true);

      service.clear();
      expect(service.canUndo, false);
      expect(service.stackLength, 0);
    });

    test('lastEntry should return the most recent entry', () {
      service.record(
        originalText: '第一段',
        replacementText: 'AI一',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 3,
      );
      service.record(
        originalText: '第二段',
        replacementText: 'AI二',
        nodeId: 'n2',
        startOffset: 0,
        endOffset: 3,
      );

      final last = service.lastEntry;
      expect(last, isNotNull);
      expect(last!.originalText, '第二段');
      expect(last.replacementText, 'AI二');
    });

    test('lastEntry should return null when stack is empty', () {
      expect(service.lastEntry, isNull);
    });

    test('popLast should remove and return the last entry', () {
      service.record(
        originalText: '第一段',
        replacementText: 'AI一',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 3,
      );
      service.record(
        originalText: '第二段',
        replacementText: 'AI二',
        nodeId: 'n2',
        startOffset: 0,
        endOffset: 3,
      );

      final popped = service.popLast();
      expect(popped, isNotNull);
      expect(popped!.originalText, '第二段');
      expect(service.stackLength, 1);

      final popped2 = service.popLast();
      expect(popped2, isNotNull);
      expect(popped2!.originalText, '第一段');
      expect(service.stackLength, 0);
      expect(service.canUndo, false);
    });

    test('popLast should return null when stack is empty', () {
      expect(service.popLast(), isNull);
    });
  });
}

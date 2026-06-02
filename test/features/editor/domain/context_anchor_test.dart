/// Tests for ContextAnchor entity and AnchorType enum.
///
/// Validates the immutable context anchor entity used for designating
/// reference paragraphs for AI operations.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/domain/context_anchor.dart';

void main() {
  group('AnchorType', () {
    test('should have two values: persistent and oneTime', () {
      expect(AnchorType.values, hasLength(2));
      expect(AnchorType.values, contains(AnchorType.persistent));
      expect(AnchorType.values, contains(AnchorType.oneTime));
    });
  });

  group('ContextAnchor', () {
    test('should create anchor with all required fields', () {
      final now = DateTime(2026, 6, 2);
      final anchor = ContextAnchor(
        id: 'anchor-1',
        text: '她有一双明亮的眼睛，总是带着温柔的微笑。',
        nodeId: 'node-1',
        startOffset: 0,
        endOffset: 20,
        isPersistent: true,
        createdAt: now,
      );

      expect(anchor.id, 'anchor-1');
      expect(anchor.text, '她有一双明亮的眼睛，总是带着温柔的微笑。');
      expect(anchor.nodeId, 'node-1');
      expect(anchor.startOffset, 0);
      expect(anchor.endOffset, 20);
      expect(anchor.isPersistent, true);
      expect(anchor.createdAt, now);
    });

    test('label should be first 20 chars of text with ellipsis when longer',
        () {
      final anchor = ContextAnchor(
        id: 'a1',
        text: '这是一段超过二十个字符的锚点文本内容，用于测试标签截断功能',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 30,
        isPersistent: true,
        createdAt: DateTime(2026, 6, 2),
      );

      expect(anchor.label.length, 23); // 20 chars + '...'
      expect(anchor.label, endsWith('...'));
      expect(anchor.label, startsWith('这是一段超过二十个字符的锚点文本内容'));
    });

    test('label should be full text when 20 chars or shorter', () {
      final anchor = ContextAnchor(
        id: 'a1',
        text: '角色设定',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 4,
        isPersistent: true,
        createdAt: DateTime(2026, 6, 2),
      );

      expect(anchor.label, '角色设定');
    });

    test('copyWith should create a new anchor with updated fields', () {
      final now = DateTime(2026, 6, 2);
      final anchor = ContextAnchor(
        id: 'a1',
        text: '原文',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 2,
        isPersistent: true,
        createdAt: now,
      );

      final updated = anchor.copyWith(isPersistent: false);
      expect(updated.isPersistent, false);
      expect(updated.id, 'a1'); // unchanged
      expect(updated.text, '原文'); // unchanged
    });

    test('equality should compare all fields', () {
      final now = DateTime(2026, 6, 2);
      final a = ContextAnchor(
        id: 'a1',
        text: 'text',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 4,
        isPersistent: true,
        createdAt: now,
      );
      final b = ContextAnchor(
        id: 'a1',
        text: 'text',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 4,
        isPersistent: true,
        createdAt: now,
      );
      final c = a.copyWith(isPersistent: false);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('fromType factory should set isPersistent based on AnchorType', () {
      final persistent = ContextAnchor.fromType(
        id: 'a1',
        text: 'text',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 4,
        type: AnchorType.persistent,
        createdAt: DateTime(2026, 6, 2),
      );
      final oneTime = ContextAnchor.fromType(
        id: 'a2',
        text: 'text',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 4,
        type: AnchorType.oneTime,
        createdAt: DateTime(2026, 6, 2),
      );

      expect(persistent.isPersistent, true);
      expect(oneTime.isPersistent, false);
    });
  });
}

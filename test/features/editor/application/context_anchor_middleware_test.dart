/// Tests for ContextAnchorMiddleware.
///
/// Validates that anchor context is injected into the PromptContext
/// system message for AI operations.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/editor/application/context_anchor_middleware.dart';
import 'package:museflow/features/editor/domain/context_anchor.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('ContextAnchorMiddleware', () {
    late ContextAnchorMiddleware middleware;

    setUp(() {
      middleware = const ContextAnchorMiddleware();
    });

    test('should return context unchanged when anchors is null', () {
      const context = PromptContext(fragments: []);
      final result = middleware.apply(context);
      expect(result.messages, isEmpty);
    });

    test('should return context unchanged when anchors is empty', () {
      const context = PromptContext(fragments: [], anchors: []);
      final result = middleware.apply(context);
      expect(result.messages, isEmpty);
    });

    test('should inject single anchor into system message', () {
      final anchor = ContextAnchor(
        id: 'a1',
        text: '她有一双明亮的眼睛',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 9,
        isPersistent: true,
        createdAt: DateTime(2026, 6, 2),
      );
      final context = PromptContext(fragments: [], anchors: [anchor]);

      final result = middleware.apply(context);

      expect(result.messages, hasLength(1));
      final json = result.messages[0].toJson();
      final content = json['content'] as String;
      expect(content, contains('参考上下文'));
      expect(content, contains('她有一双明亮的眼睛'));
      expect(content, contains(anchor.label));
    });

    test('should inject multiple anchors into system message', () {
      final anchors = [
        ContextAnchor(
          id: 'a1',
          text: '角色描述',
          nodeId: 'n1',
          startOffset: 0,
          endOffset: 4,
          isPersistent: true,
          createdAt: DateTime(2026, 6, 2),
        ),
        ContextAnchor(
          id: 'a2',
          text: '世界观设定',
          nodeId: 'n2',
          startOffset: 0,
          endOffset: 5,
          isPersistent: false,
          createdAt: DateTime(2026, 6, 2),
        ),
      ];
      final context = PromptContext(fragments: [], anchors: anchors);

      final result = middleware.apply(context);

      expect(result.messages, hasLength(1));
      final json = result.messages[0].toJson();
      final content = json['content'] as String;
      expect(content, contains('角色描述'));
      expect(content, contains('世界观设定'));
    });

    test('should append to existing messages', () {
      final anchor = ContextAnchor(
        id: 'a1',
        text: '参考文本',
        nodeId: 'n1',
        startOffset: 0,
        endOffset: 4,
        isPersistent: true,
        createdAt: DateTime(2026, 6, 2),
      );
      final context = PromptContext(
        fragments: [],
        anchors: [anchor],
        messages: [ChatMessage.system('existing system message')],
      );

      final result = middleware.apply(context);

      expect(result.messages, hasLength(2));
      // First message unchanged
      final firstJson = result.messages[0].toJson();
      expect(firstJson['content'], 'existing system message');
      // Second message is anchor context
      final secondJson = result.messages[1].toJson();
      final content = secondJson['content'] as String;
      expect(content, contains('参考上下文'));
      expect(content, contains('参考文本'));
    });

    test('should implement PromptMiddleware interface', () {
      expect(middleware, isA<PromptMiddleware>());
    });
  });
}

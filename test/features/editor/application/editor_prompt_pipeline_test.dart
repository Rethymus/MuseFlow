/// Tests for EditorPromptPipeline and its middleware chain.
///
/// Validates the editor-specific prompt pipeline that assembles prompts
/// for tone rewrite, paragraph polish, and free-input AI operations.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/editor/application/editor_prompt_pipeline.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('PromptContext extensions', () {
    test('should support selectedText field', () {
      const context = PromptContext(
        fragments: [],
        selectedText: '选中的文字',
      );
      expect(context.selectedText, '选中的文字');
    });

    test('should support anchors field', () {
      final anchor = _TestAnchor(text: '角色介绍', label: '角色卡');
      final context = PromptContext(
        fragments: [],
        anchors: [anchor],
      );
      expect(context.anchors, hasLength(1));
      expect(context.anchors![0].text, '角色介绍');
      expect(context.anchors![0].label, '角色卡');
    });

    test('selectedText should default to null', () {
      const context = PromptContext(fragments: []);
      expect(context.selectedText, isNull);
    });

    test('anchors should default to null', () {
      const context = PromptContext(fragments: []);
      expect(context.anchors, isNull);
    });

    test('addMessage should preserve selectedText and anchors', () {
      final anchor = _TestAnchor(text: '设定', label: '世界观');
      final context = PromptContext(
        fragments: [],
        selectedText: '原文',
        anchors: [anchor],
      );
      final updated = context.addMessage(
        ChatMessage.system('test'),
      );
      expect(updated.selectedText, '原文');
      expect(updated.anchors, hasLength(1));
    });

    test('withMessages should preserve selectedText and anchors', () {
      final context = PromptContext(
        fragments: [],
        selectedText: '原文',
        anchors: [],
      );
      final updated = context.withMessages([
        ChatMessage.system('test'),
      ]);
      expect(updated.selectedText, '原文');
      expect(updated.anchors, isEmpty);
    });

    test('replaceSystemMessage should preserve selectedText and anchors', () {
      final context = PromptContext(
        fragments: [],
        selectedText: '原文',
        messages: [ChatMessage.system('old')],
      );
      final updated = context.replaceSystemMessage(0, 'new');
      expect(updated.selectedText, '原文');
    });
  });

  group('EditorPromptPipeline', () {
    late EditorPromptPipeline pipeline;

    setUp(() {
      pipeline = EditorPromptPipeline();
    });

    test('should produce messages for toneRewrite operation', () {
      final context = PromptContext(
        fragments: [],
        selectedText: '月光洒在窗台上',
        selectedOperation: EditorAIOperation.toneRewrite,
      );

      final messages = pipeline.build(context);

      // Should have system message + user message
      expect(messages, hasLength(2));
      // System message should contain the base instruction + persona
      final systemContent = _extractContent(messages[0]);
      expect(systemContent, contains('中文小说作者'));
      expect(systemContent, contains('自然'));
      // System message should contain tone rewrite instruction
      expect(systemContent, contains('语气'));
      // User message should reference selected text
      final userContent = _extractContent(messages[1]);
      expect(userContent, contains('月光洒在窗台上'));
    });

    test('should produce messages for paragraphPolish operation', () {
      final context = PromptContext(
        fragments: [],
        selectedText: '他走在路上',
        selectedOperation: EditorAIOperation.paragraphPolish,
      );

      final messages = pipeline.build(context);

      expect(messages, hasLength(2));
      final systemContent = _extractContent(messages[0]);
      expect(systemContent, contains('润色'));
    });

    test('should produce messages for freeInput operation', () {
      final context = PromptContext(
        fragments: [],
        selectedText: '原文内容',
        selectedOperation: EditorAIOperation.freeInput,
        userInstruction: '请改得更生动一些',
      );

      final messages = pipeline.build(context);

      expect(messages, hasLength(2));
      final systemContent = _extractContent(messages[0]);
      expect(systemContent, contains('指令'));
      final userContent = _extractContent(messages[1]);
      expect(userContent, contains('原文内容'));
    });

    test('should include banned phrases in system message', () {
      final context = PromptContext(
        fragments: [],
        selectedText: '测试文字',
        selectedOperation: EditorAIOperation.toneRewrite,
        bannedPhrases: ['然而', '综上所述'],
      );

      final messages = pipeline.build(context);
      final systemContent = _extractContent(messages[0]);
      expect(systemContent, contains('然而'));
      expect(systemContent, contains('综上所述'));
    });
  });
}

/// Test implementation of AnchorReference.
class _TestAnchor implements AnchorReference {
  @override
  final String text;

  @override
  final String label;

  const _TestAnchor({required this.text, required this.label});
}

/// Extracts text content from a ChatMessage.
String _extractContent(ChatMessage message) {
  final json = message.toJson();
  final content = json['content'];
  if (content is String) return content;
  return '';
}

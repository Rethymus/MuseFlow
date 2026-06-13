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
      const context = PromptContext(fragments: [], selectedText: '选中的文字');
      expect(context.selectedText, '选中的文字');
    });

    test('should support anchors field', () {
      final anchor = _TestAnchor(text: '角色介绍', label: '角色卡');
      final context = PromptContext(fragments: [], anchors: [anchor]);
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
      final updated = context.addMessage(ChatMessage.system('test'));
      expect(updated.selectedText, '原文');
      expect(updated.anchors, hasLength(1));
    });

    test('withMessages should preserve selectedText and anchors', () {
      final context = PromptContext(
        fragments: [],
        selectedText: '原文',
        anchors: [],
      );
      final updated = context.withMessages([ChatMessage.system('test')]);
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

    group('new operations', () {
      test('should produce expand-specific system instruction', () {
        final context = PromptContext(
          fragments: [],
          selectedText: '他走了。',
          selectedOperation: EditorAIOperation.expand,
        );
        final messages = pipeline.build(context);
        final systemContent = _extractContent(messages[0]);
        expect(systemContent, contains('扩写'));
        expect(systemContent, contains('丰富细节'));
      });

      test('should produce compress-specific system instruction', () {
        final context = PromptContext(
          fragments: [],
          selectedText: '他走了。她看着他离开的背影，心中五味杂陈。',
          selectedOperation: EditorAIOperation.compress,
        );
        final messages = pipeline.build(context);
        final systemContent = _extractContent(messages[0]);
        expect(systemContent, contains('缩写'));
        expect(systemContent, contains('精简'));
      });

      test('should produce dialogue-specific system instruction', () {
        final context = PromptContext(
          fragments: [],
          selectedText: '两人发生了争执。',
          selectedOperation: EditorAIOperation.dialogue,
        );
        final messages = pipeline.build(context);
        final systemContent = _extractContent(messages[0]);
        expect(systemContent, contains('对话'));
      });

      test('should produce scene-specific system instruction', () {
        final context = PromptContext(
          fragments: [],
          selectedText: '战场一片狼藉。',
          selectedOperation: EditorAIOperation.scene,
        );
        final messages = pipeline.build(context);
        final systemContent = _extractContent(messages[0]);
        expect(systemContent, contains('场景'));
        expect(systemContent, contains('感官'));
      });
    });

    group('chapter context chain (LFIN-01)', () {
      test('should inject chapterContextChain before adjacent summaries', () {
        final context = PromptContext(
          fragments: [],
          selectedText: '当前文字',
          selectedOperation: EditorAIOperation.toneRewrite,
          chapterContextChain: '紧邻前章摘要：林风雨夜守山。\n前2章摘要：苏雪晴入门。',
          previousChapterSummary: '上一章摘要',
          nextChapterSummary: '下一章摘要',
        );

        final messages = pipeline.build(context);

        // Find the chapter context system message
        final chapterMsg = messages.firstWhere((m) {
          final content = _extractContent(m);
          return content.contains('前序章节脉络');
        }, orElse: () => messages.last);
        final content = _extractContent(chapterMsg);

        // Chain should appear first, then adjacent summaries
        expect(content, contains('前序章节脉络'));
        expect(content, contains('紧邻前章摘要'));
        expect(content, contains('上一章节摘要'));
        expect(content, contains('下一章节摘要'));
      });

      test('should work with only chain and no adjacent summaries', () {
        final context = PromptContext(
          fragments: [],
          selectedText: '当前文字',
          selectedOperation: EditorAIOperation.paragraphPolish,
          chapterContextChain: '紧邻前章摘要：第三章内容。',
        );

        final messages = pipeline.build(context);

        final chapterMsg = messages.firstWhere(
          (m) => _extractContent(m).contains('前序章节脉络'),
          orElse: () => messages.last,
        );
        final content = _extractContent(chapterMsg);

        expect(content, contains('前序章节脉络'));
        expect(content, contains('紧邻前章摘要'));
        expect(content, isNot(contains('上一章节摘要')));
      });
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

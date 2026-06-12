/// Tests for EditorAIState and EditorAIOperation.
///
/// Validates the immutable state entity for editor AI operations:
/// tone rewrite, paragraph polish, and free-input editing.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';

void main() {
  group('EditorAIOperation', () {
    test(
      'should have seven values: toneRewrite, paragraphPolish, freeInput, expand, compress, dialogue, scene',
      () {
        expect(EditorAIOperation.values, hasLength(7));
        expect(
          EditorAIOperation.values,
          contains(EditorAIOperation.toneRewrite),
        );
        expect(
          EditorAIOperation.values,
          contains(EditorAIOperation.paragraphPolish),
        );
        expect(EditorAIOperation.values, contains(EditorAIOperation.freeInput));
        expect(EditorAIOperation.values, contains(EditorAIOperation.expand));
        expect(EditorAIOperation.values, contains(EditorAIOperation.compress));
        expect(EditorAIOperation.values, contains(EditorAIOperation.dialogue));
        expect(EditorAIOperation.values, contains(EditorAIOperation.scene));
      },
    );

    test('toneRewrite label should be 语气改写', () {
      expect(EditorAIOperation.toneRewrite.label, '语气改写');
    });

    test('paragraphPolish label should be 文段润色', () {
      expect(EditorAIOperation.paragraphPolish.label, '文段润色');
    });

    test('freeInput label should be 自由输入', () {
      expect(EditorAIOperation.freeInput.label, '自由输入');
    });

    test('expand label should be 扩写', () {
      expect(EditorAIOperation.expand.label, '扩写');
    });

    test('compress label should be 缩写', () {
      expect(EditorAIOperation.compress.label, '缩写');
    });

    test('dialogue label should be 对话生成', () {
      expect(EditorAIOperation.dialogue.label, '对话生成');
    });

    test('scene label should be 场景描写', () {
      expect(EditorAIOperation.scene.label, '场景描写');
    });
  });

  group('EditorAIState', () {
    test('should have correct defaults', () {
      const state = EditorAIState();
      expect(state.isStreaming, false);
      expect(state.operation, isNull);
      expect(state.progressText, isNull);
      expect(state.error, isNull);
      expect(state.selectedText, '');
      expect(state.selectionNodeId, '');
      expect(state.selectionStartOffset, 0);
      expect(state.selectionEndOffset, 0);
      expect(state.userInstruction, isNull);
      expect(state.reviewSignals, isEmpty);
    });

    test('copyWith should create a new state with updated fields', () {
      const state = EditorAIState();
      final updated = state.copyWith(
        isStreaming: true,
        operation: EditorAIOperation.toneRewrite,
        selectedText: '选中的文字',
        selectionNodeId: 'node-1',
        selectionStartOffset: 5,
        selectionEndOffset: 10,
      );
      expect(updated.isStreaming, true);
      expect(updated.operation, EditorAIOperation.toneRewrite);
      expect(updated.selectedText, '选中的文字');
      expect(updated.selectionNodeId, 'node-1');
      expect(updated.selectionStartOffset, 5);
      expect(updated.selectionEndOffset, 10);
      // Original unchanged
      expect(state.isStreaming, false);
      expect(state.selectedText, '');
    });

    test('copyWith should allow setting progressText', () {
      const state = EditorAIState();
      final updated = state.copyWith(progressText: '正在生成...');
      expect(updated.progressText, '正在生成...');

      final cleared = updated.copyWith(progressText: null);
      expect(cleared.progressText, isNull);
    });

    test('copyWith should allow setting error', () {
      const state = EditorAIState();
      final updated = state.copyWith(error: '出错了');
      expect(updated.error, '出错了');

      // copyWith without error param preserves existing error
      final same = updated.copyWith(isStreaming: true);
      expect(same.error, '出错了');
    });

    test('copyWith should allow setting userInstruction', () {
      const state = EditorAIState();
      final updated = state.copyWith(userInstruction: '请改得更生动');
      expect(updated.userInstruction, '请改得更生动');
    });

    test('copyWith should allow setting reviewSignals', () {
      const state = EditorAIState();
      const signal = ReviewSignal(
        title: '转场套话偏多',
        description: '需要作者复查',
        severity: ReviewSignalSeverity.medium,
        evidence: '2 次',
      );

      final updated = state.copyWith(reviewSignals: const [signal]);

      expect(updated.reviewSignals, contains(signal));
      expect(state.reviewSignals, isEmpty);
    });

    test('should be immutable -- copyWith does not mutate original', () {
      const original = EditorAIState(selectedText: '原文');
      final copy = original.copyWith(selectedText: '修改后');
      expect(original.selectedText, '原文');
      expect(copy.selectedText, '修改后');
    });

    test('conversationHistory should default to empty list', () {
      const state = EditorAIState();
      expect(state.conversationHistory, isEmpty);
    });

    test('copyWith should allow setting conversationHistory', () {
      const state = EditorAIState();
      final turn = ConversationTurn(
        userInstruction: '太平淡了',
        aiResponse: '他猛地推开门。',
        operation: EditorAIOperation.toneRewrite,
      );
      final updated = state.copyWith(conversationHistory: [turn]);
      expect(updated.conversationHistory, hasLength(1));
      expect(updated.conversationHistory.first.userInstruction, '太平淡了');
      expect(state.conversationHistory, isEmpty);
    });
  });

  group('ConversationTurn', () {
    test('should store user instruction and AI response', () {
      const turn = ConversationTurn(
        userInstruction: '太华丽了，朴素一点',
        aiResponse: '他走了。',
        operation: EditorAIOperation.toneRewrite,
      );
      expect(turn.userInstruction, '太华丽了，朴素一点');
      expect(turn.aiResponse, '他走了。');
      expect(turn.operation, EditorAIOperation.toneRewrite);
    });

    test('should convert to chat messages', () {
      const turn = ConversationTurn(
        userInstruction: '请润色',
        aiResponse: '月光洒落。',
        operation: EditorAIOperation.paragraphPolish,
      );
      final messages = turn.toChatMessages();
      expect(messages, hasLength(2));
      expect(messages[0].toJson()['role'], 'user');
      expect(messages[0].toJson()['content'], '请润色');
      expect(messages[1].toJson()['role'], 'assistant');
      expect(messages[1].toJson()['content'], '月光洒落。');
    });

    test('should support equality comparison', () {
      const turn1 = ConversationTurn(
        userInstruction: '改',
        aiResponse: '他走了。',
        operation: EditorAIOperation.toneRewrite,
      );
      const turn2 = ConversationTurn(
        userInstruction: '改',
        aiResponse: '他走了。',
        operation: EditorAIOperation.toneRewrite,
      );
      expect(turn1, equals(turn2));
    });
  });

  group('EditorAIState maxConversationTurns', () {
    test('should be 5', () {
      expect(EditorAIState.maxConversationTurns, 5);
    });
  });
}

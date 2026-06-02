/// Tests for EditorAIState and EditorAIOperation.
///
/// Validates the immutable state entity for editor AI operations:
/// tone rewrite, paragraph polish, and free-input editing.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';

void main() {
  group('EditorAIOperation', () {
    test('should have three values: toneRewrite, paragraphPolish, freeInput',
        () {
      expect(EditorAIOperation.values, hasLength(3));
      expect(EditorAIOperation.values, contains(EditorAIOperation.toneRewrite));
      expect(EditorAIOperation.values,
          contains(EditorAIOperation.paragraphPolish));
      expect(EditorAIOperation.values, contains(EditorAIOperation.freeInput));
    });

    test('toneRewrite label should be 语气改写', () {
      expect(EditorAIOperation.toneRewrite.label, '语气改写');
    });

    test('paragraphPolish label should be 文段润色', () {
      expect(EditorAIOperation.paragraphPolish.label, '文段润色');
    });

    test('freeInput label should be 自由输入', () {
      expect(EditorAIOperation.freeInput.label, '自由输入');
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

    test('should be immutable -- copyWith does not mutate original', () {
      const original = EditorAIState(selectedText: '原文');
      final copy = original.copyWith(selectedText: '修改后');
      expect(original.selectedText, '原文');
      expect(copy.selectedText, '修改后');
    });
  });
}

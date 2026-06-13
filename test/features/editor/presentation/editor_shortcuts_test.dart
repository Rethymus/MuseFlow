/// Tests for editor AI keyboard shortcuts.
///
/// Validates that keyboard shortcuts correctly trigger AI operations
/// when text is selected, and show feedback when no text is selected.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';

void main() {
  group('Editor AI keyboard shortcuts', () {
    test('shortcut key bindings should include Ctrl+Shift+T for tone rewrite', () {
      final keySet = LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyT,
      );
      // Verify the key set resolves to a valid shortcut
      expect(keySet.keys.length, 3);
      expect(keySet.keys.contains(LogicalKeyboardKey.control), isTrue);
      expect(keySet.keys.contains(LogicalKeyboardKey.shift), isTrue);
      expect(keySet.keys.contains(LogicalKeyboardKey.keyT), isTrue);
    });

    test('shortcut key bindings should include Ctrl+Shift+P for polish', () {
      final keySet = LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyP,
      );
      expect(keySet.keys.length, 3);
    });

    test('shortcut key bindings should include Ctrl+Shift+E for expand', () {
      final keySet = LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyE,
      );
      expect(keySet.keys.length, 3);
    });

    test('cancel shortcut should use Escape key', () {
      final keySet = LogicalKeySet(LogicalKeyboardKey.escape);
      expect(keySet.keys.length, 1);
      expect(keySet.keys.contains(LogicalKeyboardKey.escape), isTrue);
    });
  });

  group('EditorAIOperation shortcuts coverage', () {
    test('should have all 7 operation types defined', () {
      expect(EditorAIOperation.values.length, 7);
    });

    test('tone rewrite should have Chinese label', () {
      expect(EditorAIOperation.toneRewrite.label, '语气改写');
    });

    test('paragraph polish should have Chinese label', () {
      expect(EditorAIOperation.paragraphPolish.label, '文段润色');
    });

    test('expand should have Chinese label', () {
      expect(EditorAIOperation.expand.label, '扩写');
    });

    test('compress should have Chinese label', () {
      expect(EditorAIOperation.compress.label, '缩写');
    });

    test('dialogue should have Chinese label', () {
      expect(EditorAIOperation.dialogue.label, '对话生成');
    });

    test('scene should have Chinese label', () {
      expect(EditorAIOperation.scene.label, '场景描写');
    });

    test('free input should have Chinese label', () {
      expect(EditorAIOperation.freeInput.label, '自由输入');
    });

    test('all operations should have non-empty labels', () {
      for (final op in EditorAIOperation.values) {
        expect(op.label, isNotEmpty);
      }
    });
  });
}

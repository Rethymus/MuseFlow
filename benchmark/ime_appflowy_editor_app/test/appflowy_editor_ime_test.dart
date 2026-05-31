import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Automated IME composition tests for appflowy_editor.
///
/// These tests simulate the composing-to-committed text lifecycle that occurs
/// when a user types with a CJK Input Method Editor (IME). They verify that
/// the editor correctly handles:
/// 1. Pinyin composing -> single character commit
/// 2. Multi-character composition commit
/// 3. Composition cancellation (backspace during composing)
/// 4. Mixed Chinese and ASCII text
///
/// The tests use appflowy_editor's Transaction API (insertText, replaceText,
/// deleteText) and EditorState.apply() to simulate text mutations, mimicking
/// how an IME would modify the document through the composing lifecycle.
///
/// NOTE: These tests verify TEXT CONTENT correctness only. They cannot verify
/// IME candidate window POSITION (requires manual testing per RESEARCH.md Pitfall 3).
void main() {
  group('appflowy_editor IME composition tests', () {
    late EditorState editorState;
    late Document document;

    setUp(() {
      document = Document.blank();
      editorState = EditorState(document: document);
    });

    tearDown(() {
      editorState.dispose();
    });

    test(
        'should handle pinyin composing lifecycle -> single character commit',
        () {
      // Simulate: "jin" composing, then commit to "今"

      final node = document.root.children.first;

      // Step 1: Verify empty document
      expect(_getDocumentText(document), '');

      // Step 2: Insert "jin" as composing text
      final t1 = editorState.transaction;
      t1.insertText(node, 0, 'jin');
      editorState.apply(t1);
      expect(_getDocumentText(document), 'jin');

      // Step 3: Replace "jin" with "今" (IME commit)
      final t2 = editorState.transaction;
      t2.replaceText(node, 0, 3, '今');
      editorState.apply(t2);

      // Verify committed character
      expect(_getDocumentText(document), '今');
    });

    test('should handle multi-character composition commit', () {
      // Simulate "jintian" composing, then committing "今天"

      final node = document.root.children.first;

      // Composing phase: insert "jintian"
      final t1 = editorState.transaction;
      t1.insertText(node, 0, 'jintian');
      editorState.apply(t1);
      expect(_getDocumentText(document), 'jintian');

      // Commit phase: "jintian" -> "今天"
      final t2 = editorState.transaction;
      t2.replaceText(node, 0, 7, '今天');
      editorState.apply(t2);

      expect(_getDocumentText(document), '今天');
    });

    test('should handle composition cancellation via backspace', () {
      // Simulate "jin" composing, then backspace to cancel.

      final node = document.root.children.first;

      // Composing phase: insert "jin"
      final t1 = editorState.transaction;
      t1.insertText(node, 0, 'jin');
      editorState.apply(t1);
      expect(_getDocumentText(document), 'jin');

      // Cancel: delete composing text
      final t2 = editorState.transaction;
      t2.deleteText(node, 0, 3);
      editorState.apply(t2);

      // After cancellation, document should be empty
      expect(_getDocumentText(document), '');
    });

    test('should handle mixed Chinese and ASCII text', () {
      // Type "hello" (no composing), then "nihao" composing to "你好".

      final node = document.root.children.first;

      // Type "hello"
      final t1 = editorState.transaction;
      t1.insertText(node, 0, 'hello');
      editorState.apply(t1);
      expect(_getDocumentText(document), 'hello');

      // Composing phase: append "nihao"
      final t2 = editorState.transaction;
      t2.insertText(node, 5, 'nihao');
      editorState.apply(t2);
      expect(_getDocumentText(document), 'hellonihao');

      // Commit phase: replace "nihao" with "你好"
      final t3 = editorState.transaction;
      t3.replaceText(node, 5, 5, '你好');
      editorState.apply(t3);

      expect(_getDocumentText(document), 'hello你好');
    });
  });
}

/// Extracts plain text content from an appflowy_editor [Document].
String _getDocumentText(Document document) {
  final buffer = StringBuffer();
  for (final node in document.root.children) {
    if (node.delta != null) {
      buffer.write(node.delta!.toPlainText());
    }
  }
  return buffer.toString();
}

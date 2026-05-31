import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

/// Automated IME composition tests for super_editor.
///
/// These tests simulate the composing-to-committed text lifecycle that occurs
/// when a user types with a CJK Input Method Editor (IME). They verify that
/// the editor correctly handles:
/// 1. Pinyin composing -> single character commit
/// 2. Multi-character composition commit
/// 3. Composition cancellation (backspace during composing)
/// 4. Mixed Chinese and ASCII text
///
/// The tests use super_editor's Editor + InsertTextRequest/DeleteContentRequest
/// API to simulate text insertions and deletions, mimicking how an IME would
/// modify the document through the composing lifecycle.
///
/// NOTE: These tests verify TEXT CONTENT correctness only. They cannot verify
/// IME candidate window POSITION (requires manual testing per RESEARCH.md Pitfall 3).
void main() {
  group('super_editor IME composition tests', () {
    late MutableDocument document;
    late MutableDocumentComposer composer;
    late Editor editor;

    setUp(() {
      document = MutableDocument.empty();
      composer = MutableDocumentComposer();
      editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: List.from(defaultRequestHandlers),
        reactionPipeline: [],
      );
    });

    tearDown(() {
      composer.dispose();
      document.dispose();
      editor.dispose();
    });

    test(
        'should handle pinyin composing lifecycle -> single character commit',
        () {
      final nodeId = document.first.id;

      // Step 1: Verify empty document
      expect(_getDocumentText(document), '');

      // Step 2: Insert "jin" as composing text
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: nodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          textToInsert: 'jin',
          attributions: {},
        ),
      ]);
      expect(_getDocumentText(document), 'jin');

      // Step 3: Simulate IME commit -- replace "jin" with "今"
      editor.execute([
        DeleteContentRequest(
          documentRange: DocumentRange(
            start: DocumentPosition(
              nodeId: nodeId,
              nodePosition: const TextNodePosition(offset: 0),
            ),
            end: DocumentPosition(
              nodeId: nodeId,
              nodePosition: const TextNodePosition(offset: 3),
            ),
          ),
        ),
      ]);
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: nodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          textToInsert: '今',
          attributions: {},
        ),
      ]);

      expect(_getDocumentText(document), '今');
    });

    test('should handle multi-character composition commit', () {
      final nodeId = document.first.id;

      // Composing phase: insert "jintian"
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: nodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          textToInsert: 'jintian',
          attributions: {},
        ),
      ]);
      expect(_getDocumentText(document), 'jintian');

      // Commit phase: replace "jintian" with "今天"
      editor.execute([
        DeleteContentRequest(
          documentRange: DocumentRange(
            start: DocumentPosition(
              nodeId: nodeId,
              nodePosition: const TextNodePosition(offset: 0),
            ),
            end: DocumentPosition(
              nodeId: nodeId,
              nodePosition: const TextNodePosition(offset: 7),
            ),
          ),
        ),
      ]);
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: nodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          textToInsert: '今天',
          attributions: {},
        ),
      ]);

      expect(_getDocumentText(document), '今天');
    });

    test('should handle composition cancellation via backspace', () {
      final nodeId = document.first.id;

      // Composing phase: insert "jin"
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: nodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          textToInsert: 'jin',
          attributions: {},
        ),
      ]);
      expect(_getDocumentText(document), 'jin');

      // Cancel: delete the composing text
      editor.execute([
        DeleteContentRequest(
          documentRange: DocumentRange(
            start: DocumentPosition(
              nodeId: nodeId,
              nodePosition: const TextNodePosition(offset: 0),
            ),
            end: DocumentPosition(
              nodeId: nodeId,
              nodePosition: const TextNodePosition(offset: 3),
            ),
          ),
        ),
      ]);

      expect(_getDocumentText(document), '');
    });

    test('should handle mixed Chinese and ASCII text', () {
      final nodeId = document.first.id;

      // Type "hello" directly
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: nodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          textToInsert: 'hello',
          attributions: {},
        ),
      ]);
      expect(_getDocumentText(document), 'hello');

      // Composing phase: append "nihao" after "hello"
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: nodeId,
            nodePosition: const TextNodePosition(offset: 5),
          ),
          textToInsert: 'nihao',
          attributions: {},
        ),
      ]);
      expect(_getDocumentText(document), 'hellonihao');

      // Commit phase: replace "nihao" with "你好"
      editor.execute([
        DeleteContentRequest(
          documentRange: DocumentRange(
            start: DocumentPosition(
              nodeId: nodeId,
              nodePosition: const TextNodePosition(offset: 5),
            ),
            end: DocumentPosition(
              nodeId: nodeId,
              nodePosition: const TextNodePosition(offset: 10),
            ),
          ),
        ),
      ]);
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: nodeId,
            nodePosition: const TextNodePosition(offset: 5),
          ),
          textToInsert: '你好',
          attributions: {},
        ),
      ]);

      expect(_getDocumentText(document), 'hello你好');
    });
  });
}

/// Extracts plain text content from a [MutableDocument].
String _getDocumentText(MutableDocument document) {
  final buffer = StringBuffer();
  for (final node in document) {
    if (node is TextNode) {
      buffer.write(node.text.toPlainText());
    }
  }
  return buffer.toString();
}

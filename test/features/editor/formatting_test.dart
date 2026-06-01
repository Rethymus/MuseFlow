import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

/// Helper to create a default editor with a single paragraph for testing.
Editor _createTestEditor([String text = 'Hello world']) {
  final document = MutableDocument(
    nodes: [
      ParagraphNode(
        id: 'test-node',
        text: AttributedText(text),
      ),
    ],
  );
  return createDefaultDocumentEditor(document: document);
}

/// Helper to get the first node from a MutableDocument as a specific type.
T _firstNodeAs<T>(MutableDocument document) {
  return document.first as T;
}

void main() {
  group('Editor formatting', () {
    late Editor editor;

    setUp(() {
      editor = _createTestEditor('Hello world');
    });

    tearDown(() {
      editor.composer.dispose();
    });

    group('bold formatting', () {
      test('should apply boldAttribution to selected text via ToggleTextAttributionsRequest', () {
        // Select characters 0-5 ("Hello")
        final selection = DocumentSelection(
          base: DocumentPosition(nodeId: 'test-node', nodePosition: const TextNodePosition(offset: 0)),
          extent: DocumentPosition(nodeId: 'test-node', nodePosition: const TextNodePosition(offset: 5)),
        );

        editor.execute([
          ToggleTextAttributionsRequest(
            documentRange: selection,
            attributions: {boldAttribution},
          ),
        ]);

        // Verify bold is applied to the selected range
        final node = _firstNodeAs<ParagraphNode>(editor.document);
        final text = node.text;

        // Check that the text at offset 0-5 has bold attribution
        final spans = text.getAttributionSpansInRange(
          attributionFilter: (attribution) => attribution == boldAttribution,
          range: const SpanRange(0, 4),
        );
        expect(spans, isNotEmpty, reason: 'Bold attribution should be applied to selected text');
      });

      test('should toggle composer preferences for bold when selection is collapsed', () {
        // Set a collapsed selection
        (editor.composer as MutableDocumentComposer).setSelectionWithReason(
          DocumentSelection.collapsed(
            position: DocumentPosition(nodeId: 'test-node', nodePosition: const TextNodePosition(offset: 5)),
          ),
        );

        // Toggle bold on preferences
        editor.composer.preferences.toggleStyles({boldAttribution});

        // Verify bold is now in current attributions
        expect(
          editor.composer.preferences.currentAttributions,
          contains(boldAttribution),
          reason: 'Bold should be in composer preferences after toggle',
        );

        // Toggle again to remove
        editor.composer.preferences.toggleStyles({boldAttribution});
        expect(
          editor.composer.preferences.currentAttributions,
          isNot(contains(boldAttribution)),
          reason: 'Bold should be removed after second toggle',
        );
      });
    });

    group('italic formatting', () {
      test('should apply italicsAttribution to selected text via ToggleTextAttributionsRequest', () {
        // Select characters 0-5 ("Hello")
        final selection = DocumentSelection(
          base: DocumentPosition(nodeId: 'test-node', nodePosition: const TextNodePosition(offset: 0)),
          extent: DocumentPosition(nodeId: 'test-node', nodePosition: const TextNodePosition(offset: 5)),
        );

        editor.execute([
          ToggleTextAttributionsRequest(
            documentRange: selection,
            attributions: {italicsAttribution},
          ),
        ]);

        // Verify italic is applied to the selected range
        final node = _firstNodeAs<ParagraphNode>(editor.document);
        final text = node.text;

        final spans = text.getAttributionSpansInRange(
          attributionFilter: (attribution) => attribution == italicsAttribution,
          range: const SpanRange(0, 4),
        );
        expect(spans, isNotEmpty, reason: 'Italic attribution should be applied to selected text');
      });
    });

    group('heading conversion', () {
      test('should convert paragraph to H1 with header1Attribution blockType', () {
        final node = _firstNodeAs<ParagraphNode>(editor.document);
        final originalText = node.text;

        // Replace the paragraph with an H1 version
        final newNode = ParagraphNode(
          id: 'test-node',
          text: originalText,
          metadata: {'blockType': header1Attribution},
        );

        editor.execute([
          ReplaceNodeRequest(existingNodeId: 'test-node', newNode: newNode),
        ]);

        // Verify the node now has header1 blockType
        final updatedNode = _firstNodeAs<ParagraphNode>(editor.document);
        expect(updatedNode.metadata['blockType'], equals(header1Attribution));
        expect(updatedNode.text.toPlainText(), equals('Hello world'));
      });

      test('should convert paragraph to H2 with header2Attribution blockType', () {
        final node = _firstNodeAs<ParagraphNode>(editor.document);

        final newNode = ParagraphNode(
          id: 'test-node',
          text: node.text,
          metadata: {'blockType': header2Attribution},
        );

        editor.execute([
          ReplaceNodeRequest(existingNodeId: 'test-node', newNode: newNode),
        ]);

        final updatedNode = _firstNodeAs<ParagraphNode>(editor.document);
        expect(updatedNode.metadata['blockType'], equals(header2Attribution));
      });

      test('should convert paragraph to H3 with header3Attribution blockType', () {
        final node = _firstNodeAs<ParagraphNode>(editor.document);

        final newNode = ParagraphNode(
          id: 'test-node',
          text: node.text,
          metadata: {'blockType': header3Attribution},
        );

        editor.execute([
          ReplaceNodeRequest(existingNodeId: 'test-node', newNode: newNode),
        ]);

        final updatedNode = _firstNodeAs<ParagraphNode>(editor.document);
        expect(updatedNode.metadata['blockType'], equals(header3Attribution));
      });
    });

    group('list conversion', () {
      test('should convert paragraph to unordered ListItemNode', () {
        final node = _firstNodeAs<ParagraphNode>(editor.document);

        final newNode = ListItemNode(
          id: 'test-node',
          itemType: ListItemType.unordered,
          text: node.text,
        );

        editor.execute([
          ReplaceNodeRequest(existingNodeId: 'test-node', newNode: newNode),
        ]);

        // Verify the node is now a ListItemNode with unordered type
        final updatedNode = editor.document.first;
        expect(updatedNode, isA<ListItemNode>());
        final listItem = updatedNode as ListItemNode;
        expect(listItem.type, equals(ListItemType.unordered));
        expect(listItem.text.toPlainText(), equals('Hello world'));
      });

      test('should convert paragraph to ordered ListItemNode', () {
        final node = _firstNodeAs<ParagraphNode>(editor.document);

        final newNode = ListItemNode(
          id: 'test-node',
          itemType: ListItemType.ordered,
          text: node.text,
        );

        editor.execute([
          ReplaceNodeRequest(existingNodeId: 'test-node', newNode: newNode),
        ]);

        // Verify the node is now a ListItemNode with ordered type
        final updatedNode = editor.document.first;
        expect(updatedNode, isA<ListItemNode>());
        final listItem = updatedNode as ListItemNode;
        expect(listItem.type, equals(ListItemType.ordered));
      });
    });

    group('toolbar active state', () {
      test('should detect bold in composer preferences when set', () {
        // Simulate collapsed cursor with bold preference active
        (editor.composer as MutableDocumentComposer).setSelectionWithReason(
          DocumentSelection.collapsed(
            position: DocumentPosition(nodeId: 'test-node', nodePosition: const TextNodePosition(offset: 0)),
          ),
        );
        editor.composer.preferences.toggleStyles({boldAttribution});

        final isBoldActive = editor.composer.preferences.currentAttributions.contains(boldAttribution);
        expect(isBoldActive, isTrue, reason: 'Bold should be detected as active in preferences');
      });

      test('should not show bold as active when not set', () {
        (editor.composer as MutableDocumentComposer).setSelectionWithReason(
          DocumentSelection.collapsed(
            position: DocumentPosition(nodeId: 'test-node', nodePosition: const TextNodePosition(offset: 0)),
          ),
        );

        final isBoldActive = editor.composer.preferences.currentAttributions.contains(boldAttribution);
        expect(isBoldActive, isFalse, reason: 'Bold should not be active when not toggled');
      });

      test('should detect bold attribution on text at expanded selection', () {
        // First apply bold to text
        final selection = DocumentSelection(
          base: DocumentPosition(nodeId: 'test-node', nodePosition: const TextNodePosition(offset: 0)),
          extent: DocumentPosition(nodeId: 'test-node', nodePosition: const TextNodePosition(offset: 5)),
        );

        editor.execute([
          ToggleTextAttributionsRequest(
            documentRange: selection,
            attributions: {boldAttribution},
          ),
        ]);

        // Verify the document has bold at the range
        final node = _firstNodeAs<ParagraphNode>(editor.document);
        final text = node.text;

        // Check span at offset 0-4
        final spans = text.getAttributionSpansInRange(
          attributionFilter: (attribution) => attribution == boldAttribution,
          range: const SpanRange(0, 4),
        );
        expect(spans, isNotEmpty, reason: 'Text should have bold attribution applied');
      });
    });
  });
}

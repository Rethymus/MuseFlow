import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/infrastructure/provenance_attribution.dart';
import 'package:museflow/features/onboarding/presentation/opening_text_insertion.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  group('insertOpeningText', () {
    late Editor editor;

    setUp(() {
      editor = createDefaultDocumentEditor(
        document: MutableDocument(
          nodes: [ParagraphNode(id: 'node-1', text: AttributedText('已有文字'))],
        ),
      );
    });

    tearDown(() {
      editor.composer.dispose();
    });

    test('inserts at collapsed cursor with provenance', () {
      editor.composer.setSelectionWithReason(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: 'node-1',
            nodePosition: const TextNodePosition(offset: 2),
          ),
        ),
      );

      final inserted = insertOpeningText(editor, '开篇');

      expect(inserted, isTrue);
      final node = editor.document.first as ParagraphNode;
      expect(node.text.toPlainText(), '已有开篇文字');
      final spans = node.text.getAttributionSpansInRange(
        attributionFilter: (attribution) =>
            attribution == aiProvenanceAttribution,
        range: const SpanRange(2, 3),
      );
      expect(spans, isNotEmpty);
    });

    test('replaces expanded selection', () {
      editor.composer.setSelectionWithReason(
        DocumentSelection(
          base: DocumentPosition(
            nodeId: 'node-1',
            nodePosition: const TextNodePosition(offset: 0),
          ),
          extent: DocumentPosition(
            nodeId: 'node-1',
            nodePosition: const TextNodePosition(offset: 2),
          ),
        ),
      );

      final inserted = insertOpeningText(editor, '新');

      expect(inserted, isTrue);
      final node = editor.document.first as ParagraphNode;
      expect(node.text.toPlainText(), '新文字');
    });

    test('appends to first text node when no selection exists', () {
      final inserted = insertOpeningText(editor, '开篇');

      expect(inserted, isTrue);
      final node = editor.document.first as ParagraphNode;
      expect(node.text.toPlainText(), '已有文字\n\n开篇');
    });

    test('returns false for empty text', () {
      expect(insertOpeningText(editor, '   '), isFalse);
    });

    test('calls AI insertion callback after successful insert', () {
      String? insertedText;

      final inserted = insertOpeningText(
        editor,
        '开篇',
        onAiInserted: (text) => insertedText = text,
      );

      expect(inserted, isTrue);
      expect(insertedText, '开篇');
    });
  });
}

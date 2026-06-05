import 'package:museflow/features/editor/infrastructure/provenance_attribution.dart';
import 'package:super_editor/super_editor.dart';

/// Inserts AI-generated opening text into the current editor document.
///
/// Prefers the active cursor/selection. If the editor has no active selection,
/// appends to the first text node so onboarding completion still produces a
/// tangible draft in the default editor document.
bool insertOpeningText(
  Editor? editor,
  String text, {
  void Function(String text)? onAiInserted,
}) {
  final trimmed = text.trim();
  if (editor == null || trimmed.isEmpty) return false;

  final selection = editor.composer.selection;
  if (selection != null) {
    final position = _insertionPositionFor(selection);
    editor.execute([
      if (!selection.isCollapsed)
        DeleteContentRequest(documentRange: selection),
      InsertTextRequest(
        documentPosition: position,
        textToInsert: trimmed,
        attributions: {aiProvenanceAttribution},
      ),
    ]);
    onAiInserted?.call(trimmed);
    return true;
  }

  TextNode? firstTextNode;
  for (final node in editor.document) {
    if (node is TextNode) {
      firstTextNode = node;
      break;
    }
  }
  if (firstTextNode == null) return false;

  final prefix = firstTextNode.text.toPlainText().isEmpty ? '' : '\n\n';
  editor.execute([
    InsertTextRequest(
      documentPosition: DocumentPosition(
        nodeId: firstTextNode.id,
        nodePosition: TextNodePosition(
          offset: firstTextNode.text.toPlainText().length,
        ),
      ),
      textToInsert: '$prefix$trimmed',
      attributions: {aiProvenanceAttribution},
    ),
  ]);
  onAiInserted?.call(trimmed);
  return true;
}

DocumentPosition _insertionPositionFor(DocumentSelection selection) {
  if (selection.isCollapsed) return selection.extent;

  final basePosition = selection.base.nodePosition;
  final extentPosition = selection.extent.nodePosition;
  if (selection.base.nodeId == selection.extent.nodeId &&
      basePosition is TextNodePosition &&
      extentPosition is TextNodePosition) {
    return basePosition.offset <= extentPosition.offset
        ? selection.base
        : selection.extent;
  }

  return selection.base;
}

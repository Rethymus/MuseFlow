import 'package:super_editor/super_editor.dart';

/// Creates a default Editor with a single paragraph placeholder.
///
/// The Editor is created and owned by the EditorPage widget (StatefulWidget)
/// since it is mutable and tightly coupled to the widget lifecycle. The same
/// Editor instance is passed to both the EditorToolbar and SuperEditor widget.
Editor createDefaultEditor() {
  return createDefaultDocumentEditor(
    document: MutableDocument(
      nodes: [
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText('开始在 MuseFlow 中创作...'),
        ),
      ],
    ),
  );
}

/// Creates an Editor pre-loaded with the given [document].
///
/// Used by EditorWithSidebar to create an Editor for a specific chapter's
/// document content. Per RESEARCH.md Open Question 1 (RESOLVED): the Editor
/// is tightly coupled to its Document, so a new Editor is created per chapter.
Editor createEditorWithDocument(MutableDocument document) {
  return createDefaultDocumentEditor(document: document);
}

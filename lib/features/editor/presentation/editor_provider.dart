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

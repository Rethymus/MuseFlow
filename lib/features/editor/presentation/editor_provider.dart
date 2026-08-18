import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';

/// Notifier exposing the current Editor instance.
///
/// Set by EditorWithSidebar when a chapter loads, cleared on disposal.
/// Per Pitfall 6: StatefulShellRoute.indexedStack keeps the editor mounted,
/// so the Editor is always available even when on the capture page.
class EditorHolderNotifier extends Notifier<Editor?> {
  @override
  Editor? build() => null;

  /// Sets the current editor instance.
  void setEditor(Editor? editor) => state = editor;
}

/// Provider exposing the current Editor instance for cross-widget access.
final editorProvider = NotifierProvider<EditorHolderNotifier, Editor?>(
  EditorHolderNotifier.new,
);

/// Creates a default Editor with a single paragraph placeholder.
///
/// The Editor is created and owned by the host editor widget (StatefulWidget)
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

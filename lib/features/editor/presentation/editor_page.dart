import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:super_editor/super_editor.dart';

/// Editor page with a super_editor instance in a centered layout.
///
/// Phase 1: basic editor with default paragraph. Toolbar added in Plan 02.
class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  late final Editor _editor;

  @override
  void initState() {
    super.initState();
    final document = MutableDocument(
      nodes: [
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText('开始在 MuseFlow 中创作...'),
        ),
      ],
    );
    _editor = createDefaultDocumentEditor(
      document: document,
    );
  }

  @override
  void dispose() {
    _editor.composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.editorMaxWidth,
            ),
            child: SuperEditor(
              editor: _editor,
              autofocus: true,
            ),
          ),
        ),
      ),
    );
  }
}

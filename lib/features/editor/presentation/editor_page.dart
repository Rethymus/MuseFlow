import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:museflow/features/editor/presentation/editor_provider.dart';
import 'package:museflow/features/editor/presentation/editor_toolbar.dart';
import 'package:super_editor/super_editor.dart';

/// Notifier exposing the current Editor instance.
///
/// Set by EditorPage in initState, cleared in dispose.
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

/// Editor page with fixed formatting toolbar and centered super_editor.
///
/// Layout: EditorToolbar + Divider + Expanded(centered SuperEditor at max 800px).
/// Keyboard shortcuts: Ctrl+B (bold), Ctrl+I (italic).
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
    _editor = createDefaultEditor();
    // Expose editor via provider for synthesis text insertion per D-07
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorProvider.notifier).setEditor(_editor);
    });
  }

  @override
  void dispose() {
    ref.read(editorProvider.notifier).setEditor(null);
    _editor.composer.dispose();
    super.dispose();
  }

  void _toggleBold() {
    final composer = _editor.composer;
    final selection = composer.selection;
    if (selection == null) return;

    if (selection.isCollapsed) {
      composer.preferences.toggleStyles({boldAttribution});
    } else {
      _editor.execute([
        ToggleTextAttributionsRequest(
          documentRange: selection,
          attributions: {boldAttribution},
        ),
      ]);
    }
  }

  void _toggleItalic() {
    final composer = _editor.composer;
    final selection = composer.selection;
    if (selection == null) return;

    if (selection.isCollapsed) {
      composer.preferences.toggleStyles({italicsAttribution});
    } else {
      _editor.execute([
        ToggleTextAttributionsRequest(
          documentRange: selection,
          attributions: {italicsAttribution},
        ),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
            const _BoldIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI):
            const _ItalicIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _BoldIntent: CallbackAction<_BoldIntent>(
            onInvoke: (_) => _toggleBold(),
          ),
          _ItalicIntent: CallbackAction<_ItalicIntent>(
            onInvoke: (_) => _toggleItalic(),
          ),
        },
        child: Scaffold(
          body: Column(
            children: [
              // Fixed toolbar at top
              EditorToolbar(editor: _editor),
              // Divider between toolbar and editor
              Divider(height: 1, thickness: 1, color: colorScheme.outline),
              // Editor area with centered layout
              Expanded(
                child: SingleChildScrollView(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Keyboard shortcut intents ---

class _BoldIntent extends Intent {
  const _BoldIntent();
}

class _ItalicIntent extends Intent {
  const _ItalicIntent();
}

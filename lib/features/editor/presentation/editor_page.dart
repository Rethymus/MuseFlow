import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:museflow/features/editor/presentation/context_anchor_indicator.dart';
import 'package:museflow/features/editor/presentation/diff_display.dart';
import 'package:museflow/features/editor/presentation/editor_provider.dart';
import 'package:museflow/features/editor/presentation/editor_toolbar.dart';
import 'package:museflow/features/editor/presentation/floating_toolbar.dart';
import 'package:museflow/features/editor/presentation/status_bar.dart';
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
  late final SelectionLayerLinks _selectionLinks;

  @override
  void initState() {
    super.initState();
    _editor = createDefaultEditor();
    _selectionLinks = SelectionLayerLinks();
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
        // EDIT-06: Ctrl+Shift+Z for AI undo (separate from Ctrl+Z)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift,
            LogicalKeyboardKey.keyZ): const _UndoAIIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _BoldIntent: CallbackAction<_BoldIntent>(
            onInvoke: (_) => _toggleBold(),
          ),
          _ItalicIntent: CallbackAction<_ItalicIntent>(
            onInvoke: (_) => _toggleItalic(),
          ),
          _UndoAIIntent: CallbackAction<_UndoAIIntent>(
            onInvoke: (_) => _undoLastAIChange(),
          ),
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _checkUnresolvedDiffs(context);
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
                          selectionLayerLinks: _selectionLinks,
                          documentOverlayBuilders: [
                            // Selection leaders layer (positions leader widgets
                            // at selection bounds for the floating toolbar)
                            _SelectionLeadersLayerBuilder(
                              links: _selectionLinks,
                            ),
                            // D-14: Anchor indicators (background layer)
                            const ContextAnchorOverlayBuilder(),
                            // Diff highlights overlay
                            const DiffOverlayBuilder(),
                            // Floating toolbar for AI actions
                            FunctionalSuperEditorLayerBuilder(
                              (context, editContext) {
                                return ContentLayerProxyWidget(
                                  child: FloatingToolbar(
                                    editor: _editor,
                                    selectionLayerLinks: _selectionLinks,
                                  ),
                                );
                              },
                            ),
                            // Accept/reject action bar for pending diffs
                            FunctionalSuperEditorLayerBuilder(
                              (context, editContext) {
                                return ContentLayerProxyWidget(
                                  child: AcceptRejectBar(
                                    editor: _editor,
                                    selectionLayerLinks: _selectionLinks,
                                  ),
                                );
                              },
                            ),
                            // Default caret overlay
                            const DefaultCaretOverlayBuilder(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Status bar showing pending AI modification count (D-11)
                const StatusBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Undoes the last AI modification via SelectiveUndoService.
  ///
  /// Per EDIT-06: Separate from Ctrl+Z (which undoes human edits).
  void _undoLastAIChange() {
    ref.read(editorAINotifierProvider.notifier).undoLastAIChange();
  }

  /// Checks for unresolved diffs before navigating away.
  ///
  /// Per D-04: Shows a confirmation dialog when there are pending
  /// AI modifications, warning the user before leaving.
  void _checkUnresolvedDiffs(BuildContext context) {
    final aiState = ref.read(editorAINotifierProvider);
    final diffResult = aiState.diffResult;

    if (diffResult == null || diffResult.allResolved) {
      // No unresolved diffs -- allow navigation
      Navigator.of(context).pop();
      return;
    }

    final pendingCount = diffResult.pendingCount;

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未确认的AI修改'),
        content: Text('有 $pendingCount 处未确认的AI修改，确定离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('留在当前页'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('放弃修改'),
          ),
        ],
      ),
    ).then((shouldPop) {
      if (shouldPop == true && context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}

// --- Keyboard shortcut intents ---

class _BoldIntent extends Intent {
  const _BoldIntent();
}

class _ItalicIntent extends Intent {
  const _ItalicIntent();
}

class _UndoAIIntent extends Intent {
  const _UndoAIIntent();
}

/// Layer builder that positions leader widgets at selection bounds.
///
/// This provides the [LeaderLink]s that the [FloatingToolbar] uses
/// via [Follower.withOffset] to position itself relative to the selection.
class _SelectionLeadersLayerBuilder implements SuperEditorLayerBuilder {
  const _SelectionLeadersLayerBuilder({required this.links});

  final SelectionLayerLinks links;

  @override
  ContentLayerWidget build(BuildContext context, SuperEditorContext editContext) {
    return SelectionLeadersDocumentLayer(
      document: editContext.document,
      selection: editContext.composer.selectionNotifier,
      links: links,
    );
  }
}

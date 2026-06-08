import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/editor/infrastructure/provenance_attribution.dart';
import 'package:museflow/features/editor/presentation/context_anchor_indicator.dart';
import 'package:museflow/features/editor/presentation/diff_display.dart';
import 'package:museflow/features/editor/presentation/editor_provider.dart';
import 'package:museflow/features/editor/presentation/editor_toolbar.dart';
import 'package:museflow/features/editor/presentation/floating_toolbar.dart';
import 'package:museflow/features/editor/presentation/status_bar.dart';
import 'package:museflow/features/knowledge/presentation/deviation_warning_widget.dart';
import 'package:museflow/features/manuscript/application/chapter_auto_save.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/presentation/chapter_context_menu.dart';
import 'package:museflow/features/manuscript/presentation/chapter_create_dialog.dart';
import 'package:museflow/features/manuscript/presentation/chapter_rename_dialog.dart';
import 'package:museflow/features/manuscript/presentation/chapter_sidebar.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:super_editor/super_editor.dart';

/// Builds a theme-aware provenance stylesheet for the manuscript editor.
///
/// Converts the former top-level variable to a function so text color
/// follows the current theme's onSurface color (dark mode fix, P14-07-UI-01).
Stylesheet _buildManuscriptStylesheet(BuildContext context) {
  final textColor = Theme.of(context).colorScheme.onSurface;
  final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;

  return defaultStylesheet.copyWith(
    inlineTextStyler: (attributions, existingStyle) {
      var style = defaultInlineTextStyler(attributions, existingStyle);
      // Ensure text color follows the theme (dark mode fix).
      style = style.copyWith(color: textColor, fontFamily: fontFamily);
      if (attributions.contains(aiProvenanceAttribution)) {
        style = style.copyWith(backgroundColor: provenanceColor);
      }
      return style;
    },
  );
}

/// Full-screen editor with a chapter navigation sidebar.
///
/// Wraps SuperEditor with chapter management features:
/// - Left sidebar (260px) with reorderable chapter list
/// - Document switching with forced-save guarantees (ValueKey pattern)
/// - Auto-save via ChapterAutoSave (2s debounce)
/// - Keyboard shortcuts: Ctrl+Up/Down for chapter nav, Ctrl+Shift+N for new
/// - PopScope and WidgetsBindingObserver for forced save on exit/pause
class EditorWithSidebar extends ConsumerStatefulWidget {
  const EditorWithSidebar({super.key, required this.manuscriptId});

  /// The manuscript ID whose chapters are being edited.
  final String manuscriptId;

  @override
  ConsumerState<EditorWithSidebar> createState() => _EditorWithSidebarState();
}

class _EditorWithSidebarState extends ConsumerState<EditorWithSidebar>
    with WidgetsBindingObserver {
  String? _currentChapterId;
  Editor? _editor;
  SelectionLayerLinks? _selectionLinks;
  EditListener? _editListener;
  ChapterAutoSave? _autoSave;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAutoSave();
    _loadInitialChapter();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeEditorOnly();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Per SC-4: Force save on app pause or inactive (e.g. window unfocus).
    // Flutter does not await lifecycle callbacks, so this is a best-effort
    // async save. Errors are caught and logged rather than causing an
    // unhandled async exception.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _forceSaveBestEffort();
    }
  }

  // --- Chapter & Document Management ---

  /// Pre-loads the auto-save service so it's available in dispose.
  void _loadAutoSave() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(chapterAutoSaveProvider.future).then((autoSave) {
        if (!mounted) return;
        _autoSave = autoSave;
      });
    });
  }

  /// Loads persisted chapters for the manuscript and selects the first one.
  ///
  /// Per SC-2/SC-3: Calls [ChapterNotifier.loadChapters] to fetch chapters
  /// from the repository, then loads the first chapter into the editor.
  /// ChapterNotifier.build() deliberately returns an empty list, so this
  /// explicit load is required on every editor entry.
  void _loadInitialChapter() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Always trigger loadChapters to ensure data is fresh from repository.
      // Await it before reading state because build() starts with an empty list.
      await ref
          .read(chapterNotifierProvider.notifier)
          .loadChapters(widget.manuscriptId);
      if (!mounted) return;

      // Read loaded chapter state and load first chapter if available.
      final chapters = ref.read(chapterNotifierProvider).asData?.value ?? [];
      if (chapters.isEmpty) return;
      setState(() {
        _loadChapter(chapters.first);
      });
    });
  }

  /// Loads a chapter's document content into the editor.
  void _loadChapter(Chapter chapter) {
    _cleanupEditor();

    // Deserialize chapter content to a SuperEditor document
    MutableDocument document;
    if (chapter.documentContent.isEmpty) {
      document = MutableDocument(
        nodes: [
          ParagraphNode(id: Editor.createNodeId(), text: AttributedText('')),
        ],
      );
    } else {
      try {
        document = deserializeMarkdownToDocument(chapter.documentContent);
      } catch (_) {
        // Fallback: create document with content as plain text
        document = MutableDocument(
          nodes: [
            ParagraphNode(
              id: Editor.createNodeId(),
              text: AttributedText(chapter.documentContent),
            ),
          ],
        );
      }
    }

    // Create editor with the chapter's document
    _editor = createEditorWithDocument(document);
    _selectionLinks = SelectionLayerLinks();
    _currentChapterId = chapter.id;

    // Set up auto-save edit listener
    _editListener = FunctionalEditListener((_) {
      _onDocumentChanged();
    });
    _editor!.addListener(_editListener!);

    // Expose editor via provider
    ref.read(editorProvider.notifier).setEditor(_editor);
  }

  /// Switches to a different chapter with forced save of the current one.
  Future<void> _switchChapter(String newChapterId) async {
    if (newChapterId == _currentChapterId) return;

    // Force save current chapter before switching
    await _forceSaveAsync();

    // Find the new chapter
    final chapters = ref.read(chapterNotifierProvider).asData?.value ?? [];
    final newChapter = chapters.where((c) => c.id == newChapterId).firstOrNull;
    if (newChapter == null) return;

    setState(() {
      _loadChapter(newChapter);
    });
  }

  /// Navigates to manuscript settings after forcing pending edits to persist.
  Future<void> _openSettings() async {
    await _forceSaveAsync();
    if (!mounted) return;
    context.go('/manuscript/${widget.manuscriptId}/settings');
  }

  /// Navigates to the previous chapter in the list.
  void _goToPreviousChapter() {
    final chapters = ref.read(chapterNotifierProvider).asData?.value ?? [];
    if (chapters.isEmpty || _currentChapterId == null) return;

    final currentIndex = chapters.indexWhere((c) => c.id == _currentChapterId);
    if (currentIndex > 0) {
      _switchChapter(chapters[currentIndex - 1].id);
    }
  }

  /// Navigates to the next chapter in the list.
  void _goToNextChapter() {
    final chapters = ref.read(chapterNotifierProvider).asData?.value ?? [];
    if (chapters.isEmpty || _currentChapterId == null) return;

    final currentIndex = chapters.indexWhere((c) => c.id == _currentChapterId);
    if (currentIndex < chapters.length - 1) {
      _switchChapter(chapters[currentIndex + 1].id);
    }
  }

  // --- Auto-Save ---

  /// Called when the document content changes.
  ///
  /// Serializes the current document to Markdown and triggers auto-save
  /// via ChapterAutoSave.onDocumentChanged (2s debounce).
  void _onDocumentChanged() {
    if (_editor == null || _currentChapterId == null) return;
    final markdown = serializeDocumentToMarkdown(_editor!.document);
    _autoSave?.onDocumentChanged(_currentChapterId!, markdown);
  }

  /// Forces an async save of pending changes.
  Future<void> _forceSaveAsync() async {
    if (_editor == null || _currentChapterId == null) return;
    final markdown = serializeDocumentToMarkdown(_editor!.document);
    final autoSave = _autoSave;
    if (autoSave != null) {
      autoSave.onDocumentChanged(_currentChapterId!, markdown);
      await autoSave.forceSave();
    }
  }

  /// Best-effort async save for lifecycle transitions.
  ///
  /// Per SC-4: Flutter does not await [didChangeAppLifecycleState] callbacks,
  /// so persistence cannot be guaranteed here. This fires the save and catches
  /// errors to prevent unhandled async exceptions.
  void _forceSaveBestEffort() {
    if (_editor == null || _currentChapterId == null) return;
    final markdown = serializeDocumentToMarkdown(_editor!.document);
    final autoSave = _autoSave;
    if (autoSave != null) {
      autoSave.onDocumentChanged(_currentChapterId!, markdown);
      // ignore: avoid_catching_errors
      autoSave.forceSave().catchError((_) {
        // Best-effort: log but don't crash on lifecycle save failure
        debugPrint(
          'Warning: best-effort save failed during lifecycle transition',
        );
      });
    }
  }

  /// Cleanup-only disposal path.
  ///
  /// Synchronous widget disposal cannot await [ChapterAutoSave.forceSave]. All
  /// controllable exits (chapter switch, settings, and back navigation) call
  /// [_forceSaveAsync] before cleanup; dispose only releases editor resources.
  void _disposeEditorOnly() {
    if (_editListener != null && _editor != null) {
      _editor!.removeListener(_editListener!);
    }
    // Don't use ref.read in dispose -- editor provider will be cleaned up
    // when the widget tree is torn down.
    _editor?.composer.dispose();
    _editor = null;
    _selectionLinks = null;
    _editListener = null;
  }

  /// Cleans up the current editor instance.
  void _cleanupEditor() {
    if (_editListener != null && _editor != null) {
      _editor!.removeListener(_editListener!);
    }
    if (mounted) {
      ref.read(editorProvider.notifier).setEditor(null);
    }
    _editor?.composer.dispose();
    _editor = null;
    _selectionLinks = null;
    _editListener = null;
  }

  // --- Chapter Operations ---

  /// Shows the create chapter dialog and creates the chapter on confirm.
  void _showCreateChapterDialog() {
    final chapters = ref.read(chapterNotifierProvider).asData?.value ?? [];
    final currentSortOrder = chapters.isEmpty
        ? 0
        : chapters
                  .where((c) => c.id == _currentChapterId)
                  .firstOrNull
                  ?.sortOrder ??
              chapters.last.sortOrder;

    showDialog<String>(
      context: context,
      builder: (_) => const ChapterCreateDialog(),
    ).then((title) {
      if (title == null || title.isEmpty) return;
      final now = DateTime.now();
      ref
          .read(chapterNotifierProvider.notifier)
          .add(
            Chapter(
              id: '',
              manuscriptId: widget.manuscriptId,
              title: title,
              sortOrder: currentSortOrder + 1,
              status: '草稿',
              createdAt: now,
              updatedAt: now,
            ),
          );
    });
  }

  /// Handles context menu actions for a chapter.
  void _handleContextMenuAction(Chapter chapter, ChapterAction action) {
    final notifier = ref.read(chapterNotifierProvider.notifier);
    switch (action) {
      case ChapterAction.rename:
        showDialog<String>(
          context: context,
          builder: (_) => ChapterRenameDialog(currentTitle: chapter.title),
        ).then((newTitle) {
          if (newTitle == null || newTitle.isEmpty) return;
          notifier.save(chapter.copyWith(title: newTitle));
        });
      case ChapterAction.split:
        if (_editor == null || _currentChapterId != chapter.id) return;
        _splitAtCursor(chapter);
      case ChapterAction.merge:
        _mergeWithNext(chapter);
      case ChapterAction.duplicate:
        notifier.duplicateChapter(chapter.id);
      case ChapterAction.delete:
        _confirmDeleteChapter(chapter);
    }
  }

  /// Splits the current chapter at the cursor position.
  void _splitAtCursor(Chapter chapter) {
    if (_editor == null) return;
    final selection = _editor!.composer.selection;
    if (selection == null) return;

    // Get plain text before and after cursor
    final plainText = _getDocumentPlainText(_editor!.document);
    final offset = _getSelectionOffset(selection);
    if (offset == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('只能在文本位置拆分章节')));
      return;
    }
    final before = plainText.substring(0, offset);
    final after = plainText.substring(offset);

    if (before.isEmpty && after.isEmpty) return;

    ref
        .read(chapterNotifierProvider.notifier)
        .splitChapter(chapter.id, before, after);
  }

  /// Merges the given chapter with the next one in the list.
  void _mergeWithNext(Chapter chapter) {
    final chapters = ref.read(chapterNotifierProvider).asData?.value ?? [];
    final currentIndex = chapters.indexWhere((c) => c.id == chapter.id);
    if (currentIndex < 0 || currentIndex >= chapters.length - 1) return;

    ref
        .read(chapterNotifierProvider.notifier)
        .mergeChapters(chapter.id, chapters[currentIndex + 1].id);
  }

  /// Shows a confirmation dialog before deleting a chapter.
  void _confirmDeleteChapter(Chapter chapter) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text("确定要删除章节'${chapter.title}'吗？此操作不可撤销。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true) return;
      ref.read(chapterNotifierProvider.notifier).delete(chapter.id);

      // If deleted chapter was active, switch to first remaining chapter
      if (chapter.id == _currentChapterId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final remaining =
              ref.read(chapterNotifierProvider).asData?.value ?? [];
          if (remaining.isNotEmpty) {
            _loadChapter(remaining.first);
            setState(() {});
          } else {
            _cleanupEditor();
            setState(() {
              _currentChapterId = null;
            });
          }
        });
      }
    });
  }

  // --- Helpers ---

  String _getDocumentPlainText(Document document) {
    final buffer = StringBuffer();
    for (final node in document) {
      if (node is TextNode) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(node.text.toPlainText());
      }
    }
    return buffer.toString();
  }

  int? _getSelectionOffset(DocumentSelection selection) {
    try {
      final baseOffset =
          (selection.base.nodePosition as TextNodePosition).offset;
      return baseOffset;
    } catch (_) {
      return null;
    }
  }

  /// Navigates back to the manuscript library after forced save.
  void _navigateBack() async {
    await _forceSaveAsync();
    if (mounted) {
      context.go(AppConstants.editor);
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chaptersAsync = ref.watch(chapterNotifierProvider);
    final chapters = chaptersAsync.asData?.value ?? [];

    // Compute manuscript word count for status bar
    final currentWordCount = chapters.fold<int>(
      0,
      (sum, c) => sum + c.wordCount,
    );

    // Get manuscript for title and target word count
    final manuscriptsAsync = ref.watch(manuscriptNotifierProvider);
    final manuscript = manuscriptsAsync.asData?.value
        .where((m) => m.id == widget.manuscriptId)
        .firstOrNull;
    final manuscriptTitle = manuscript?.title ?? '文稿';
    final targetWordCount = manuscript?.targetWordCount ?? 0;

    final isLastChapter =
        chapters.isEmpty || chapters.last.id == _currentChapterId;
    final hasSelection = _editor?.composer.selection != null;

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowUp):
            const _PreviousChapterIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowDown):
            const _NextChapterIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyN,
        ): const _NewChapterIntent(),
        // Preserve editor shortcuts
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
            const _BoldIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI):
            const _ItalicIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyZ,
        ): const _UndoAIIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const _QuickInsertIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PreviousChapterIntent: CallbackAction<_PreviousChapterIntent>(
            onInvoke: (_) => _goToPreviousChapter(),
          ),
          _NextChapterIntent: CallbackAction<_NextChapterIntent>(
            onInvoke: (_) => _goToNextChapter(),
          ),
          _NewChapterIntent: CallbackAction<_NewChapterIntent>(
            onInvoke: (_) => _showCreateChapterDialog(),
          ),
          _BoldIntent: CallbackAction<_BoldIntent>(
            onInvoke: (_) => _toggleBold(),
          ),
          _ItalicIntent: CallbackAction<_ItalicIntent>(
            onInvoke: (_) => _toggleItalic(),
          ),
          _UndoAIIntent: CallbackAction<_UndoAIIntent>(
            onInvoke: (_) => _undoLastAIChange(),
          ),
          _QuickInsertIntent: CallbackAction<_QuickInsertIntent>(
            onInvoke: (_) {
              // Quick insert not available in manuscript editor yet.
              return null;
            },
          ),
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _navigateBack();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: '返回文稿库',
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateBack,
              ),
              title: Text(manuscriptTitle),
              actions: [
                IconButton(
                  tooltip: '文稿设置',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: _openSettings,
                ),
              ],
            ),
            body: Row(
              children: [
                // Chapter sidebar
                ChapterSidebar(
                  manuscriptId: widget.manuscriptId,
                  manuscriptTitle: manuscriptTitle,
                  activeChapterId: _currentChapterId,
                  onChapterTap: _switchChapter,
                  onNewChapter: _showCreateChapterDialog,
                  onReorder: (manuscriptId, oldIndex, newIndex) {
                    ref
                        .read(chapterNotifierProvider.notifier)
                        .reorder(manuscriptId, oldIndex, newIndex);
                  },
                  onChapterContextMenu: (chapter) {
                    final isCurrent = chapter.id == _currentChapterId;
                    showChapterContextMenu(
                      context: context,
                      position: _getMenuPosition(chapter),
                      isSplitEnabled: isCurrent && hasSelection,
                      isMergeEnabled:
                          !isLastChapter || chapter.id != chapters.last.id,
                      onAction: (action) =>
                          _handleContextMenuAction(chapter, action),
                    );
                  },
                ),
                // Divider between sidebar and editor
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colorScheme.outline,
                ),
                // Editor area
                Expanded(
                  child: _buildEditorArea(
                    colorScheme,
                    currentWordCount,
                    targetWordCount,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the main editor area with toolbar, editor, and status bar.
  Widget _buildEditorArea(
    ColorScheme colorScheme,
    int currentWordCount,
    int targetWordCount,
  ) {
    if (_editor == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('选择或创建一个章节开始写作'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Editor toolbar
        EditorToolbar(editor: _editor!),
        const DeviationWarningWidget(),
        Divider(height: 1, thickness: 1, color: colorScheme.outline),
        // Editor content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.editorMaxWidth,
                ),
                // ValueKey forces rebuild on chapter switch (per RESEARCH.md)
                child: SuperEditor(
                  key: ValueKey(_currentChapterId),
                  editor: _editor!,
                  autofocus: true,
                  stylesheet: _buildManuscriptStylesheet(context),
                  selectionLayerLinks: _selectionLinks,
                  documentOverlayBuilders: [
                    _SelectionLeadersLayerBuilder(links: _selectionLinks!),
                    const ContextAnchorOverlayBuilder(),
                    const DiffOverlayBuilder(),
                    FunctionalSuperEditorLayerBuilder((context, editContext) {
                      return ContentLayerProxyWidget(
                        child: FloatingToolbar(
                          editor: _editor!,
                          selectionLayerLinks: _selectionLinks!,
                          manuscriptId: widget.manuscriptId,
                          chapterId: _currentChapterId,
                        ),
                      );
                    }),
                    FunctionalSuperEditorLayerBuilder((context, editContext) {
                      return ContentLayerProxyWidget(
                        child: AcceptRejectBar(
                          editor: _editor!,
                          selectionLayerLinks: _selectionLinks!,
                        ),
                      );
                    }),
                    const DefaultCaretOverlayBuilder(),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Status bar with manuscript progress
        StatusBar(
          currentWordCount: currentWordCount,
          targetWordCount: targetWordCount,
        ),
      ],
    );
  }

  /// Computes the position for a context menu relative to a chapter row.
  RelativeRect _getMenuPosition(Chapter chapter) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return const RelativeRect.fromLTRB(32, 200, 0, 0);
    }
    final size = renderBox.size;
    return RelativeRect.fromLTRB(260, 200, size.width - 260, 0);
  }

  // --- Editor Shortcuts ---

  void _toggleBold() {
    final composer = _editor?.composer;
    final selection = composer?.selection;
    if (selection == null || _editor == null) return;

    if (selection.isCollapsed) {
      composer!.preferences.toggleStyles({boldAttribution});
    } else {
      _editor!.execute([
        ToggleTextAttributionsRequest(
          documentRange: selection,
          attributions: {boldAttribution},
        ),
      ]);
    }
  }

  void _toggleItalic() {
    final composer = _editor?.composer;
    final selection = composer?.selection;
    if (selection == null || _editor == null) return;

    if (selection.isCollapsed) {
      composer!.preferences.toggleStyles({italicsAttribution});
    } else {
      _editor!.execute([
        ToggleTextAttributionsRequest(
          documentRange: selection,
          attributions: {italicsAttribution},
        ),
      ]);
    }
  }

  void _undoLastAIChange() {
    ref.read(editorAINotifierProvider.notifier).undoLastAIChange();
  }
}

// --- Keyboard shortcut intents ---

class _PreviousChapterIntent extends Intent {
  const _PreviousChapterIntent();
}

class _NextChapterIntent extends Intent {
  const _NextChapterIntent();
}

class _NewChapterIntent extends Intent {
  const _NewChapterIntent();
}

class _BoldIntent extends Intent {
  const _BoldIntent();
}

class _ItalicIntent extends Intent {
  const _ItalicIntent();
}

class _UndoAIIntent extends Intent {
  const _UndoAIIntent();
}

class _QuickInsertIntent extends Intent {
  const _QuickInsertIntent();
}

/// Layer builder that positions leader widgets at selection bounds.
///
/// Provides the [LeaderLink]s that the [FloatingToolbar] uses
/// via [Follower.withOffset] to position itself relative to the selection.
class _SelectionLeadersLayerBuilder implements SuperEditorLayerBuilder {
  const _SelectionLeadersLayerBuilder({required this.links});

  final SelectionLayerLinks links;

  @override
  ContentLayerWidget build(
    BuildContext context,
    SuperEditorContext editContext,
  ) {
    return SelectionLeadersDocumentLayer(
      document: editContext.document,
      selection: editContext.composer.selectionNotifier,
      links: links,
    );
  }
}

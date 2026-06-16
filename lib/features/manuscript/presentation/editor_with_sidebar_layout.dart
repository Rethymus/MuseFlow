part of 'editor_with_sidebar.dart';

/// Layout helpers for [_EditorWithSidebarState].
///
/// Extracted from editor_with_sidebar.dart to satisfy the
/// 03-flutter-standards.md file-size cap. Dart does not allow splitting a
/// single State class body across files, so the desktop/mobile/editor-area
/// builders live in this private extension. The state's [build] method
/// invokes them via bare names — Dart resolves same-library extension-on-this
/// members transparently, so call sites are unchanged.
extension _EditorWithSidebarStateLayout on _EditorWithSidebarState {
  /// Desktop layout: sidebar + divider + editor in a Row.
  Widget _buildDesktopLayout({
    required ColorScheme colorScheme,
    required String manuscriptTitle,
    required List<Chapter> chapters,
    required int currentWordCount,
    required int targetWordCount,
    required bool hasSelection,
  }) {
    final isLastChapter =
        chapters.isEmpty || _currentChapterId == chapters.last.id;
    return Row(
      children: [
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
              isMergeEnabled: !isLastChapter || chapter.id != chapters.last.id,
              onAction: (action) => _handleContextMenuAction(chapter, action),
            );
          },
        ),
        VerticalDivider(width: 1, thickness: 1, color: colorScheme.outline),
        Expanded(
          child: _buildEditorArea(
            colorScheme,
            currentWordCount,
            targetWordCount,
          ),
        ),
      ],
    );
  }

  /// Mobile layout: editor with drawer for chapter navigation.
  Widget _buildMobileLayout({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String manuscriptTitle,
    required List<Chapter> chapters,
    required int currentWordCount,
    required int targetWordCount,
    required bool hasSelection,
  }) {
    final isLastChapter =
        chapters.isEmpty || _currentChapterId == chapters.last.id;
    return Scaffold(
      drawer: Drawer(
        child: ChapterSidebar(
          manuscriptId: widget.manuscriptId,
          manuscriptTitle: manuscriptTitle,
          activeChapterId: _currentChapterId,
          onChapterTap: (chapter) {
            _switchChapter(chapter);
            Navigator.of(context).pop(); // close drawer
          },
          onNewChapter: () {
            Navigator.of(context).pop();
            _showCreateChapterDialog();
          },
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
              isMergeEnabled: !isLastChapter || chapter.id != chapters.last.id,
              onAction: (action) => _handleContextMenuAction(chapter, action),
            );
          },
        ),
      ),
      body: _buildEditorArea(colorScheme, currentWordCount, targetWordCount),
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
        const StyleThermometerCard(),
        const ForeshadowingReminderWidget(),
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
}

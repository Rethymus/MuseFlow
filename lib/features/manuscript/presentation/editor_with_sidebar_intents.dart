part of 'editor_with_sidebar.dart';

/// Manuscript stylesheet, keyboard shortcut intents, and selection-leaders
/// layer builder.
///
/// Extracted from editor_with_sidebar.dart to satisfy the
/// 03-flutter-standards.md file-size cap. All symbols live in the same
/// library — the state class and build tree reference them via bare names
/// unchanged.

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

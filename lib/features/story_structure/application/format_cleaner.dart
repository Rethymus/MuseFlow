library;

import 'package:museflow/features/story_structure/domain/format_clean_result.dart';

part 'format_cleaner_punctuation.dart';
part 'format_cleaner_markdown.dart';
part 'format_cleaner_whitespace.dart';

/// Options controlling which format cleanup passes are active.
class FormatCleanOptions {
  final bool normalizePunctuation;
  final bool cleanMarkdown;
  final bool normalizeWhitespace;
  final bool normalizeIndentation;
  final bool normalizeParagraphSpacing;

  const FormatCleanOptions({
    this.normalizePunctuation = true,
    this.cleanMarkdown = true,
    this.normalizeWhitespace = true,
    this.normalizeIndentation = true,
    this.normalizeParagraphSpacing = true,
  });
}

/// Deterministic format cleaner for manuscript finishing.
///
/// Applies a series of passes to normalize Chinese punctuation, clean Markdown
/// residuals, normalize whitespace and indentation, and fix paragraph spacing.
/// Each pass is conservative and designed to avoid corrupting URLs, decimal
/// numbers, file paths, model names, and code-like snippets.
///
/// Returns a [FormatCleanResult] with structured changes for preview.
/// Does NOT mutate any text before explicit user confirmation.
class FormatCleaner {
  const FormatCleaner();

  /// Runs all enabled cleanup passes on [text] and returns a structured result.
  FormatCleanResult clean(String text, {FormatCleanOptions? options}) {
    options ??= const FormatCleanOptions();
    final changes = <FormatChange>[];
    var current = text;

    if (options.normalizeWhitespace) {
      current = _normalizeLineEndings(current, changes);
      current = _trimTrailingWhitespace(current, changes);
    }

    if (options.normalizePunctuation) {
      current = _normalizePunctuation(current, changes);
    }

    if (options.cleanMarkdown) {
      current = _cleanMarkdownHeadings(current, changes);
      current = _cleanMarkdownLists(current, changes);
      current = _cleanMarkdownCodeFences(current, changes);
      current = _cleanMarkdownEmphasis(current, changes);
      current = _cleanHtmlTags(current, changes);
    }

    if (options.normalizeParagraphSpacing) {
      current = _collapseBlankLines(current, changes);
    }

    return FormatCleanResult(
      originalText: text,
      cleanedText: current,
      changes: changes,
    );
  }
}

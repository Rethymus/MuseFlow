import 'package:flutter/material.dart';
import 'package:museflow/features/story_structure/application/format_cleaner.dart';
import 'package:museflow/features/story_structure/domain/format_clean_result.dart';

/// Dialog for previewing format cleanup changes before applying them.
///
/// Per T-05-06 and D-14: Shows a preview/diff of deterministic cleanup changes
/// grouped by category. The manuscript is NOT mutated until the author
/// explicitly taps "Apply cleanup".
///
/// Flow:
/// 1. Author selects scope (current chapter or whole manuscript)
/// 2. Taps "Preview cleanup" to generate the diff
/// 3. Reviews changes grouped by category
/// 4. Confirms "Apply cleanup" to apply, or "Cancel" to discard
class FormatCleanPreviewDialog extends StatefulWidget {
  /// The original text to be cleaned.
  final String originalText;

  /// Callback invoked with cleaned text only after explicit confirmation.
  final void Function(String cleanedText) onApply;

  const FormatCleanPreviewDialog({
    super.key,
    required this.originalText,
    required this.onApply,
  });

  @override
  State<FormatCleanPreviewDialog> createState() =>
      _FormatCleanPreviewDialogState();
}

class _FormatCleanPreviewDialogState extends State<FormatCleanPreviewDialog> {
  FormatCleanResult? _result;
  bool _isGenerating = false;

  static const _cleaner = FormatCleaner();

  void _generatePreview() {
    setState(() {
      _isGenerating = true;
    });

    // Format cleaning is deterministic and synchronous
    final result = _cleaner.clean(widget.originalText);

    setState(() {
      _result = result;
      _isGenerating = false;
    });
  }

  void _apply() {
    if (_result == null) return;
    widget.onApply(_result!.cleanedText);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('格式清理预览'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info text
            Text(
              '先预览清理结果，确认后才会修改正文。',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Preview button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _generatePreview,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.preview),
                label: Text(_isGenerating ? '生成预览中...' : '预览清理'),
              ),
            ),
            const SizedBox(height: 16),

            // Preview result area
            if (_result != null) ...[
              // Summary strip
              _buildSummaryStrip(_result!, colorScheme),
              const SizedBox(height: 12),

              // Changes grouped by category
              Expanded(
                child: _result!.hasChanges
                    ? _buildChangesList(_result!)
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 48),
                            SizedBox(height: 8),
                            Text('文本已经是干净的，无需修改。'),
                          ],
                        ),
                      ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Text(
                    '点击"预览清理"查看修改预览',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _result != null ? _apply : null,
          child: const Text('确认应用'),
        ),
      ],
    );
  }

  Widget _buildSummaryStrip(
      FormatCleanResult result, ColorScheme colorScheme) {
    final categories = <FormatChangeCategory>{};
    for (final change in result.changes) {
      categories.add(change.category);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '${result.changes.length} 处修改',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(_categoryLabel(cat)),
                  visualDensity: VisualDensity.compact,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildChangesList(FormatCleanResult result) {
    // Group changes by category
    final grouped = <FormatChangeCategory, List<FormatChange>>{};
    for (final change in result.changes) {
      grouped.putIfAbsent(change.category, () => []).add(change);
    }

    return ListView(
      children: grouped.entries.map((entry) {
        return ExpansionTile(
          title: Text(_categoryLabel(entry.key)),
          subtitle: Text('${entry.value.length} 处'),
          initiallyExpanded: true,
          children: entry.value.map((change) {
            return ListTile(
              dense: true,
              title: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: change.original,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.red,
                      ),
                    ),
                    TextSpan(text: ' → '),
                    TextSpan(
                      text: change.replacement,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              subtitle: Text(
                change.explanation,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  String _categoryLabel(FormatChangeCategory category) {
    return switch (category) {
      FormatChangeCategory.punctuation => '标点修正',
      FormatChangeCategory.markdown => 'Markdown 清理',
      FormatChangeCategory.whitespace => '空白修正',
      FormatChangeCategory.indentation => '缩进修正',
      FormatChangeCategory.paragraph => '段落间距',
    };
  }
}

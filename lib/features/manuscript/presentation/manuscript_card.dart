import 'package:flutter/material.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/domain/manuscript_genre.dart';

/// A card widget displaying a manuscript summary in the library grid.
///
/// Shows genre-colored cover area with cover letter, title, word count
/// progress bar, status badge, and last-edited timestamp.
/// Supports tap to navigate and long-press for context menu.
class ManuscriptCard extends StatelessWidget {
  const ManuscriptCard({
    super.key,
    required this.manuscript,
    this.currentWordCount = 0,
    required this.onTap,
    this.onEditInfo,
    this.onDelete,
  });

  final Manuscript manuscript;

  /// Current total word count across all chapters.
  final int currentWordCount;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Callback for "编辑信息" context menu action.
  final VoidCallback? onEditInfo;

  /// Callback for "删除" context menu action.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: _showContextMenu,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCoverArea(colorScheme),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      manuscript.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Word count + progress bar
                    _buildProgressBar(theme, colorScheme),
                    const Spacer(),
                    // Status badge + timestamp
                    _buildBottomRow(theme, colorScheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverArea(ColorScheme colorScheme) {
    final effectiveLetter = manuscript.coverLetter.isNotEmpty
        ? manuscript.coverLetter
        : manuscript.title.substring(0, manuscript.title.length.clamp(0, 2));
    final genreColor = Color(ManuscriptGenre.genreColor(manuscript.genre));

    return Container(
      height: 80,
      color: genreColor,
      alignment: Alignment.center,
      child: Text(
        effectiveLetter,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, ColorScheme colorScheme) {
    final progress = manuscript.targetWordCount > 0
        ? (currentWordCount / manuscript.targetWordCount).clamp(0.0, 1.0)
        : 0.0;
    final formattedCurrent = _formatNumber(currentWordCount);
    final formattedTarget = _formatNumber(manuscript.targetWordCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$formattedCurrent / $formattedTarget 字',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          minHeight: 4,
          backgroundColor: colorScheme.surfaceContainerLow,
          valueColor: AlwaysStoppedAnimation(colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildBottomRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        _StatusBadge(status: manuscript.status),
        const Spacer(),
        Text(
          _relativeTime(manuscript.updatedAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showContextMenu() {
    // Context menu is shown via PopupMenuButton in the parent
    // or via GestureDetector onLongPress in the card container.
    // For now, the parent page handles this by wrapping in GestureDetector.
    // This is a placeholder that could be expanded.
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${dateTime.month}月${dateTime.day}日';
  }
}

/// A pill-shaped badge showing manuscript status with appropriate color.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (bgColor, textColor) = _statusColors(colorScheme);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  (Color, Color) _statusColors(ColorScheme colorScheme) {
    return switch (status) {
      '构思中' => (colorScheme.surfaceContainerLow, colorScheme.onSurfaceVariant),
      '写作中' => (colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
      '已完成' => (colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
      _ => (colorScheme.surfaceContainerLow, colorScheme.onSurfaceVariant),
    };
  }
}

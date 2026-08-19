import 'package:flutter/material.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/theme/app_dimens.dart';

/// A single row in the chapter sidebar list.
///
/// Displays the chapter title (left-aligned) and word count (right-aligned).
/// When [isActive] is true, the row gets the macOS selection pill: a tinted
/// rounded background with a bolder title.
class ChapterSidebarRow extends StatelessWidget {
  const ChapterSidebarRow({
    super.key,
    required this.chapter,
    required this.isActive,
    required this.onTap,
  });

  /// The chapter to display.
  final Chapter chapter;

  /// Whether this chapter is the currently active (selected) chapter.
  final bool isActive;

  /// Called when the user taps this row.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? p.accentFill : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                chapter.title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? p.label : p.secondaryLabel,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${chapter.wordCount}',
              style: textTheme.labelMedium?.copyWith(color: p.tertiaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

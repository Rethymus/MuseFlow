import 'package:flutter/material.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';

/// A single row in the chapter sidebar list.
///
/// Displays the chapter title (left-aligned) and word count (right-aligned).
/// When [isActive] is true, the row gets a highlighted background and bolder title.
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
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                chapter.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${chapter.wordCount}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

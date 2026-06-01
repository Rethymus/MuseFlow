import 'package:flutter/material.dart';
import 'package:museflow/core/domain/fragment.dart';

/// A card displaying a single fragment with checkbox, text, tags, and timestamp.
///
/// Per UI-SPEC:
/// - Card with elevation 0, surfaceContainerHighest background
/// - Row: Checkbox | Text + Tags (Expanded) | Timestamp
/// - Text: body style 14px, maxLines 3, ellipsis overflow
/// - Tags: Wrap of Chip widgets, 12px label style
/// - Timestamp: label style 12px, onSurfaceVariant color, yyyy-MM-dd HH:mm
class FragmentCard extends StatelessWidget {
  final Fragment fragment;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback? onTap;

  const FragmentCard({
    super.key,
    required this.fragment,
    required this.isSelected,
    required this.onToggleSelect,
    this.onTap,
  });

  /// Formats a DateTime as 'yyyy-MM-dd HH:mm' without the intl package.
  static String _formatTimestamp(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox for multi-select (per D-10)
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelect(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 12),

              // Fragment text + tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fragment text
                    Text(
                      fragment.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (fragment.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      // Tag chips
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: fragment.tags.map((tag) {
                          return Chip(
                            label: Text(
                              tag,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Timestamp
              Text(
                _formatTimestamp(fragment.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/theme/app_dimens.dart';

/// A card displaying a single fragment with checkbox, text, tags, and
/// timestamp, on the iOS inset-group card.
///
/// - Flat white card on the grouped gray page, 12pt corners
/// - Row: Checkbox | Text + Tags (Expanded) | Timestamp
/// - Text: body style, maxLines 3, ellipsis overflow
/// - Tags: tinted gray pills, caption2 label
/// - Timestamp: tertiaryLabel caption2, yyyy-MM-dd HH:mm
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
    final p = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageMargin,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: p.cardBackground,
        borderRadius: AppRadius.rMedium,
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: AppRadius.rMedium),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox for multi-select (per D-10)
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelect(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),

              // Fragment text + tags
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fragment text
                      Text(
                        fragment.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: p.label,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (fragment.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        // Tag pills
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: fragment.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: p.gray5,
                                borderRadius: AppRadius.pill,
                              ),
                              child: Text(
                                tag,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: p.secondaryLabel,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Timestamp
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _formatTimestamp(fragment.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: p.tertiaryLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

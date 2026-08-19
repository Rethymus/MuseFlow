import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:museflow/shared/theme/app_colors.dart';

/// Reusable navigation card for the Reports Hub page.
///
/// Displays an icon, title, description, and trailing chevron.
/// Follows the visual pattern of StatsSummaryCard but with a
/// horizontal layout: icon left, text center, chevron right.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  /// Leading icon for the report type.
  final IconData icon;

  /// Report card title.
  final String title;

  /// Report card description.
  final String description;

  /// Callback when card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final p = AppColors.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: p.accent, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: p.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 15,
                color: p.tertiaryLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/theme/app_dimens.dart';
import 'package:museflow/shared/widgets/app_card.dart';

/// A metric tile on an Apple inset-group card: tinted icon chip, secondary
/// label title and a large bold value.
class StatsSummaryCard extends StatelessWidget {
  const StatsSummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppColors.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: p.accentFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: p.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: p.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

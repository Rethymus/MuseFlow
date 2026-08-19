/// AppCard — the iOS "inset grouped" surface for MuseFlow.
///
/// A flat card (`secondarySystemGroupedBackground`) sitting on the grouped
/// gray page background, 12pt corners, no elevation or shadow — hierarchy
/// comes from the layered backgrounds, per Apple HIG "Deference".
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// A flat content card used across list and grid layouts.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.radius = AppRadius.medium,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? p.cardBackground,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null && onLongPress == null) return card;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: card,
    );
  }
}

/// AppTabBar — the iOS-style frosted bottom tab bar.
///
/// Replaces Material's NavigationBar: 50pt tall (plus safe area), frosted
/// grouped background with a hairline top edge, tinted active icon + 10pt
/// label. Five destinations max, per Apple HIG.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_materials.dart';
import 'app_pressable.dart';
import 'app_sidebar.dart';

/// iOS-style bottom tab bar with a blurred translucent background.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    this.scrollEdge,
  });

  /// Index of the selected tab (named after NavigationBar's contract).
  final int selectedIndex;

  final List<AppSidebarDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  /// Optional scroll-edge intensity; strengthens the frost while content
  /// scrolls beneath (HIG scroll edge effect).
  final AppScrollEdge? scrollEdge;

  static const double barHeight = 50;

  @override
  Widget build(BuildContext context) {
    return AppMaterial(
      tier: AppMaterialTier.ultraThin,
      radius: BorderRadius.zero,
      borderEdges: const {LogicalEdge.top},
      scrollEdge: scrollEdge,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _TabItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onDestinationSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppSidebarDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final icon = selected
        ? (destination.selectedIcon ?? destination.icon)
        : destination.icon;
    final tint = selected ? p.accent : p.gray;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: AppPressable(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: tint),
            const SizedBox(height: 2),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 10,
                height: 1.0,
                color: tint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

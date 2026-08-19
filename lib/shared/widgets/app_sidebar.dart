/// AppSidebar — the macOS-style translucent sidebar.
///
/// Replaces Material's NavigationRail as MuseFlow's desktop chrome: a
/// slightly-tinted material column with the app title on top, icon+label
/// destinations, and the signature macOS selection pill (rounded-rect
/// tinted with the app accent). A hairline separates it from content.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_materials.dart';

/// One sidebar destination (icon + label).
class AppSidebarDestination {
  const AppSidebarDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
}

/// macOS-style sidebar navigation.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    this.extended = true,
    this.title = '灵韵',
  });

  /// Index of the selected destination (named after NavigationRail's field
  /// so call sites and tests read the same).
  final int selectedIndex;

  /// When false, renders the icon-only compact column (~68px).
  final bool extended;

  final List<AppSidebarDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  /// App wordmark shown at the top; pass empty string to hide.
  final String title;

  static const double extendedWidth = 212;
  static const double collapsedWidth = 68;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = extended ? extendedWidth : collapsedWidth;

    return SizedBox(
      width: width,
      child: AppMaterial(
        tier: AppMaterialTier.thin,
        radius: BorderRadius.zero,
        borderEdges: const {LogicalEdge.right},
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.headlineMedium,
                  ),
                ),
              ],
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      _SidebarItem(
                        destination: destinations[i],
                        selected: i == selectedIndex,
                        extended: extended,
                        onTap: () => onDestinationSelected(i),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final AppSidebarDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  static const double height = 38;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final icon = selected
        ? (destination.selectedIcon ?? destination.icon)
        : destination.icon;
    final tint = selected ? p.accent : p.secondaryLabel;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: extended ? 10 : 0),
          decoration: BoxDecoration(
            color: selected ? p.accentFill : null,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Row(
            mainAxisAlignment: extended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21, color: tint),
              if (extended) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? p.label : p.secondaryLabel,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

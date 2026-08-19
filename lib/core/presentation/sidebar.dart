import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:museflow/shared/widgets/app_sidebar.dart';
import 'package:museflow/shared/widgets/app_tab_bar.dart';

/// Adaptive navigation chrome, Apple style.
///
/// Desktop (>= [AppConstants.sidebarCollapsedBreakpoint]): the macOS-style
/// [AppSidebar] — icon+label destinations on a tinted material column,
/// icon-only between 600–1000px, extended above 1000px.
///
/// Narrow: the iOS-style frosted [AppTabBar] with the 5 primary
/// destinations; Material's 5-destination cap moves 设置 to the library
/// AppBar gear action on narrow layouts (HF-3).
class AdaptiveSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdaptiveSidebar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  /// All six desktop destinations (capture, editor, knowledge, structure,
  /// stats, settings).
  static const List<AppSidebarDestination> destinations = [
    AppSidebarDestination(icon: CupertinoIcons.bookmark, label: '捕捉器'),
    AppSidebarDestination(icon: CupertinoIcons.pen, label: '编辑器'),
    AppSidebarDestination(icon: CupertinoIcons.book, label: '知识库'),
    AppSidebarDestination(icon: CupertinoIcons.graph_circle, label: '故事结构'),
    AppSidebarDestination(icon: CupertinoIcons.chart_bar, label: '统计'),
    AppSidebarDestination(icon: CupertinoIcons.gear, label: '设置'),
  ];

  /// The 5 primary destinations shown in the bottom tab bar.
  static final List<AppSidebarDestination> primaryDestinations = destinations
      .take(5)
      .toList();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Below collapsed breakpoint: iOS bottom tab bar (phone portrait).
    if (screenWidth < AppConstants.sidebarCollapsedBreakpoint) {
      return AppTabBar(
        selectedIndex: currentIndex.clamp(0, primaryDestinations.length - 1),
        destinations: primaryDestinations,
        onDestinationSelected: onDestinationSelected,
      );
    }

    // Desktop: macOS sidebar, icon-only until the extended breakpoint.
    final isExtended = screenWidth >= AppConstants.sidebarExtendedBreakpoint;

    return AppSidebar(
      selectedIndex: currentIndex,
      destinations: destinations,
      onDestinationSelected: onDestinationSelected,
      extended: isExtended,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/sidebar.dart';
import 'package:museflow/shared/constants/app_constants.dart';

/// Main app shell with sidebar + content area layout.
///
/// Wraps the [StatefulNavigationShell] with an adaptive sidebar.
/// The sidebar uses [NavigationRail] on desktop and [NavigationBar] on mobile.
class AppShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < AppConstants.sidebarCollapsedBreakpoint;

    if (isNarrow) {
      // Mobile layout: bottom nav bar + content
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: AdaptiveSidebar(
          currentIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        ),
      );
    }

    // Desktop layout: sidebar + content in Row
    return Scaffold(
      body: Row(
        children: [
          AdaptiveSidebar(
            currentIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

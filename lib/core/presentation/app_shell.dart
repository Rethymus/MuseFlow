import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/core/presentation/sidebar.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:museflow/shared/utils/keyboard_shortcuts.dart';
import 'package:window_manager/window_manager.dart';

/// Main app shell with sidebar + content area layout.
///
/// Wraps the [StatefulNavigationShell] with an adaptive sidebar.
/// The sidebar uses [NavigationRail] on desktop and [NavigationBar] on mobile.
///
/// Also implements [WindowListener] to persist window geometry (size and
/// position) to the encrypted settings box on resize/move events, debounced
/// to avoid excessive writes.
class AppShellScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends ConsumerState<AppShellScaffold>
    with WindowListener {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowResize() => _scheduleSaveGeometry();

  @override
  void onWindowMove() => _scheduleSaveGeometry();

  /// Debounced save — coalesces rapid resize/move events into a single write.
  void _scheduleSaveGeometry() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _saveGeometry);
  }

  Future<void> _saveGeometry() async {
    final settingsAsync = ref.read(settingsRepositoryProvider);
    final settings = settingsAsync.value;
    if (settings == null) return;

    try {
      final size = await windowManager.getSize();
      await settings.saveWindowSize(size);

      final position = await windowManager.getPosition();
      await settings.saveWindowPosition(position);
    } catch (_) {
      // Window geometry persistence is non-critical; don't crash the app.
      debugPrint('Warning: failed to persist window geometry');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < AppConstants.sidebarCollapsedBreakpoint;

    if (isNarrow) {
      // Mobile layout: bottom nav bar + content
      return QuickCaptureShortcut(
        child: Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: AdaptiveSidebar(
            currentIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: (index) {
              widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              );
            },
          ),
        ),
      );
    }

    // Desktop layout: sidebar + content in Row
    return QuickCaptureShortcut(
      child: Scaffold(
        body: Row(
          children: [
            AdaptiveSidebar(
              currentIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: (index) {
                widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == widget.navigationShell.currentIndex,
                );
              },
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: widget.navigationShell),
          ],
        ),
      ),
    );
  }
}

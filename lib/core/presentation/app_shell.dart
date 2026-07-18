import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/infrastructure/settings_repository.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/core/platform/window_controller.dart';
import 'package:museflow/core/presentation/sidebar.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:museflow/shared/utils/keyboard_shortcuts.dart';

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

class _AppShellScaffoldState extends ConsumerState<AppShellScaffold> {
  Timer? _debounce;
  late final PlatformWindowController _windowController;

  @override
  void initState() {
    super.initState();
    _windowController = PlatformWindowController(
      onGeometryChanged: _scheduleSaveGeometry,
    );
    _windowController.attach();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _windowController.detach();
    super.dispose();
  }

  void onWindowResize() => _scheduleSaveGeometry();

  void onWindowMove() => _scheduleSaveGeometry();

  /// Debounced save — coalesces rapid resize/move events into a single write.
  void _scheduleSaveGeometry() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _saveGeometry);
  }

  Future<SettingsRepository?> _readSettingsForGeometrySave() async {
    final settingsAsync = ref.read(settingsRepositoryProvider);
    return settingsAsync.value;
  }

  Future<void> _saveGeometry() async {
    final settings = await _readSettingsForGeometrySave();
    if (settings == null) return;

    try {
      await savePlatformWindowGeometry(settings);
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
          body: _withWebBackupReminder(widget.navigationShell),
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
            Expanded(child: _withWebBackupReminder(widget.navigationShell)),
          ],
        ),
      ),
    );
  }

  Widget _withWebBackupReminder(Widget child) {
    if (!kIsWeb) return child;

    final manuscripts = ref.watch(manuscriptNotifierProvider).value ?? const [];
    final settings = ref.watch(settingsRepositoryProvider).value;
    final lastBackupAt = settings?.getLastBrowserBackupAt();
    final backupDue =
        manuscripts.isNotEmpty &&
        (lastBackupAt == null ||
            DateTime.now().difference(lastBackupAt).inDays >= 7);
    if (!backupDue) return child;

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.backup_outlined),
                const SizedBox(width: 12),
                const Expanded(child: Text('浏览器数据可能被清理，请及时导出作品备份。')),
                TextButton(
                  onPressed: () => context.go(AppConstants.settings),
                  child: const Text('前往备份'),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

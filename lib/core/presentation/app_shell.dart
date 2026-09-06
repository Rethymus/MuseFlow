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
import 'package:museflow/shared/theme/app_materials.dart';
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
  final AppScrollEdge _scrollEdge = AppScrollEdge();
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
      // Mobile layout: bottom nav bar + content. extendBody lets content
      // scroll under the frosted tab bar so the blur samples real pixels;
      // the transparent scaffold lets the ambient canvas show through
      // wherever the page does not paint.
      return QuickCaptureShortcut(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: NotificationListener<ScrollNotification>(
            onNotification: _updateScrollEdge,
            child: _withWebBackupReminder(widget.navigationShell),
          ),
          bottomNavigationBar: AdaptiveSidebar(
            scrollEdge: _scrollEdge,
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

    // Desktop layout: sidebar + content in Row. The scaffold stays
    // transparent so the sidebar's glass samples the ambient canvas
    // (macOS sidebar behavior: depth comes from what is behind the
    // window, not from the content column).
    return QuickCaptureShortcut(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            AdaptiveSidebar(
              scrollEdge: _scrollEdge,
              currentIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: (index) {
                widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == widget.navigationShell.currentIndex,
                );
              },
            ),
            // The sidebar draws its own hairline right border.
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _updateScrollEdge,
                child: _withWebBackupReminder(widget.navigationShell),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _updateScrollEdge(ScrollNotification n) {
    _scrollEdge.updateFromOffset(n.metrics.pixels);
    return false;
  }

  Widget _withWebBackupReminder(Widget child) {
    if (!kIsWeb) return child;

    final manuscripts = ref.watch(manuscriptNotifierProvider).value ?? const [];
    final settings = ref.watch(settingsRepositoryProvider).value;
    if (settings == null) return child;
    // HF-4: a permanent, undismissable banner taxes every page load and
    // breaks writing focus. Snooze it for 7 days after an explicit dismiss.
    if (settings.isBackupBannerSnoozed()) return child;

    final lastBackupAt = settings.getLastBrowserBackupAt();
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.backup_outlined, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '浏览器数据可能被清理，请及时导出作品备份。',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppConstants.settings),
                  child: const Text('前往备份'),
                ),
                IconButton(
                  tooltip: '7 天内不再提醒',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    settings.snoozeBackupBanner();
                    // Re-evaluate the snooze state on the next build.
                    ref.invalidate(settingsRepositoryProvider);
                  },
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

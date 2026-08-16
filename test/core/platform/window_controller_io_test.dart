import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/infrastructure/settings_repository.dart';
import 'package:museflow/core/platform/window_controller_io.dart';

/// Guards for the desktop-only window_manager boundary.
///
/// window_manager 0.5.1 has no Android/iOS plugin registration, so any channel
/// call there throws MissingPluginException — historically this crashed
/// `main()` before `runApp` on Android release builds. The tests inject
/// `supportsWindowManager: () => false` to emulate a mobile platform;
/// flutter_test registers no window_manager plugin either, so a broken guard
/// that let the call through would throw and fail the test.
void main() {
  Directory? tempDir;

  tearDown(() async {
    // Close boxes BEFORE deleting the directory: Windows refuses to delete
    // files that are still open (errno 32), unlike Linux.
    await Hive.close();
    final dir = tempDir;
    tempDir = null;
    if (dir != null && await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('configurePlatformWindow is a no-op on unsupported platforms', () async {
    await configurePlatformWindow(
      savedSize: null,
      savedPosition: null,
      supportsWindowManager: () => false,
    );
  });

  test(
    'savePlatformWindowGeometry is a no-op on unsupported platforms',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'museflow_window_guard_test_',
      );
      tempDir = dir;
      Hive.init(dir.path);
      final repo = SettingsRepository(await Hive.openBox<dynamic>('settings'));

      await savePlatformWindowGeometry(
        repo,
        supportsWindowManager: () => false,
      );

      expect(
        repo.getWindowSize(),
        isNull,
        reason: 'mobile platforms must never query windowManager.getSize()',
      );
    },
  );

  test(
    'PlatformWindowController attach/detach skip windowManager when unsupported',
    () {
      var geometryChanged = false;
      final controller = PlatformWindowController(
        onGeometryChanged: () => geometryChanged = true,
        supportsWindowManager: () => false,
      );

      controller.attach();
      controller.detach();

      expect(geometryChanged, isFalse);
    },
  );
}

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:museflow/core/infrastructure/settings_repository.dart';
import 'package:window_manager/window_manager.dart';

/// Whether the current platform has a window_manager implementation.
///
/// window_manager 0.5.1 ships Windows/macOS/Linux plugins ONLY — there is no
/// Android/iOS registration, so any channel call there throws
/// [MissingPluginException]. Before this guard, `main()` awaited
/// `ensureInitialized()` on every non-Web platform and the exception killed
/// startup before `runApp` (Android release builds installed fine but crashed
/// on launch). Mobile platforms fall through as no-ops, mirroring the Web stub
/// in window_controller_web.dart.
///
/// Exposed as a standalone function (and injectable via `supportsWindowManager`
/// parameters) so unit tests can exercise the guard without faking
/// [Platform.isX] statics.
bool defaultSupportsWindowManager() =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

class PlatformWindowController with WindowListener {
  PlatformWindowController({
    required this.onGeometryChanged,
    bool Function()? supportsWindowManager,
  }) : _supportsWindowManager =
           supportsWindowManager ?? defaultSupportsWindowManager;

  final VoidCallback onGeometryChanged;
  final bool Function() _supportsWindowManager;

  void attach() {
    if (!_supportsWindowManager()) return;
    windowManager.addListener(this);
  }

  void detach() {
    if (!_supportsWindowManager()) return;
    windowManager.removeListener(this);
  }

  @override
  void onWindowResize() {
    onGeometryChanged();
  }

  @override
  void onWindowMove() {
    onGeometryChanged();
  }
}

Future<void> configurePlatformWindow({
  required Size? savedSize,
  required Offset? savedPosition,
  bool Function()? supportsWindowManager,
}) async {
  final supported = (supportsWindowManager ?? defaultSupportsWindowManager)();
  if (!supported) return;

  try {
    await WindowManager.instance.ensureInitialized();
  } on MissingPluginException {
    // Defensive: a desktop platform where the plugin failed to register
    // (e.g. stripped runner). Window setup is optional — never block startup.
    return;
  }
  windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: savedSize ?? const Size(1200, 800),
      minimumSize: const Size(800, 600),
      center: savedPosition == null,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'MuseFlow 灵韵',
    ),
    () async {
      if (savedPosition != null) {
        await windowManager.setPosition(savedPosition);
      }
      await windowManager.show();
      await windowManager.focus();
    },
  );
}

Future<void> savePlatformWindowGeometry(
  SettingsRepository settings, {
  bool Function()? supportsWindowManager,
}) async {
  final supported = (supportsWindowManager ?? defaultSupportsWindowManager)();
  if (!supported) return;

  final size = await windowManager.getSize();
  await settings.saveWindowSize(size);

  final position = await windowManager.getPosition();
  await settings.saveWindowPosition(position);
}

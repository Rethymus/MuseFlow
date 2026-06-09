import 'package:flutter/material.dart';
import 'package:museflow/core/infrastructure/settings_repository.dart';
import 'package:window_manager/window_manager.dart';

class PlatformWindowController with WindowListener {
  PlatformWindowController({required this.onGeometryChanged});

  final VoidCallback onGeometryChanged;

  void attach() {
    windowManager.addListener(this);
  }

  void detach() {
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
}) async {
  await WindowManager.instance.ensureInitialized();
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

Future<void> savePlatformWindowGeometry(SettingsRepository settings) async {
  final size = await windowManager.getSize();
  await settings.saveWindowSize(size);

  final position = await windowManager.getPosition();
  await settings.saveWindowPosition(position);
}

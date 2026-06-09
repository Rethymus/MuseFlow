import 'package:flutter/material.dart';
import 'package:museflow/core/infrastructure/settings_repository.dart';

class PlatformWindowController {
  PlatformWindowController({required this.onGeometryChanged});

  final VoidCallback onGeometryChanged;

  void attach() {}

  void detach() {}
}

Future<void> configurePlatformWindow({
  required Size? savedSize,
  required Offset? savedPosition,
}) async {}

Future<void> savePlatformWindowGeometry(SettingsRepository settings) async {}

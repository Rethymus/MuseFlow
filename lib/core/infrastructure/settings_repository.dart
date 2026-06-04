import 'dart:ui';

import 'package:hive_ce/hive.dart';
import 'package:museflow/core/domain/fragment_tag.dart';

/// Repository for managing application settings in an encrypted Hive box.
///
/// Persists window geometry (size, position) and user preferences.
class SettingsRepository {
  final Box<dynamic> _box;

  static const String _windowSizeKey = 'windowSize';
  static const String _windowPositionKey = 'windowPosition';
  static const String _defaultTagKey = 'defaultTag';

  SettingsRepository(this._box);

  /// Saves the window size to the encrypted settings box.
  Future<void> saveWindowSize(Size size) async {
    await _box.put(_windowSizeKey, {
      'width': size.width,
      'height': size.height,
    });
  }

  /// Retrieves the persisted window size, or null if not set.
  Size? getWindowSize() {
    final data = _box.get(_windowSizeKey);
    if (data == null) return null;
    return Size(data['width'] as double, data['height'] as double);
  }

  /// Saves the window position to the encrypted settings box.
  Future<void> saveWindowPosition(Offset position) async {
    await _box.put(_windowPositionKey, {
      'x': position.dx,
      'y': position.dy,
    });
  }

  /// Retrieves the persisted window position, or null if not set.
  Offset? getWindowPosition() {
    final data = _box.get(_windowPositionKey);
    if (data == null) return null;
    return Offset(data['x'] as double, data['y'] as double);
  }

  /// Gets the default fragment tag for quick capture.
  String getDefaultTag() {
    return _box.get(_defaultTagKey, defaultValue: FragmentTags.story) as String;
  }

  /// Sets the default fragment tag for quick capture.
  Future<void> setDefaultTag(String tag) async {
    await _box.put(_defaultTagKey, tag);
  }

  /// Gets the user's banned phrase list for anti-AI-scent processing.
  ///
  /// Returns null if not yet initialized (first access).
  List<String>? getBannedPhrases() {
    final data = _box.get('banned_phrases');
    if (data == null) return null;
    if (data is List) return data.cast<String>();
    return null;
  }

  /// Saves the user's banned phrase list for anti-AI-scent processing.
  Future<void> saveBannedPhrases(List<String> phrases) async {
    await _box.put('banned_phrases', phrases);
  }

  /// Gets the last export path used for manuscript export.
  ///
  /// Returns null if no export has been performed yet.
  String? getLastExportPath() {
    return _box.get('last_export_path') as String?;
  }

  /// Saves the last export path for manuscript export.
  ///
  /// Per D-18: Local-only, does not expose manuscript content.
  Future<void> saveLastExportPath(String path) async {
    await _box.put('last_export_path', path);
  }
}

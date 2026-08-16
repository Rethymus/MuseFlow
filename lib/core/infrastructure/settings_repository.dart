import 'dart:convert';
import 'dart:ui';

import 'package:hive_ce/hive.dart';
import 'package:museflow/core/domain/fragment_tag.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:museflow/features/ai/domain/creativity_level.dart';

const String _encryptionKeyStoreKey = 'hive_encryption_key';

/// Opens (or returns the already-open) encrypted Hive 'settings' box.
///
/// The AES key is read from — or generated into — platform secure storage,
/// so the box is always opened with the same cipher regardless of which
/// call site wins the race. Single source of truth for `main()` startup,
/// [settingsRepositoryProvider], and the onboarding repositories; previously
/// `onboardingRepositoryProvider` opened the same box WITHOUT a cipher, and
/// Hive ignores the cipher argument once a box is open, so an early onboarding
/// access silently left the settings box unencrypted.
Future<Box<dynamic>> openSettingsBox(SecureStorageService secureStorage) async {
  final storedKey = await secureStorage.getApiKey(_encryptionKeyStoreKey);

  List<int> encryptionKey;
  if (storedKey != null) {
    encryptionKey = base64Decode(storedKey);
  } else {
    encryptionKey = Hive.generateSecureKey();
    await secureStorage.saveApiKey(
      _encryptionKeyStoreKey,
      base64Encode(encryptionKey),
    );
  }

  return Hive.openBox(
    'settings',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );
}

/// Repository for managing application settings in an encrypted Hive box.
///
/// Persists window geometry (size, position) and user preferences.
class SettingsRepository {
  final Box<dynamic> _box;

  static const String _windowSizeKey = 'windowSize';
  static const String _windowPositionKey = 'windowPosition';
  static const String _defaultTagKey = 'defaultTag';
  static const String _autoDeviationCheckKey = 'auto_deviation_check';
  static const String _creativityLevelKey = 'creativity_level';
  static const String _webWorkspaceNoticeKey = 'web_workspace_notice_seen';
  static const String _lastBrowserBackupAtKey = 'last_browser_backup_at';

  SettingsRepository(this._box);

  /// The underlying Hive settings box.
  ///
  /// Exposed for sibling repositories (e.g. OnboardingProgressRepository)
  /// that need to persist data in the same encrypted box.
  Box<dynamic> get box => _box;

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
    await _box.put(_windowPositionKey, {'x': position.dx, 'y': position.dy});
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

  /// Whether the editor should run an automatic skill-consistency
  /// (deviation) check after each AI operation.
  ///
  /// OFF by default: the post-operation check fires a SECOND LLM call that
  /// silently doubles token cost. Users opt in via Settings. See D-CP-01.
  bool getAutoDeviationCheck() {
    return _box.get(_autoDeviationCheckKey, defaultValue: false) as bool;
  }

  /// Persists the auto deviation-check preference.
  Future<void> saveAutoDeviationCheck(bool enabled) async {
    await _box.put(_autoDeviationCheckKey, enabled);
  }

  /// Gets the user's creativity level (AA-03) for generation temperature.
  ///
  /// Falls back to [CreativityLevel.balanced] when no value is persisted yet,
  /// matching the historical default temperature behavior.
  CreativityLevel getCreativityLevel() {
    final raw = _box.get(_creativityLevelKey) as String?;
    return CreativityLevel.fromJson(raw);
  }

  /// Persists the user's creativity level selection.
  Future<void> saveCreativityLevel(CreativityLevel level) async {
    await _box.put(_creativityLevelKey, level.toJson());
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

  bool hasSeenWebWorkspaceNotice() {
    return _box.get(_webWorkspaceNoticeKey, defaultValue: false) as bool;
  }

  Future<void> markWebWorkspaceNoticeSeen() async {
    await _box.put(_webWorkspaceNoticeKey, true);
  }

  DateTime? getLastBrowserBackupAt() {
    final value = _box.get(_lastBrowserBackupAtKey) as String?;
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> saveLastBrowserBackupAt(DateTime value) async {
    await _box.put(_lastBrowserBackupAtKey, value.toIso8601String());
  }
}

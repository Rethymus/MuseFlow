import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;

/// Service for securely storing API keys using platform-specific secure storage.
///
/// On Windows: uses Windows Credential Manager.
/// On Android: uses Android Keystore with encrypted shared preferences.
/// On Linux/WSL2: uses file-based storage directly (libsecret keyring is
/// unreliable — auto-locks frequently, causing KeyringLocked errors).
class SecureStorageService {
  static const String _apiKeyPrefix = 'api_key_';

  final FlutterSecureStorage _storage;
  final bool _useFallback;

  late final String _fallbackDir;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(),
        ),
        // On Linux, skip libsecret entirely — keyring auto-locks on WSL2.
        _useFallback = !kIsWeb && Platform.isLinux {
    _fallbackDir = p.join(
      Platform.environment['HOME'] ?? '/tmp',
      '.local',
      'share',
      'museflow',
      'secrets',
    );
    _ensureFallbackDir();
  }

  /// Ensures fallback directory exists.
  void _ensureFallbackDir() {
    Directory(_fallbackDir).createSync(recursive: true);
  }

  String _fallbackPath(String providerId) {
    return p.join(_fallbackDir, '${_apiKeyPrefix}$providerId');
  }

  /// Saves an API key for the given provider.
  ///
  /// [providerId] identifies the AI provider (e.g., 'openai', 'claude', 'deepseek').
  /// [key] is the API key string to store securely.
  Future<void> saveApiKey(String providerId, String key) async {
    if (_useFallback) {
      File(_fallbackPath(providerId)).writeAsStringSync(key);
      return;
    }
    try {
      await _storage.write(key: '$_apiKeyPrefix$providerId', value: key);
    } catch (_) {
      // Fallback to file-based storage when secure storage fails
      // (e.g., locked keyring on WSL2).
      File(_fallbackPath(providerId)).writeAsStringSync(key);
    }
  }

  /// Retrieves the API key for the given provider.
  ///
  /// Returns null if no key is stored for the provider.
  Future<String?> getApiKey(String providerId) async {
    if (_useFallback) {
      final file = File(_fallbackPath(providerId));
      if (file.existsSync()) return file.readAsStringSync();
      return null;
    }
    try {
      return await _storage.read(key: '$_apiKeyPrefix$providerId');
    } catch (_) {
      // Try fallback storage on secure storage failure.
      final file = File(_fallbackPath(providerId));
      if (file.existsSync()) return file.readAsStringSync();
      return null;
    }
  }

  /// Deletes the API key for the given provider.
  Future<void> deleteApiKey(String providerId) async {
    if (_useFallback) {
      final file = File(_fallbackPath(providerId));
      if (file.existsSync()) file.deleteSync();
      return;
    }
    try {
      await _storage.delete(key: '$_apiKeyPrefix$providerId');
    } catch (_) {
      final file = File(_fallbackPath(providerId));
      if (file.existsSync()) file.deleteSync();
    }
  }
}

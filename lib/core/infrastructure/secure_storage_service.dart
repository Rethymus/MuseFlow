import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:museflow/core/platform/web_workspace_mode.dart';

/// Service for securely storing API keys using platform-specific secure storage.
///
/// On Windows: uses Windows Credential Manager.
/// On Android: uses Android Keystore with encrypted shared preferences.
/// On Linux: uses Secret Service/libsecret via flutter_secure_storage.
///
/// Sensitive values must not fall back to plaintext files. If the platform
/// secure-storage backend is unavailable or locked, callers receive the
/// platform exception and should surface an actionable error.
class SecureStorageService {
  static const String _apiKeyPrefix = 'api_key_';
  static const String _settingsEncryptionKeyId = 'hive_encryption_key';
  static const WebOptions _webSessionOptions = WebOptions(
    useSessionStorage: true,
  );

  final FlutterSecureStorage _storage;

  SecureStorageService()
    : _storage = const FlutterSecureStorage(aOptions: AndroidOptions());

  /// Saves an API key for the given provider.
  ///
  /// [providerId] identifies the AI provider (e.g., 'openai', 'claude', 'deepseek').
  /// [key] is the API key string to store securely.
  Future<void> saveApiKey(String providerId, String key) async {
    final storageKey = '$_apiKeyPrefix$providerId';
    await _storage.write(
      key: storageKey,
      value: key,
      webOptions: _webOptionsFor(providerId),
    );

    // Provider keys used to persist in localStorage on Web. Remove that copy
    // after a session-scoped write so upgrades do not leave a durable secret.
    if (kIsWeb && providerId != _settingsEncryptionKeyId) {
      await _storage.delete(key: storageKey);
    }
  }

  /// Retrieves the API key for the given provider.
  ///
  /// Returns null if no key is stored for the provider.
  Future<String?> getApiKey(String providerId) async {
    final storageKey = '$_apiKeyPrefix$providerId';
    final value = await _storage.read(
      key: storageKey,
      webOptions: _webOptionsFor(providerId),
    );
    if (value != null || !kIsWeb || providerId == _settingsEncryptionKeyId) {
      return value;
    }

    // Migrate a pre-session-storage Web key for the current tab, then remove
    // the old persistent copy. This path disappears once users revisit their
    // configured providers after upgrading.
    final legacyValue = await _storage.read(key: storageKey);
    if (legacyValue == null) return null;
    await _storage.write(
      key: storageKey,
      value: legacyValue,
      webOptions: _webSessionOptions,
    );
    await _storage.delete(key: storageKey);
    return legacyValue;
  }

  /// Deletes the API key for the given provider.
  Future<void> deleteApiKey(String providerId) async {
    final storageKey = '$_apiKeyPrefix$providerId';
    await _storage.delete(
      key: storageKey,
      webOptions: _webOptionsFor(providerId),
    );
    if (kIsWeb && providerId != _settingsEncryptionKeyId) {
      await _storage.delete(key: storageKey);
    }
  }

  WebOptions _webOptionsFor(String providerId) {
    return providerId == _settingsEncryptionKeyId && !isTemporaryWebWorkspace
        ? WebOptions.defaultOptions
        : _webSessionOptions;
  }
}

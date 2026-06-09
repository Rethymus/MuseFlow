import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  final FlutterSecureStorage _storage;

  SecureStorageService()
    : _storage = const FlutterSecureStorage(aOptions: AndroidOptions());

  /// Saves an API key for the given provider.
  ///
  /// [providerId] identifies the AI provider (e.g., 'openai', 'claude', 'deepseek').
  /// [key] is the API key string to store securely.
  Future<void> saveApiKey(String providerId, String key) async {
    await _storage.write(key: '$_apiKeyPrefix$providerId', value: key);
  }

  /// Retrieves the API key for the given provider.
  ///
  /// Returns null if no key is stored for the provider.
  Future<String?> getApiKey(String providerId) async {
    return _storage.read(key: '$_apiKeyPrefix$providerId');
  }

  /// Deletes the API key for the given provider.
  Future<void> deleteApiKey(String providerId) async {
    await _storage.delete(key: '$_apiKeyPrefix$providerId');
  }
}

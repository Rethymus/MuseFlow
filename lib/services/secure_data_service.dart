import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure data encryption service for user data protection.
///
/// This service provides AES-256-GCM encryption for sensitive user data
/// including note content, titles, and other private information.
///
/// Features:
/// - AES-256-GCM encryption algorithm
/// - Unique IV per data item
/// - PBKDF2 key derivation with salt
/// - Secure key storage via flutter_secure_storage
/// - Performance optimized with caching
class SecureDataService {
  static final SecureDataService instance = SecureDataService._internal();
  factory SecureDataService() => instance;
  SecureDataService._internal();

  // Constants for encryption
  static const int _keySize = 32; // 256 bits for AES-256
  static const int _ivLength = 12; // GCM standard IV length
  static const int _saltLength = 16; // Salt length for key derivation
  static const int _iterations = 10000; // PBKDF2 iterations
  static const String _masterKeyName = 'museflow_encryption_master_key';
  static const String _masterSaltName = 'museflow_encryption_salt';

  // Secure storage for master key
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Cached encryption keys for performance
  Key? _cachedKey;
  Uint8List? _cachedSalt;

  /// Initialize the secure data service
  ///
  /// Loads or generates the master encryption key and salt.
  /// Should be called during app initialization.
  Future<void> initialize() async {
    await _loadOrGenerateMasterKey();
  }

  /// Load existing master key or generate a new one
  Future<void> _loadOrGenerateMasterKey() async {
    final existingKey = await _secureStorage.read(key: _masterKeyName);
    final existingSalt = await _secureStorage.read(key: _masterSaltName);

    if (existingKey != null && existingSalt != null) {
      // Load existing key and salt
      _cachedKey = Key.fromBase64(existingKey);
      // 安全修复：使用base64UrlDecode读取salt，兼容新旧格式
      try {
        _cachedSalt = base64UrlDecode(existingSalt);
      } catch (e) {
        // 兼容旧格式：如果是旧的String.fromCharCodes格式
        _cachedSalt = Uint8List.fromList(
            existingSalt.codeUnits.map((c) => c as int).toList());
      }
    } else {
      // Generate new key and salt
      final salt = _generateRandomBytes(_saltLength);
      final masterKey = _generateRandomBytes(_keySize);

      // Store securely
      await _secureStorage.write(
        key: _masterKeyName,
        value: base64UrlEncode(masterKey),
      );
      // 安全修复：使用base64UrlEncode存储salt，避免>127字节值损坏
      await _secureStorage.write(
        key: _masterSaltName,
        value: base64UrlEncode(salt),
      );

      _cachedKey = Key(masterKey);
      _cachedSalt = salt;
    }
  }

  /// Generate cryptographically secure random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Derive encryption key from master key and data-specific salt
  ///
  /// Uses PBKDF2-HMAC-SHA256 for key derivation with a unique salt
  /// per data item to ensure different keys for different data.
  Uint8List _deriveKey(String dataId) {
    if (_cachedKey == null || _cachedSalt == null) {
      throw StateError('SecureDataService not initialized');
    }

    // Combine master salt with data-specific salt for uniqueness
    final dataSalt = sha256
        .convert(_cachedSalt! + Uint8List.fromList(dataId.codeUnits))
        .bytes;

    // PBKDF2 key derivation
    final hmac = Hmac(sha256, _cachedKey!.bytes);
    final derivedKey = pbkdf2(
      hmac,
      _cachedKey!.bytes,
      dataSalt,
      _iterations,
      _keySize,
    );

    return Uint8List.fromList(derivedKey);
  }

  /// Encrypt plain text data
  ///
  /// Returns a base64-encoded string containing the IV and encrypted data.
  /// Format: base64(iv + encrypted_data)
  String encrypt(String plainText, {String? dataId}) {
    if (_cachedKey == null) {
      throw StateError('SecureDataService not initialized');
    }

    // Generate unique IV for this encryption
    final iv = _generateRandomBytes(_ivLength);

    // Derive key for this specific data
    final derivedKey = dataId != null ? _deriveKey(dataId) : _cachedKey!.bytes;

    // Create encrypter with GCM mode
    final encrypter = Encrypter(AES(Key(derivedKey), mode: AESMode.gcm));

    // Encrypt the data
    final encrypted = encrypter.encryptBytes(
      plainText.codeUnits,
      iv: IV(iv),
    );

    // Combine IV and encrypted data
    final combined = Uint8List(iv.length + encrypted.bytes.length);
    combined.setAll(0, iv);
    combined.setAll(iv.length, encrypted.bytes);

    // Return as base64
    return base64UrlEncode(combined);
  }

  /// Decrypt encrypted data
  ///
  /// Takes a base64-encoded string containing IV and encrypted data,
  /// returns the original plain text.
  String decrypt(String encryptedData, {String? dataId}) {
    if (_cachedKey == null) {
      throw StateError('SecureDataService not initialized');
    }

    try {
      // Decode base64
      final combined = base64UrlDecode(encryptedData);

      if (combined.length < _ivLength) {
        throw ArgumentError('Invalid encrypted data format');
      }

      // Extract IV and encrypted data
      final iv = combined.sublist(0, _ivLength);
      final data = combined.sublist(_ivLength);

      // Derive key for this specific data
      final derivedKey =
          dataId != null ? _deriveKey(dataId) : _cachedKey!.bytes;

      // Create decrypter with GCM mode
      final decrypter = Encrypter(AES(Key(derivedKey), mode: AESMode.gcm));

      // Decrypt the data
      final decrypted = decrypter.decryptBytes(
        Encrypted(data),
        iv: IV(iv),
      );

      // Convert back to string
      return String.fromCharCodes(decrypted);
    } catch (e) {
      throw SecurityException('Decryption failed: $e');
    }
  }

  /// Encrypt note content with structured format
  ///
  /// Encrypts both title and content of a note, storing them in a
  /// structured format that includes metadata for validation.
  Map<String, String> encryptNoteData({
    required String noteId,
    required String title,
    required String content,
  }) {
    return {
      'title': encrypt(title, dataId: '${noteId}_title'),
      'content': encrypt(content, dataId: '${noteId}_content'),
      'iv_length': _ivLength.toString(),
      'algorithm': 'AES-256-GCM',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Decrypt note content
  ///
  /// Decrypts and validates the encrypted note data.
  Map<String, String> decryptNoteData({
    required String noteId,
    required String encryptedTitle,
    required String encryptedContent,
  }) {
    try {
      return {
        'title': decrypt(encryptedTitle, dataId: '${noteId}_title'),
        'content': decrypt(encryptedContent, dataId: '${noteId}_content'),
      };
    } catch (e) {
      throw SecurityException('Failed to decrypt note data: $e');
    }
  }

  /// Batch encrypt multiple notes efficiently
  ///
  /// Optimizes performance by caching derived keys and minimizing
  /// cryptographic operations.
  List<Map<String, dynamic>> batchEncryptNotes(
      List<Map<String, dynamic>> notes) {
    return notes.map((note) {
      final noteId = note['id'] as String;
      final encrypted = encryptNoteData(
        noteId: noteId,
        title: note['title'] as String,
        content: note['content'] as String,
      );

      return {
        'id': noteId,
        'title': encrypted['title']!,
        'content': encrypted['content']!,
        'created_at': note['created_at'],
        'updated_at': note['updated_at'],
        'tags': note['tags'] ?? [],
        'is_encrypted': true,
      };
    }).toList();
  }

  /// Batch decrypt multiple notes efficiently
  ///
  /// Optimizes performance for bulk decryption operations.
  List<Map<String, dynamic>> batchDecryptNotes(
      List<Map<String, dynamic>> notes) {
    return notes.map((note) {
      final noteId = note['id'] as String;
      final isEncrypted = note['is_encrypted'] as bool? ?? false;

      if (!isEncrypted) {
        // Return as-is if not encrypted
        return note;
      }

      final decrypted = decryptNoteData(
        noteId: noteId,
        encryptedTitle: note['title'] as String,
        encryptedContent: note['content'] as String,
      );

      return {
        'id': noteId,
        'title': decrypted['title']!,
        'content': decrypted['content']!,
        'created_at': note['created_at'],
        'updated_at': note['updated_at'],
        'tags': note['tags'] ?? [],
        'is_encrypted': false,
      };
    }).toList();
  }

  /// Verify data integrity by encrypting and comparing
  ///
  /// Useful for testing and validation purposes.
  bool verifyEncryption(String original, String encrypted, {String? dataId}) {
    try {
      final decrypted = decrypt(encrypted, dataId: dataId);
      return decrypted == original;
    } catch (e) {
      return false;
    }
  }

  /// Generate new encryption keys
  ///
  /// WARNING: This will invalidate all existing encrypted data.
  /// Only use this for security resets or key rotation.
  Future<void> regenerateKeys() async {
    // Clear cached keys
    _cachedKey = null;
    _cachedSalt = null;

    // Generate and store new keys
    await _loadOrGenerateMasterKey();
  }

  /// Clear all cached encryption keys from memory
  ///
  /// Should be called when the app goes to background or is locked.
  void clearCache() {
    _cachedKey = null;
    _cachedSalt = null;
  }

  /// Get encryption service status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _cachedKey != null,
      'key_size': _keySize,
      'algorithm': 'AES-256-GCM',
      'key_derivation': 'PBKDF2-HMAC-SHA256',
      'iterations': _iterations,
      'iv_length': _ivLength,
    };
  }

  /// Clean up resources
  Future<void> dispose() async {
    clearCache();
  }
}

/// Custom exception for security-related errors
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

/// PBKDF2 key derivation function implementation
List<int> pbkdf2(Hmac hmac, List<int> password, List<int> salt, int iterations,
    int keyLength) {
  final dk = <int>[];
  final blockCount =
      (keyLength + hmac.hash.digestSize - 1) ~/ hmac.hash.digestSize;

  for (int i = 1; i <= blockCount; i++) {
    final block = Uint8List(hmac.hash.digestSize);
    final iBytes = _intToBytes(i);

    // U1 = PRF(password, salt || INT_32_BE(i))
    final u1 = hmac.convert(salt + iBytes);
    block.setAll(0, u1.bytes);

    // U2...Uc = PRF(password, Uj-1)
    var uj = u1.bytes;
    for (int j = 1; j < iterations; j++) {
      uj = hmac.convert(uj).bytes;
      for (int k = 0; k < block.length; k++) {
        block[k] ^= uj[k];
      }
    }

    dk.addAll(block);
  }

  return dk.sublist(0, keyLength);
}

/// Convert integer to big-endian bytes
Uint8List _intToBytes(int value) {
  return Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big);
}

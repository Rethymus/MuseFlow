import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:retry/retry.dart';
import '../../models/ai_config.dart';
import '../../models/ai_message.dart';
import '../../models/ai_response.dart';
import '../../utils/logger.dart';
import 'ai_adapter.dart';
import 'adapters/openai_adapter.dart';
import 'adapters/claude_adapter.dart';
import 'adapters/deepseek_adapter.dart';
import 'adapters/ollama_adapter.dart';
import 'cache/cache_manager.dart';
import 'cache/ai_cache_stats.dart';

/// AI服务
/// 提供统一的AI服务接口，管理多个AI适配器
class AIService {
  static AIService? _instance;
  static const String _encryptionKey = 'museflow_ai_encryption_key';

  final FlutterSecureStorage _secureStorage;
  final Map<String, AIAdapter> _adapters = {};
  String? _activeConfigId;
  Timer? _cleanupTimer;
  final CacheManager _cacheManager;
  bool _enableCaching;
  // 性能优化：缓存加密密钥，避免重复平台通道调用
  String? _cachedEncryptionKey;

  AIService._({
    FlutterSecureStorage? secureStorage,
    CacheManager? cacheManager,
    bool enableCaching = true,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _cacheManager = cacheManager ?? CacheManager.instance,
        _enableCaching = enableCaching;

  /// 获取单例实例
  static AIService get instance {
    _instance ??= AIService._();
    return _instance!;
  }

  /// 初始化服务
  static Future<AIService> initialize() async {
    final service = instance;
    await service._initialize();
    return service;
  }

  Future<void> _initialize() async {
    // 初始化缓存管理器
    await CacheManager.initialize();
    // 启动定期清理任务
    _startCleanupTimer();
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _cleanupInactiveAdapters(),
    );
  }

  void _cleanupInactiveAdapters() {
    _adapters.removeWhere((id, adapter) {
      // 这里可以添加逻辑来清理不活跃的适配器
      // 暂时保留所有适配器
      return false;
    });
  }

  /// 创建适配器
  AIAdapter _createAdapter(AIConfig config) {
    switch (config.provider) {
      case AIProvider.openai:
        return OpenAIAdapter(config: config);
      case AIProvider.anthropic:
        return ClaudeAdapter(config: config);
      case AIProvider.deepseek:
        return DeepSeekAdapter(config: config);
      case AIProvider.ollama:
        return OllamaAdapter(config: config);
    }
  }

  /// 获取或创建适配器
  Future<AIAdapter> _getAdapter(AIConfig config) async {
    // 如果适配器已存在，直接返回
    if (_adapters.containsKey(config.id)) {
      return _adapters[config.id]!;
    }

    // 解密API Key
    final decryptedConfig = await _decryptConfig(config);

    // 创建新适配器
    final adapter = _createAdapter(decryptedConfig);
    _adapters[config.id] = adapter;

    return adapter;
  }

  /// 加密配置
  Future<String> _encryptApiKey(String apiKey) async {
    try {
      // 获取或生成加密密钥
      final key = await _getEncryptionKey();
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      // 加密API Key
      final encrypted = encrypter.encrypt(apiKey);
      return encrypted.base64;
    } catch (e) {
      // 安全修复：加密失败时抛出异常，不返回明文
      Logger.error('API密钥加密失败: $e', tag: 'Security');
      throw AIServiceException(
        message: 'API密钥加密失败，无法安全存储',
        originalError: e,
      );
    }
  }

  /// 解密配置
  Future<AIConfig> _decryptConfig(AIConfig config) async {
    try {
      final decryptedApiKey = await _decryptApiKey(config.apiKey);
      return config.copyWith(apiKey: decryptedApiKey);
    } catch (e) {
      // 如果解密失败，返回原始配置
      return config;
    }
  }

  /// 解密API Key
  Future<String> _decryptApiKey(String encryptedKey) async {
    try {
      final key = await _getEncryptionKey();
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      final decrypted = encrypter.decrypt64(encryptedKey);
      return decrypted;
    } catch (e) {
      // 安全修复：解密失败时抛出异常，不返回密文
      Logger.error('API密钥解密失败: $e', tag: 'Security');
      throw AIServiceException(
        message: 'API密钥解密失败，密钥可能已损坏',
        originalError: e,
      );
    }
  }

  /// 获取加密密钥（带缓存）
  Future<encrypt.Key> _getEncryptionKey() async {
    // 性能优化：使用缓存避免重复平台通道调用
    if (_cachedEncryptionKey != null) {
      return encrypt.Key.fromUtf8(_cachedEncryptionKey!);
    }

    final storedKey = await _secureStorage.read(key: _encryptionKey);

    if (storedKey != null) {
      _cachedEncryptionKey = storedKey;
      return encrypt.Key.fromUtf8(storedKey);
    }

    // 生成新密钥
    final newKey = _generateEncryptionKey();
    await _secureStorage.write(
      key: _encryptionKey,
      value: newKey,
    );

    _cachedEncryptionKey = newKey;
    return encrypt.Key.fromUtf8(newKey);
  }

  /// 生成加密密钥
  String _generateEncryptionKey() {
    // 生成32字节的密钥
    final key = encrypt.Key.fromSecureRandom(32);
    return key.base64;
  }

  /// 添加AI配置
  Future<AIConfig> addConfig(AIConfig config) async {
    // 加密API Key
    final encryptedApiKey = await _encryptApiKey(config.apiKey);
    final encryptedConfig = config.copyWith(apiKey: encryptedApiKey);

    // 保存配置
    await _saveConfig(encryptedConfig);

    return encryptedConfig;
  }

  /// 保存配置到安全存储
  Future<void> _saveConfig(AIConfig config) async {
    final key = 'ai_config_${config.id}';
    final json = config.toJson();
    // 安全修复：使用jsonEncode而不是Map.toString()，确保是有效JSON
    await _secureStorage.write(key: key, value: jsonEncode(json));
  }

  /// 获取配置列表
  Future<List<AIConfig>> getConfigs() async {
    final configs = <AIConfig>[];

    try {
      // 这里需要遍历安全存储中的所有配置
      // 由于FlutterSecureStorage不支持直接列举所有键，
      // 我们需要维护一个配置ID列表
      final configIds = await _getConfigIds();

      for (final id in configIds) {
        final config = await getConfig(id);
        if (config != null) {
          configs.add(config);
        }
      }
    } catch (e) {
      // 返回空列表
    }

    return configs;
  }

  /// 获取配置ID列表
  Future<List<String>> _getConfigIds() async {
    try {
      final idsJson = await _secureStorage.read(key: 'ai_config_ids');
      if (idsJson != null) {
        final List<dynamic> ids = jsonDecode(idsJson);
        return ids.cast<String>();
      }
    } catch (e) {
      // Ignore errors
    }

    return [];
  }

  /// 保存配置ID列表
  Future<void> _saveConfigIds(List<String> ids) async {
    await _secureStorage.write(
      key: 'ai_config_ids',
      value: jsonEncode(ids),
    );
  }

  /// 获取配置
  Future<AIConfig?> getConfig(String id) async {
    try {
      final key = 'ai_config_$id';
      final configJson = await _secureStorage.read(key: key);
      if (configJson == null) return null;

      final Map<String, dynamic> json = jsonDecode(configJson);
      return AIConfig.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// 删除配置
  Future<void> deleteConfig(String id) async {
    final key = 'ai_config_$id';
    await _secureStorage.delete(key: key);

    // 从适配器缓存中移除
    _adapters.remove(id);

    // 如果删除的是活跃配置，清除活跃配置
    if (_activeConfigId == id) {
      _activeConfigId = null;
    }

    // 更新配置ID列表
    final configIds = await _getConfigIds();
    configIds.remove(id);
    await _saveConfigIds(configIds);
  }

  /// 设置活跃配置
  Future<void> setActiveConfig(String id) async {
    final config = await getConfig(id);
    if (config == null) {
      throw ArgumentError('Configuration not found: $id');
    }

    _activeConfigId = id;
  }

  /// 获取活跃配置
  Future<AIConfig?> getActiveConfig() async {
    if (_activeConfigId == null) return null;
    return getConfig(_activeConfigId!);
  }

  /// 发送消息
  Future<AIResponse> sendMessage(
    List<AIMessage> messages, {
    AIConfig? config,
    int? retryCount,
    bool useCache = true,
  }) async {
    final effectiveConfig = config ?? await getActiveConfig();
    if (effectiveConfig == null) {
      throw StateError('No active configuration found');
    }

    // 检查缓存
    if (_enableCaching && useCache) {
      final cachedResponse =
          await _cacheManager.checkCache(messages, effectiveConfig);
      if (cachedResponse != null) {
        // 返回缓存的响应
        return AIResponse(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: cachedResponse.content,
          model: cachedResponse.model,
          inputTokens: cachedResponse.inputTokens,
          outputTokens: cachedResponse.outputTokens,
          finishReason: 'cached',
          metadata: {
            'cached': true,
            'cache_hit_count': cachedResponse.hitCount,
            'cache_age_seconds': cachedResponse.ageInSeconds,
            'original_timestamp': cachedResponse.createdAt.toIso8601String(),
          },
        );
      }
    }

    // 缓存未命中，发送实际请求
    final adapter = await _getAdapter(effectiveConfig);
    final retries = retryCount ?? effectiveConfig.effectiveRetryCount;

    final response = await retry(
      maxAttempts: retries,
      retryIf: (e) => _shouldRetry(e),
      onRetry: (e) {
        Logger.warning('Retry request after error: $e', tag: 'AI');
      },
      () => adapter.sendMessage(messages, config: effectiveConfig),
    );

    // 存储响应到缓存
    if (_enableCaching && useCache) {
      await _cacheManager.storeCache(messages, effectiveConfig, response);
    }

    return response;
  }

  /// 流式发送消息
  Stream<AIStreamChunk> sendMessageStream(
    List<AIMessage> messages, {
    AIConfig? config,
    int? retryCount,
    void Function(AIStreamChunk)? onChunk,
    bool useCache = true,
  }) async* {
    final effectiveConfig = config ?? await getActiveConfig();
    if (effectiveConfig == null) {
      throw StateError('No active configuration found');
    }

    // 流式请求不支持缓存，直接发送
    // 但可以在完成后缓存完整响应
    final adapter = await _getAdapter(effectiveConfig);
    final retries = retryCount ?? effectiveConfig.effectiveRetryCount;

    String fullContent = '';
    await for (final chunk in adapter.sendMessageStream(
      messages,
      config: effectiveConfig,
      onChunk: onChunk,
    )) {
      fullContent += chunk.content;
      yield chunk;
    }

    // 流式响应完成后缓存完整结果
    if (_enableCaching && useCache && fullContent.isNotEmpty) {
      final response = AIResponse(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: fullContent,
        model: effectiveConfig.model,
        metadata: {'streaming': true},
      );
      await _cacheManager.storeCache(messages, effectiveConfig, response);
    }
  }

  /// 判断是否应该重试
  bool _shouldRetry(dynamic error) {
    if (error is NetworkException) return true;
    if (error is AITimeoutException) return true;
    if (error is RateLimitException) return true;
    return false;
  }

  /// 验证API密钥
  Future<bool> validateApiKey(AIConfig config) async {
    try {
      final adapter = await _getAdapter(config);
      return await adapter.validateApiKey();
    } catch (e) {
      return false;
    }
  }

  /// 获取可用模型
  Future<List<String>> getAvailableModels(AIConfig config) async {
    final adapter = await _getAdapter(config);
    return adapter.getAvailableModels();
  }

  /// 估算token数
  int estimateTokens(List<AIMessage> messages, AIConfig config) {
    final adapter = _createAdapter(config);
    return adapter.estimateTokens(messages);
  }

  /// 清理资源
  void dispose() {
    _cleanupTimer?.cancel();
    for (final adapter in _adapters.values) {
      adapter.dispose();
    }
    _adapters.clear();
  }

  /// 获取缓存管理器
  CacheManager get cacheManager => _cacheManager;

  /// 获取缓存统计信息
  Future<AICacheStats> getCacheStats() async {
    return _cacheManager.stats;
  }

  /// 获取缓存性能报告
  Future<String> getCachePerformanceReport() async {
    return await _cacheManager.generateReport();
  }

  /// 获取缓存健康状态
  Future<Map<String, dynamic>> getCacheHealthStatus() async {
    return await _cacheManager.getHealthStatus();
  }

  /// 清空AI缓存
  Future<void> clearCache({bool clearExpiredOnly = false}) async {
    if (clearExpiredOnly) {
      await _cacheManager.clearExpired();
    } else {
      await _cacheManager.clearAll();
    }
  }

  /// 重置缓存统计
  void resetCacheStats() {
    _cacheManager.resetStats();
  }

  /// 启用/禁用缓存
  void setCachingEnabled(bool enabled) {
    _enableCaching = enabled;
  }

  /// 获取缓存性能指标
  Future<CachePerformanceMetrics> getCachePerformanceMetrics() async {
    return await _cacheManager.getPerformanceMetrics();
  }

  /// 获取缓存建议
  Future<List<String>> getCacheSuggestions() async {
    return await _cacheManager.getSuggestions();
  }

  /// 监听缓存事件
  Stream<CacheManagerEvent> get cacheEvents => _cacheManager.events;

  /// 优化缓存策略
  Future<void> optimizeCacheStrategy() async {
    await _cacheManager.optimizeStrategy();
  }

  /// 预热缓存
  Future<void> warmupCache(
    List<AIMessage> commonMessages,
    AIConfig? config,
  ) async {
    final effectiveConfig = config ?? await getActiveConfig();
    if (effectiveConfig == null) {
      throw StateError('No active configuration found');
    }
    await _cacheManager.warmup(commonMessages, effectiveConfig);
  }
}

/// AI服务异常
class AIServiceException implements Exception {
  final String message;
  final dynamic originalError;

  AIServiceException({
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'AIServiceException: $message';
}

/// 无活跃配置异常
class NoActiveConfigException extends AIServiceException {
  NoActiveConfigException({
    String? message,
    dynamic originalError,
  }) : super(
          message: message ?? 'No active AI configuration found',
          originalError: originalError,
        );
}

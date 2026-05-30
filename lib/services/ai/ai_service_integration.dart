import 'dart:async';
import 'ai_service.dart';
import 'ai_types.dart';
import 'personalized_ai_service.dart';
import 'contextual_ai_service.dart';
import 'realtime_writing_assistant.dart';
import 'cache/cache_manager.dart';
import 'cache/ai_cache_stats.dart';
import '../../models/ai_config.dart';
import '../../models/ai_message.dart';
import '../../models/ai_response.dart';
import '../../models/user_preference.dart';
import '../../utils/logger.dart';

// 导出所有必要的类型，以便外部使用
export 'ai_service.dart' show AIService;
export 'ai_adapter.dart' show AIAdapter;
export '../../models/ai_response.dart' show AIStreamChunk;
export 'ai_types.dart' show SuggestionType, EmotionTone, ContextualSuggestion;
export 'personalized_ai_service.dart' show PersonalizedAIService;
export 'contextual_ai_service.dart' show ContextualAIService;
export 'realtime_writing_assistant.dart' show RealTimeWritingAssistant;

/// AI服务集成器
/// 统一管理所有AI相关服务，提供向后兼容的接口
class AIServiceIntegration {
  static AIServiceIntegration? _instance;

  // 基础服务
  late final AIService _baseService;
  late final PersonalizedAIService _personalizedService;
  late final ContextualAIService _contextualService;
  late final RealTimeWritingAssistant _writingAssistant;

  // 服务状态
  bool _initialized = false;
  final Map<String, bool> _serviceStatus = {
    'base': false,
    'personalized': false,
    'contextual': false,
    'writingAssistant': false,
  };

  // 配置
  AIServiceIntegrationConfig _config = const AIServiceIntegrationConfig();

  AIServiceIntegration._();

  /// 获取单例实例
  static AIServiceIntegration get instance {
    _instance ??= AIServiceIntegration._();
    return _instance!;
  }

  /// 初始化所有AI服务
  static Future<AIServiceIntegration> initialize({
    AIService? baseService,
    PersonalizedAIService? personalizedService,
    ContextualAIService? contextualService,
    RealTimeWritingAssistant? writingAssistant,
    AIServiceIntegrationConfig? config,
  }) async {
    final integration = instance;
    integration._config = config ?? const AIServiceIntegrationConfig();

    try {
      // 1. 初始化基础AI服务
      Logger.info('初始化基础AI服务...', tag: 'AIIntegration');
      integration._baseService = baseService ?? await AIService.initialize();
      integration._serviceStatus['base'] = true;

      // 2. 初始化个性化AI服务
      if (integration._config.enablePersonalizedService) {
        Logger.info('初始化个性化AI服务...', tag: 'AIIntegration');
        integration._personalizedService = personalizedService ??
            await PersonalizedAIService.initialize(
              baseService: integration._baseService,
            );
        integration._serviceStatus['personalized'] = true;
      } else {
        integration._personalizedService = PersonalizedAIService.instance;
      }

      // 3. 初始化上下文AI服务
      if (integration._config.enableContextualService) {
        Logger.info('初始化上下文AI服务...', tag: 'AIIntegration');
        integration._contextualService = contextualService ??
            await ContextualAIService.initialize(
              baseService: integration._baseService,
              personalizedService: integration._personalizedService,
            );
        integration._serviceStatus['contextual'] = true;
      } else {
        integration._contextualService = ContextualAIService.instance;
      }

      // 4. 初始化实时写作助手
      if (integration._config.enableWritingAssistant) {
        Logger.info('初始化实时写作助手...', tag: 'AIIntegration');
        integration._writingAssistant = writingAssistant ??
            await RealTimeWritingAssistant.initialize(
              contextualService: integration._contextualService,
            );
        integration._serviceStatus['writingAssistant'] = true;
      } else {
        integration._writingAssistant = RealTimeWritingAssistant.instance;
      }

      integration._initialized = true;
      Logger.info('AI服务集成初始化完成', tag: 'AIIntegration');
    } catch (e) {
      Logger.error('AI服务集成初始化失败: $e', tag: 'AIIntegration');
      rethrow;
    }

    return integration;
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
          'AIServiceIntegration not initialized. Call initialize() first.');
    }
  }

  /// 向后兼容：发送消息（使用个性化服务）
  Future<AIResponse> sendMessage(
    List<AIMessage> messages, {
    AIConfig? config,
    int? retryCount,
    bool useCache = true,
    bool applyPersonalization = true,
  }) async {
    _ensureInitialized();

    if (applyPersonalization && _serviceStatus['personalized'] == true) {
      return await _personalizedService.sendPersonalizedMessage(
        messages,
        config: config,
        retryCount: retryCount,
        useCache: useCache,
        applyPreferences: true,
      );
    } else {
      return await _baseService.sendMessage(
        messages,
        config: config,
        retryCount: retryCount,
        useCache: useCache,
      );
    }
  }

  /// 向后兼容：流式发送消息
  Stream<AIStreamChunk> sendMessageStream(
    List<AIMessage> messages, {
    AIConfig? config,
    int? retryCount,
    void Function(AIStreamChunk)? onChunk,
    bool useCache = true,
    bool applyPersonalization = true,
  }) async* {
    _ensureInitialized();

    if (applyPersonalization && _serviceStatus['personalized'] == true) {
      yield* _personalizedService.sendPersonalizedMessageStream(
        messages,
        config: config,
        retryCount: retryCount,
        onChunk: onChunk,
        useCache: useCache,
        applyPreferences: true,
      );
    } else {
      yield* _baseService.sendMessageStream(
        messages,
        config: config,
        retryCount: retryCount,
        onChunk: onChunk,
        useCache: useCache,
      );
    }
  }

  /// 发送上下文感知消息
  Future<AIResponse> sendContextualMessage(
    String userMessage, {
    String? documentId,
    String? conversationId,
    AIConfig? config,
    Map<String, dynamic>? customContext,
  }) async {
    _ensureInitialized();

    if (_serviceStatus['contextual'] != true) {
      throw StateError('ContextualAIService not enabled');
    }

    return await _contextualService.sendContextualMessage(
      userMessage,
      documentId: documentId,
      conversationId: conversationId,
      config: config,
      customContext: customContext,
    );
  }

  /// 开始写作会话
  String startWritingSession({
    required String documentId,
    String? conversationId,
    String? initialContent,
    Map<String, dynamic>? metadata,
  }) {
    _ensureInitialized();

    if (_serviceStatus['writingAssistant'] != true) {
      throw StateError('RealTimeWritingAssistant not enabled');
    }

    return _writingAssistant.startWritingSession(
      documentId: documentId,
      conversationId: conversationId,
      initialContent: initialContent,
      metadata: metadata,
    );
  }

  /// 处理写作输入
  Future<List<WritingPrediction>> processWritingInput(
    String sessionId,
    String currentText, {
    int? cursorPosition,
  }) async {
    _ensureInitialized();

    if (_serviceStatus['writingAssistant'] != true) {
      throw StateError('RealTimeWritingAssistant not enabled');
    }

    return await _writingAssistant.processTextInput(
      sessionId,
      currentText,
      cursorPosition: cursorPosition,
    );
  }

  /// 分析文档风格
  Future<DocumentStyleAnalysis> analyzeDocumentStyle(
    String documentContent, {
    String? documentId,
    String? context,
  }) async {
    _ensureInitialized();

    if (_serviceStatus['contextual'] != true) {
      throw StateError('ContextualAIService not enabled');
    }

    return await _contextualService.analyzeDocumentStyle(
      documentContent,
      documentId: documentId,
      context: context,
    );
  }

  /// 预测用户需求
  Future<UserIntentPrediction> predictUserNeeds(
    String sessionId,
    String currentText,
  ) async {
    _ensureInitialized();

    if (_serviceStatus['writingAssistant'] != true) {
      throw StateError('RealTimeWritingAssistant not enabled');
    }

    return await _writingAssistant.predictUserNeeds(sessionId, currentText);
  }

  /// 生成情境化提示
  Future<ContextualPrompt> generateContextualPrompt(
    String sessionId,
    String currentText, {
    String? specificContext,
    List<String>? focusAreas,
  }) async {
    _ensureInitialized();

    if (_serviceStatus['writingAssistant'] != true) {
      throw StateError('RealTimeWritingAssistant not enabled');
    }

    return await _writingAssistant.generateContextualPrompt(
      sessionId,
      currentText,
      specificContext: specificContext,
      focusAreas: focusAreas,
    );
  }

  /// 提供格式建议
  Future<FormatSuggestion> provideFormatSuggestion(
    String sessionId,
    String currentText,
  ) async {
    _ensureInitialized();

    if (_serviceStatus['writingAssistant'] != true) {
      throw StateError('RealTimeWritingAssistant not enabled');
    }

    return await _writingAssistant.provideFormatSuggestion(
      sessionId,
      currentText,
    );
  }

  /// 开始多轮对话
  String startConversation({
    String? documentId,
    String? initialContext,
    Map<String, dynamic>? metadata,
  }) {
    _ensureInitialized();

    if (_serviceStatus['contextual'] != true) {
      throw StateError('ContextualAIService not enabled');
    }

    return _contextualService.startConversation(
      documentId: documentId,
      initialContext: initialContext,
      metadata: metadata,
    );
  }

  /// 继续对话
  Future<AIResponse> continueConversation(
    String conversationId,
    String userMessage, {
    AIConfig? config,
  }) async {
    _ensureInitialized();

    if (_serviceStatus['contextual'] != true) {
      throw StateError('ContextualAIService not enabled');
    }

    return await _contextualService.continueConversation(
      conversationId,
      userMessage,
      config: config,
    );
  }

  /// 结束对话
  Future<ConversationSummary> endConversation(String conversationId) async {
    _ensureInitialized();

    if (_serviceStatus['contextual'] != true) {
      throw StateError('ContextualAIService not enabled');
    }

    return await _contextualService.endConversation(conversationId);
  }

  /// 结束写作会话
  Future<WritingSessionSummary> endWritingSession(String sessionId) async {
    _ensureInitialized();

    if (_serviceStatus['writingAssistant'] != true) {
      throw StateError('RealTimeWritingAssistant not enabled');
    }

    return await _writingAssistant.endWritingSession(sessionId);
  }

  // 代理基础服务方法（向后兼容）

  Future<AIConfig> addConfig(AIConfig config) => _baseService.addConfig(config);
  Future<List<AIConfig>> getConfigs() => _baseService.getConfigs();
  Future<AIConfig?> getConfig(String id) => _baseService.getConfig(id);
  Future<void> deleteConfig(String id) => _baseService.deleteConfig(id);
  Future<void> setActiveConfig(String id) => _baseService.setActiveConfig(id);
  Future<AIConfig?> getActiveConfig() => _baseService.getActiveConfig();
  Future<bool> validateApiKey(AIConfig config) =>
      _baseService.validateApiKey(config);
  Future<List<String>> getAvailableModels(AIConfig config) =>
      _baseService.getAvailableModels(config);
  int estimateTokens(List<AIMessage> messages, AIConfig config) =>
      _baseService.estimateTokens(messages, config);

  // 缓存相关方法
  CacheManager get cacheManager => _baseService.cacheManager;
  Future<AICacheStats> getCacheStats() => _baseService.getCacheStats();
  Future<String> getCachePerformanceReport() =>
      _baseService.getCachePerformanceReport();
  Future<Map<String, dynamic>> getCacheHealthStatus() =>
      _baseService.getCacheHealthStatus();
  Future<void> clearCache({bool clearExpiredOnly = false}) =>
      _baseService.clearCache(clearExpiredOnly: clearExpiredOnly);
  void resetCacheStats() => _baseService.resetCacheStats();
  void setCachingEnabled(bool enabled) =>
      _baseService.setCachingEnabled(enabled);
  Future<CachePerformanceMetrics> getCachePerformanceMetrics() =>
      _baseService.getCachePerformanceMetrics();
  Future<List<String>> getCacheSuggestions() =>
      _baseService.getCacheSuggestions();
  Stream<CacheManagerEvent> get cacheEvents => _baseService.cacheEvents;
  Future<void> optimizeCacheStrategy() => _baseService.optimizeCacheStrategy();
  Future<void> warmupCache(List<AIMessage> commonMessages, AIConfig? config) =>
      _baseService.warmupCache(commonMessages, config);

  // 个性化服务方法
  Future<void> recordFeedback({
    required String originalText,
    required String suggestedText,
    required String finalText,
    String? context,
    List<String>? topics,
  }) async {
    if (_serviceStatus['personalized'] == true) {
      return await _personalizedService.recordFeedback(
        originalText: originalText,
        suggestedText: suggestedText,
        finalText: finalText,
        context: context,
        topics: topics,
      );
    }
  }

  Future<WritingAnalysis> analyzeUserWriting(String text,
      {String? context}) async {
    if (_serviceStatus['personalized'] == true) {
      return await _personalizedService.analyzeUserWriting(text,
          context: context);
    }
    throw StateError('PersonalizedAIService not enabled');
  }

  Map<String, dynamic> getPersonalizationSuggestions(String text) {
    if (_serviceStatus['personalized'] == true) {
      return _personalizedService.getPersonalizationSuggestions(text);
    }
    throw StateError('PersonalizedAIService not enabled');
  }

  Map<String, dynamic> getLearningStats() {
    if (_serviceStatus['personalized'] == true) {
      return _personalizedService.getLearningStats();
    }
    return {};
  }

  Future<Map<String, dynamic>> getPrivacyReport() async {
    if (_serviceStatus['personalized'] == true) {
      return await _personalizedService.getPrivacyReport();
    }
    return {};
  }

  Future<void> resetPreferences() async {
    if (_serviceStatus['personalized'] == true) {
      return await _personalizedService.resetPreferences();
    }
  }

  Future<void> clearAllData() async {
    if (_serviceStatus['personalized'] == true) {
      return await _personalizedService.clearAllData();
    }
  }

  Stream<UserPreference> get preferenceUpdates {
    if (_serviceStatus['personalized'] == true) {
      return _personalizedService.preferenceUpdates;
    }
    return const Stream.empty();
  }

  UserPreference? get currentPreference {
    if (_serviceStatus['personalized'] == true) {
      return _personalizedService.currentPreference;
    }
    return null;
  }

  // 事件流
  Stream<ContextualSuggestion> get contextualSuggestions {
    if (_serviceStatus['contextual'] == true) {
      return _contextualService.contextualSuggestions;
    }
    return const Stream.empty();
  }

  Stream<WritingAssistantEvent> get writingAssistantEvents {
    if (_serviceStatus['writingAssistant'] == true) {
      return _writingAssistant.events;
    }
    return const Stream.empty();
  }

  /// 获取服务状态
  Map<String, bool> get serviceStatus => Map.from(_serviceStatus);

  /// 检查服务是否启用
  bool isServiceEnabled(String serviceName) {
    return _serviceStatus[serviceName] ?? false;
  }

  /// 更新服务配置
  Future<void> updateServiceConfig(AIServiceIntegrationConfig config) async {
    _config = config;

    // 重新初始化需要的服务
    if (config.enablePersonalizedService &&
        _serviceStatus['personalized'] != true) {
      await PersonalizedAIService.initialize(baseService: _baseService);
      _serviceStatus['personalized'] = true;
    }

    if (config.enableContextualService &&
        _serviceStatus['contextual'] != true) {
      await ContextualAIService.initialize(
        baseService: _baseService,
        personalizedService: _personalizedService,
      );
      _serviceStatus['contextual'] = true;
    }

    if (config.enableWritingAssistant &&
        _serviceStatus['writingAssistant'] != true) {
      await RealTimeWritingAssistant.initialize(
        contextualService: _contextualService,
      );
      _serviceStatus['writingAssistant'] = true;
    }
  }

  /// 获取当前配置
  AIServiceIntegrationConfig get config => _config;

  /// 清理资源
  void dispose() {
    _baseService.dispose();
    if (_serviceStatus['contextual'] == true) {
      _contextualService.dispose();
    }
    if (_serviceStatus['writingAssistant'] == true) {
      _writingAssistant.dispose();
    }
    _serviceStatus.forEach((key, value) => _serviceStatus[key] = false);
    _initialized = false;
  }

  /// 获取服务健康状态
  Future<Map<String, dynamic>> getHealthStatus() async {
    final healthStatus = <String, dynamic>{};

    healthStatus['initialized'] = _initialized;
    healthStatus['services'] = Map.from(_serviceStatus);

    // 添加各个服务的详细健康状态
    if (_serviceStatus['base'] == true) {
      try {
        final cacheHealth = await _baseService.getCacheHealthStatus();
        healthStatus['cache'] = cacheHealth;
      } catch (e) {
        healthStatus['cache'] = {'error': e.toString()};
      }
    }

    if (_serviceStatus['personalized'] == true) {
      try {
        final privacyReport = await _personalizedService.getPrivacyReport();
        healthStatus['personalization'] = {
          'enabled': _personalizedService.currentPreference?.enabled ?? false,
          'confidence':
              _personalizedService.currentPreference?.confidenceScore ?? 0.0,
        };
      } catch (e) {
        healthStatus['personalization'] = {'error': e.toString()};
      }
    }

    return healthStatus;
  }
}

/// AI服务集成配置
class AIServiceIntegrationConfig {
  final bool enablePersonalizedService;
  final bool enableContextualService;
  final bool enableWritingAssistant;
  final bool enableCaching;
  final int maxContextHistory;
  final double styleAnalysisThreshold;
  final int maxConversationTurns;

  const AIServiceIntegrationConfig({
    this.enablePersonalizedService = true,
    this.enableContextualService = true,
    this.enableWritingAssistant = true,
    this.enableCaching = true,
    this.maxContextHistory = 50,
    this.styleAnalysisThreshold = 0.6,
    this.maxConversationTurns = 20,
  });

  /// 创建默认配置
  factory AIServiceIntegrationConfig.defaultConfig() {
    return const AIServiceIntegrationConfig();
  }

  /// 创建仅基础服务的配置
  factory AIServiceIntegrationConfig.basicOnly() {
    return const AIServiceIntegrationConfig(
      enablePersonalizedService: false,
      enableContextualService: false,
      enableWritingAssistant: false,
    );
  }

  /// 创建完整功能的配置
  factory AIServiceIntegrationConfig.fullFeatured() {
    return const AIServiceIntegrationConfig(
      enablePersonalizedService: true,
      enableContextualService: true,
      enableWritingAssistant: true,
      enableCaching: true,
      maxContextHistory: 100,
      styleAnalysisThreshold: 0.5,
      maxConversationTurns: 30,
    );
  }

  /// 复制并修改配置
  AIServiceIntegrationConfig copyWith({
    bool? enablePersonalizedService,
    bool? enableContextualService,
    bool? enableWritingAssistant,
    bool? enableCaching,
    int? maxContextHistory,
    double? styleAnalysisThreshold,
    int? maxConversationTurns,
  }) {
    return AIServiceIntegrationConfig(
      enablePersonalizedService:
          enablePersonalizedService ?? this.enablePersonalizedService,
      enableContextualService:
          enableContextualService ?? this.enableContextualService,
      enableWritingAssistant:
          enableWritingAssistant ?? this.enableWritingAssistant,
      enableCaching: enableCaching ?? this.enableCaching,
      maxContextHistory: maxContextHistory ?? this.maxContextHistory,
      styleAnalysisThreshold:
          styleAnalysisThreshold ?? this.styleAnalysisThreshold,
      maxConversationTurns: maxConversationTurns ?? this.maxConversationTurns,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() => {
        'enablePersonalizedService': enablePersonalizedService,
        'enableContextualService': enableContextualService,
        'enableWritingAssistant': enableWritingAssistant,
        'enableCaching': enableCaching,
        'maxContextHistory': maxContextHistory,
        'styleAnalysisThreshold': styleAnalysisThreshold,
        'maxConversationTurns': maxConversationTurns,
      };

  /// 从JSON创建
  factory AIServiceIntegrationConfig.fromJson(Map<String, dynamic> json) {
    return AIServiceIntegrationConfig(
      enablePersonalizedService:
          json['enablePersonalizedService'] as bool? ?? true,
      enableContextualService: json['enableContextualService'] as bool? ?? true,
      enableWritingAssistant: json['enableWritingAssistant'] as bool? ?? true,
      enableCaching: json['enableCaching'] as bool? ?? true,
      maxContextHistory: json['maxContextHistory'] as int? ?? 50,
      styleAnalysisThreshold: json['styleAnalysisThreshold'] as double? ?? 0.6,
      maxConversationTurns: json['maxConversationTurns'] as int? ?? 20,
    );
  }
}

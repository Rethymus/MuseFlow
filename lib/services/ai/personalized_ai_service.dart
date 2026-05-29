import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:retry/retry.dart';
import '../../models/ai_config.dart';
import '../../models/ai_message.dart';
import '../../models/ai_response.dart';
import '../../models/user_preference.dart';
import 'ai_adapter.dart';
import 'adapters/openai_adapter.dart';
import 'adapters/claude_adapter.dart';
import 'adapters/deepseek_adapter.dart';
import 'adapters/ollama_adapter.dart';
import 'cache/ai_request_cache.dart';
import 'cache/cache_manager.dart';
import '../preference/user_preference_manager.dart';
import '../preference/feedback_collector.dart';
import '../preference/writing_analyzer.dart';

/// 个性化AI服务
/// 在基础AI服务上集成用户偏好学习功能
class PersonalizedAIService {
  static PersonalizedAIService? _instance;
  final AIService _baseService;
  UserPreferenceManager? _preferenceManager;
  FeedbackCollector? _feedbackCollector;
  WritingAnalyzer? _writingAnalyzer;
  bool _initialized = false;

  PersonalizedAIService._({AIService? baseService})
      : _baseService = baseService ?? AIService.instance;

  /// 获取单例实例
  static PersonalizedAIService get instance {
    _instance ??= PersonalizedAIService._();
    return _instance!;
  }

  /// 初始化服务
  static Future<PersonalizedAIService> initialize({
    AIService? baseService,
    UserPreferenceManager? preferenceManager,
    FeedbackCollector? feedbackCollector,
    WritingAnalyzer? writingAnalyzer,
  }) async {
    final service = instance;
    service._baseService = baseService ?? AIService.instance;

    // 初始化偏好管理器
    service._preferenceManager =
        preferenceManager ?? await UserPreferenceManager.initialize();
    service._feedbackCollector =
        feedbackCollector ?? FeedbackCollector.instance;
    service._writingAnalyzer = writingAnalyzer ?? WritingAnalyzer.instance;

    service._initialized = true;
    return service;
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
          'PersonalizedAIService not initialized. Call initialize() first.');
    }
  }

  /// 是否已初始化
  bool get isInitialized => _initialized;

  /// 发送个性化消息
  Future<AIResponse> sendPersonalizedMessage(
    List<AIMessage> messages, {
    AIConfig? config,
    int? retryCount,
    bool useCache = true,
    bool applyPreferences = true,
  }) async {
    _ensureInitialized();

    final preference = _preferenceManager!.currentPreference;
    if (applyPreferences && preference != null && preference.enabled) {
      // 应用用户偏好到消息
      final personalizedMessages =
          _applyPreferencesToMessages(messages, preference);

      // 发送消息
      final response = await _baseService.sendMessage(
        personalizedMessages,
        config: config,
        retryCount: retryCount,
        useCache: useCache,
      );

      // 根据用户偏好调整响应
      final adjustedResponse =
          _adjustResponseForPreferences(response, preference);

      return adjustedResponse;
    } else {
      // 不应用偏好，直接发送
      return await _baseService.sendMessage(
        messages,
        config: config,
        retryCount: retryCount,
        useCache: useCache,
      );
    }
  }

  /// 流式发送个性化消息
  Stream<AIStreamChunk> sendPersonalizedMessageStream(
    List<AIMessage> messages, {
    AIConfig? config,
    int? retryCount,
    void Function(AIStreamChunk)? onChunk,
    bool useCache = true,
    bool applyPreferences = true,
  }) async* {
    _ensureInitialized();

    final preference = _preferenceManager!.currentPreference;
    if (applyPreferences && preference != null && preference.enabled) {
      // 应用用户偏好到消息
      final personalizedMessages =
          _applyPreferencesToMessages(messages, preference);

      // 流式发送消息
      await for (final chunk in _baseService.sendMessageStream(
        personalizedMessages,
        config: config,
        retryCount: retryCount,
        onChunk: onChunk,
        useCache: useCache,
      )) {
        // 根据用户偏好调整每个chunk
        final adjustedChunk = _adjustChunkForPreferences(chunk, preference);
        yield adjustedChunk;
      }
    } else {
      // 不应用偏好，直接发送
      await for (final chunk in _baseService.sendMessageStream(
        messages,
        config: config,
        retryCount: retryCount,
        onChunk: onChunk,
        useCache: useCache,
      )) {
        yield chunk;
      }
    }
  }

  /// 应用用户偏好到消息
  List<AIMessage> _applyPreferencesToMessages(
    List<AIMessage> messages,
    UserPreference preference,
  ) {
    if (!preference.hasSufficientConfidence()) {
      return messages;
    }

    final personalizedMessages = <AIMessage>[];

    for (final message in messages) {
      // 根据用户偏好调整消息内容
      String adjustedContent = message.content;

      // 根据语言风格偏好调整
      adjustedContent = _adjustForLanguageStyle(
        adjustedContent,
        preference.languageStyle,
      );

      // 根据详细程度偏好调整
      adjustedContent = _adjustForDetailLevel(
        adjustedContent,
        preference.detailLevel,
      );

      // 根据主题兴趣添加相关指导
      if (preference.topicInterests.isNotEmpty) {
        final systemPrompt = _generatePersonalizedSystemPrompt(preference);
        if (message.role == 'system') {
          adjustedContent = '$systemPrompt\n\n$adjustedContent';
        }
      }

      // 创建调整后的消息
      personalizedMessages.add(AIMessage(
        role: message.role,
        content: adjustedContent,
        metadata: {
          ...?message.metadata,
          'personalized': true,
          'preferenceApplied': true,
        },
      ));
    }

    return personalizedMessages;
  }

  /// 根据语言风格调整内容
  String _adjustForLanguageStyle(String content, LanguageStyle style) {
    switch (style) {
      case LanguageStyle.formal:
        return _makeFormal(content);
      case LanguageStyle.casual:
        return _makeCasual(content);
      default:
        return content;
    }
  }

  /// 根据详细程度调整内容
  String _adjustForDetailLevel(String content, DetailLevel level) {
    switch (level) {
      case DetailLevel.concise:
        return '$content\n\n请保持简洁明了。';
      case DetailLevel.detailed:
        return '$content\n\n请提供详细的信息和解释。';
      case DetailLevel.verbose:
        return '$content\n\n请提供全面详细的阐述。';
      default:
        return content;
    }
  }

  /// 使内容更正式
  String _makeFormal(String content) {
    return content
        .replaceAll('很好', '优秀')
        .replaceAll('不错', '良好')
        .replaceAll('很多', '诸多')
        .replaceAll('特别', '尤为')
        .replaceAll('非常', '十分');
  }

  /// 使内容更口语化
  String _makeCasual(String content) {
    return content
        .replaceAll('优秀', '很棒')
        .replaceAll('良好', '不错')
        .replaceAll('诸多', '很多')
        .replaceAll('尤为', '特别')
        .replaceAll('十分', '非常');
  }

  /// 生成个性化系统提示
  String _generatePersonalizedSystemPrompt(UserPreference preference) {
    final parts = <String>[];

    // 语言风格指导
    if (preference.languageStyle != LanguageStyle.unknown) {
      switch (preference.languageStyle) {
        case LanguageStyle.formal:
          parts.add('使用正式、专业的语言风格');
          break;
        case LanguageStyle.casual:
          parts.add('使用口语化、自然的语言风格');
          break;
        case LanguageStyle.mixed:
          parts.add('根据语境灵活调整语言风格');
          break;
        default:
          break;
      }
    }

    // 详细程度指导
    if (preference.detailLevel != DetailLevel.unknown) {
      switch (preference.detailLevel) {
        case DetailLevel.concise:
          parts.add('保持简洁明了的表达方式');
          break;
        case DetailLevel.detailed:
          parts.add('提供详细的信息和解释');
          break;
        case DetailLevel.verbose:
          parts.add('提供全面详细的阐述');
          break;
        default:
          break;
      }
    }

    // 修改偏好指导
    if (preference.modificationAcceptanceRates.isNotEmpty) {
      final highAcceptanceTypes = preference.modificationAcceptanceRates.entries
          .where((e) => e.value > 0.7)
          .map((e) => _describeModificationType(e.key))
          .toList();

      if (highAcceptanceTypes.isNotEmpty) {
        parts.add('用户倾向于接受以下类型的修改：${highAcceptanceTypes.join('、')}');
      }
    }

    // 主题兴趣
    if (preference.topicInterests.isNotEmpty) {
      final topTopics = preference.topicInterests.entries
          .where((e) => e.value > 0.5)
          .map((e) => e.key)
          .take(5)
          .toList();

      if (topTopics.isNotEmpty) {
        parts.add('用户对以下主题特别关注：${topTopics.join('、')}');
      }
    }

    return parts.isEmpty
        ? ''
        : '个性化要求：\n${parts.map((p) => '- $p').join('\n')}';
  }

  /// 描述修改类型
  String _describeModificationType(ModificationType type) {
    switch (type) {
      case ModificationType.grammar:
        return '语法修正';
      case ModificationType.spelling:
        return '拼写修正';
      case ModificationType.style:
        return '风格改进';
      case ModificationType.expansion:
        return '内容扩展';
      case ModificationType.simplification:
        return '内容精简';
      case ModificationType.structure:
        return '结构调整';
      case ModificationType.vocabulary:
        return '词汇替换';
      case ModificationType.other:
        return '其他修改';
    }
  }

  /// 根据用户偏好调整响应
  AIResponse _adjustResponseForPreferences(
    AIResponse response,
    UserPreference preference,
  ) {
    if (!preference.hasSufficientConfidence()) {
      return response;
    }

    // 调整响应内容
    String adjustedContent = response.content;
    adjustedContent = _preferenceManager!.adjustAISuggestion(
      adjustedContent,
      response.content,
    );

    return AIResponse(
      id: response.id,
      content: adjustedContent,
      model: response.model,
      inputTokens: response.inputTokens,
      outputTokens: response.outputTokens,
      finishReason: response.finishReason,
      metadata: {
        ...?response.metadata,
        'personalized': true,
        'preferenceApplied': true,
        'originalContent': response.content,
      },
    );
  }

  /// 调整流式响应的chunk
  AIStreamChunk _adjustChunkForPreferences(
    AIStreamChunk chunk,
    UserPreference preference,
  ) {
    if (!preference.hasSufficientConfidence()) {
      return chunk;
    }

    // 对于流式响应，我们通常不在每个chunk上应用偏好
    // 因为这会破坏文本的连贯性
    // 但我们可以标记这些信息，让最终响应知道可以应用偏好
    return chunk;
  }

  /// 记录用户反馈
  Future<void> recordFeedback({
    required String originalText,
    required String suggestedText,
    required String finalText,
    String? context,
    List<String>? topics,
  }) async {
    _ensureInitialized();

    // 检测修改类型
    final modificationType = _feedbackCollector!.detectModificationType(
      originalText,
      suggestedText,
    );

    // 判断反馈类型
    FeedbackType feedbackType;
    if (finalText == suggestedText) {
      feedbackType = FeedbackType.accepted;
    } else if (finalText == originalText) {
      feedbackType = FeedbackType.rejected;
    } else {
      feedbackType = FeedbackType.partiallyAccepted;
    }

    // 创建反馈记录
    final feedback = UserFeedback.create(
      feedbackType: feedbackType,
      modificationType: modificationType,
      originalText: originalText,
      modifiedText: suggestedText,
      finalText: finalText,
      context: context,
      topics: topics,
    );

    // 添加到偏好管理器
    await _preferenceManager!.addFeedback(feedback);
  }

  /// 分析用户写作
  Future<WritingAnalysis> analyzeUserWriting(String text,
      {String? context}) async {
    _ensureInitialized();
    return await _preferenceManager!.analyzeWriting(text, context: context);
  }

  /// 获取个性化建议
  Map<String, dynamic> getPersonalizationSuggestions(String text) {
    _ensureInitialized();
    return _preferenceManager!.getPersonalizedSuggestions(text);
  }

  /// 获取学习统计
  Map<String, dynamic> getLearningStats() {
    _ensureInitialized();
    return _preferenceManager!.getLearningStats();
  }

  /// 获取隐私报告
  Future<Map<String, dynamic>> getPrivacyReport() async {
    _ensureInitialized();
    return await _preferenceManager!.getPrivacyReport();
  }

  /// 重置偏好数据
  Future<void> resetPreferences() async {
    _ensureInitialized();
    await _preferenceManager!.resetPreferences();
  }

  /// 清除所有数据
  Future<void> clearAllData() async {
    _ensureInitialized();
    await _preferenceManager!.clearAllData();
  }

  /// 获取偏好更新流
  Stream<UserPreference> get preferenceUpdates {
    _ensureInitialized();
    return _preferenceManager!.preferenceUpdates;
  }

  /// 获取当前用户偏好
  UserPreference? get currentPreference {
    _ensureInitialized();
    return _preferenceManager!.currentPreference;
  }

  /// 获取学习配置
  PreferenceLearningConfig get learningConfig {
    _ensureInitialized();
    return _preferenceManager!.config;
  }

  /// 更新学习配置
  Future<void> updateLearningConfig(PreferenceLearningConfig config) async {
    _ensureInitialized();
    await _preferenceManager!.updateConfig(config);
  }

  /// 代理基础服务方法
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
  void dispose() => _baseService.dispose();
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
}

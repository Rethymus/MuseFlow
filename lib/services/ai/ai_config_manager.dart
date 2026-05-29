import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../models/ai_config.dart';

/// AI配置管理器
/// 提供便捷的配置创建和管理功能
class AIConfigManager {
  static const Uuid _uuid = Uuid();

  /// 创建OpenAI配置
  static AIConfig createOpenAIConfig({
    required String apiKey,
    String? baseUrl,
    String model = 'gpt-4o',
    int maxTokens = 2048,
    double temperature = 0.7,
    double topP = 1.0,
    int? retryCount,
    int? timeoutSeconds,
  }) {
    return AIConfig(
      id: _uuid.v4(),
      provider: AIProvider.openai,
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      retryCount: retryCount,
      timeoutSeconds: timeoutSeconds,
    );
  }

  /// 创建Anthropic配置
  static AIConfig createAnthropicConfig({
    required String apiKey,
    String? baseUrl,
    String model = 'claude-3-5-sonnet-20241022',
    int maxTokens = 2048,
    double temperature = 0.7,
    int? retryCount,
    int? timeoutSeconds,
  }) {
    return AIConfig(
      id: _uuid.v4(),
      provider: AIProvider.anthropic,
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
      retryCount: retryCount,
      timeoutSeconds: timeoutSeconds,
    );
  }

  /// 创建DeepSeek配置
  static AIConfig createDeepSeekConfig({
    required String apiKey,
    String? baseUrl,
    String model = 'deepseek-chat',
    int maxTokens = 2048,
    double temperature = 0.7,
    double topP = 1.0,
    int? retryCount,
    int? timeoutSeconds,
  }) {
    return AIConfig(
      id: _uuid.v4(),
      provider: AIProvider.deepseek,
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      retryCount: retryCount,
      timeoutSeconds: timeoutSeconds,
    );
  }

  /// 创建Ollama配置
  static AIConfig createOllamaConfig({
    String? baseUrl,
    String model = 'llama3',
    int maxTokens = 2048,
    double temperature = 0.7,
    int? timeoutSeconds,
  }) {
    return AIConfig(
      id: _uuid.v4(),
      provider: AIProvider.ollama,
      apiKey: '', // Ollama不需要API Key
      baseUrl: baseUrl,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
      timeoutSeconds: timeoutSeconds ?? 120,
    );
  }

  /// 从JSON创建配置
  static AIConfig? fromJson(Map<String, dynamic> json) {
    try {
      return AIConfig.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// 从JSON字符串创建配置
  static AIConfig? fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      return fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// 克隆配置
  static AIConfig clone(AIConfig config) {
    return config.copyWith(id: _uuid.v4());
  }

  /// 验证配置
  static String? validate(AIConfig config) {
    // 检查API Key
    if (config.provider.requiresApiKey) {
      if (config.apiKey.isEmpty) {
        return 'API Key is required for ${config.provider.name}';
      }
    }

    // 检查模型名称
    if (config.model.isEmpty) {
      return 'Model name is required';
    }

    // 检查温度范围
    if (config.temperature < 0 || config.temperature > 2) {
      return 'Temperature must be between 0 and 2';
    }

    // 检查TopP范围
    if (config.topP < 0 || config.topP > 1) {
      return 'Top P must be between 0 and 1';
    }

    // 检查最大Token数
    if (config.maxTokens < 1) {
      return 'Max tokens must be greater than 0';
    }

    // 检查超时时间
    if (config.timeoutSeconds != null && config.timeoutSeconds! < 1) {
      return 'Timeout must be greater than 0 seconds';
    }

    return null;
  }

  /// 获取推荐的模型配置
  static Map<String, dynamic> getRecommendedModelParams(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return {
          'temperature': 0.7,
          'max_tokens': 2048,
          'top_p': 1.0,
          'frequency_penalty': 0,
          'presence_penalty': 0,
        };
      case AIProvider.anthropic:
        return {
          'temperature': 0.7,
          'max_tokens': 2048,
          'top_p': 1.0,
        };
      case AIProvider.deepseek:
        return {
          'temperature': 0.7,
          'max_tokens': 2048,
          'top_p': 1.0,
        };
      case AIProvider.ollama:
        return {
          'temperature': 0.7,
          'num_ctx': 2048,
          'top_k': 40,
          'top_p': 0.9,
        };
    }
  }

  /// 获取供应商的默认配置
  static AIConfig getDefaultConfig(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return createOpenAIConfig(apiKey: '');
      case AIProvider.anthropic:
        return createAnthropicConfig(apiKey: '');
      case AIProvider.deepseek:
        return createDeepSeekConfig(apiKey: '');
      case AIProvider.ollama:
        return createOllamaConfig();
    }
  }

  /// 比较两个配置是否相等（忽略ID）
  static bool isEqual(AIConfig a, AIConfig b) {
    return a.provider == b.provider &&
        a.apiKey == b.apiKey &&
        a.baseUrl == b.baseUrl &&
        a.model == b.model &&
        a.maxTokens == b.maxTokens &&
        a.temperature == b.temperature &&
        a.topP == b.topP;
  }

  /// 导出配置为JSON字符串
  static String exportToJson(AIConfig config) {
    return jsonEncode(config.toJson());
  }

  /// 批量导出配置
  static String exportToJsonList(List<AIConfig> configs) {
    final jsonList = configs.map((config) => config.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// 批量导入配置
  static List<AIConfig> importFromJsonList(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final configs = <AIConfig>[];

      for (final json in jsonList) {
        if (json is Map<String, dynamic>) {
          final config = fromJson(json);
          if (config != null) {
            configs.add(config);
          }
        }
      }

      return configs;
    } catch (e) {
      return [];
    }
  }

  /// 生成配置描述
  static String getDescription(AIConfig config) {
    final buffer = StringBuffer();
    buffer.write('${config.provider.name} - ');
    buffer.write(config.model);

    if (config.baseUrl != null && config.baseUrl!.isNotEmpty) {
      buffer.write(' (${config.baseUrl})');
    }

    return buffer.toString();
  }

  /// 检查配置是否需要更新
  static bool needsUpdate(AIConfig config, AIConfig? newConfig) {
    if (newConfig == null) return false;
    return !isEqual(config, newConfig);
  }
}

/// AI配置预设
class AIConfigPresets {
  /// 获取快速响应预设
  static AIConfig getFastResponse(AIProvider provider) {
    final baseConfig = AIConfigManager.getDefaultConfig(provider);
    return baseConfig.copyWith(
      temperature: 0.3,
      maxTokens: 512,
    );
  }

  /// 获取创意写作预设
  static AIConfig getCreativeWriting(AIProvider provider) {
    final baseConfig = AIConfigManager.getDefaultConfig(provider);
    return baseConfig.copyWith(
      temperature: 0.9,
      maxTokens: 4096,
    );
  }

  /// 获取代码生成预设
  static AIConfig getCodeGeneration(AIProvider provider) {
    final baseConfig = AIConfigManager.getDefaultConfig(provider);
    return baseConfig.copyWith(
      temperature: 0.2,
      maxTokens: 2048,
    );
  }

  /// 获取分析预设
  static AIConfig getAnalysis(AIProvider provider) {
    final baseConfig = AIConfigManager.getDefaultConfig(provider);
    return baseConfig.copyWith(
      temperature: 0.5,
      maxTokens: 1024,
    );
  }

  /// 获取长文本生成预设
  static AIConfig getLongForm(AIProvider provider) {
    final baseConfig = AIConfigManager.getDefaultConfig(provider);
    return baseConfig.copyWith(
      temperature: 0.7,
      maxTokens: 8192,
    );
  }
}

/// AI配置模型
/// 存储不同AI供应商的配置信息
class AIConfig {
  final String id;
  final AIProvider provider;
  final String apiKey;
  final String? baseUrl;
  final String model;
  final Map<String, dynamic>? modelParameters;
  final int maxTokens;
  final double temperature;
  final double topP;
  final int? retryCount;
  final int? timeoutSeconds;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool isActive;

  AIConfig({
    required this.id,
    required this.provider,
    required this.apiKey,
    this.baseUrl,
    required this.model,
    this.modelParameters,
    this.maxTokens = 2048,
    this.temperature = 0.7,
    this.topP = 1.0,
    this.retryCount = 3,
    this.timeoutSeconds = 30,
    DateTime? createdAt,
    this.lastUsedAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 获取默认base URL（如果未自定义）
  String get effectiveBaseUrl {
    return baseUrl ?? provider.defaultBaseUrl;
  }

  /// 获取重试次数
  int get effectiveRetryCount => retryCount ?? provider.defaultRetryCount;

  /// 获取超时时间
  int get effectiveTimeout => timeoutSeconds ?? provider.defaultTimeout;

  /// 转换为JSON（用于加密存储）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider.toString(),
      'apiKey': apiKey, // 这个会被加密
      'baseUrl': baseUrl,
      'model': model,
      'modelParameters': modelParameters,
      'maxTokens': maxTokens,
      'temperature': temperature,
      'topP': topP,
      'retryCount': retryCount,
      'timeoutSeconds': timeoutSeconds,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory AIConfig.fromJson(Map<String, dynamic> json) {
    return AIConfig(
      id: json['id'] as String,
      provider: AIProvider.fromString(json['provider'] as String),
      apiKey: json['apiKey'] as String,
      baseUrl: json['baseUrl'] as String?,
      model: json['model'] as String,
      modelParameters: json['modelParameters'] as Map<String, dynamic>?,
      maxTokens: json['maxTokens'] as int? ?? 2048,
      temperature: json['temperature'] as double? ?? 0.7,
      topP: json['topP'] as double? ?? 1.0,
      retryCount: json['retryCount'] as int?,
      timeoutSeconds: json['timeoutSeconds'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// 创建配置副本
  AIConfig copyWith({
    String? id,
    AIProvider? provider,
    String? apiKey,
    String? baseUrl,
    String? model,
    Map<String, dynamic>? modelParameters,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? retryCount,
    int? timeoutSeconds,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isActive,
  }) {
    return AIConfig(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      modelParameters: modelParameters ?? this.modelParameters,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      retryCount: retryCount ?? this.retryCount,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// 更新最后使用时间
  AIConfig updateLastUsed() {
    return copyWith(lastUsedAt: DateTime.now());
  }
}

/// AI供应商枚举
enum AIProvider {
  openai(
    name: 'OpenAI',
    defaultBaseUrl: 'https://api.openai.com/v1',
    defaultTimeout: 30,
    defaultRetryCount: 3,
  ),
  anthropic(
    name: 'Anthropic',
    defaultBaseUrl: 'https://api.anthropic.com/v1',
    defaultTimeout: 60,
    defaultRetryCount: 2,
  ),
  deepseek(
    name: 'DeepSeek',
    defaultBaseUrl: 'https://api.deepseek.com/v1',
    defaultTimeout: 30,
    defaultRetryCount: 3,
  ),
  ollama(
    name: 'Ollama',
    defaultBaseUrl: 'http://localhost:11434/v1',
    defaultTimeout: 120,
    defaultRetryCount: 1,
  );

  final String name;
  final String defaultBaseUrl;
  final int defaultTimeout;
  final int defaultRetryCount;

  const AIProvider({
    required this.name,
    required this.defaultBaseUrl,
    required this.defaultTimeout,
    required this.defaultRetryCount,
  });

  static AIProvider fromString(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return AIProvider.openai;
      case 'anthropic':
        return AIProvider.anthropic;
      case 'deepseek':
        return AIProvider.deepseek;
      case 'ollama':
        return AIProvider.ollama;
      default:
        throw ArgumentError('Unknown AI provider: $provider');
    }
  }

  @override
  String toString() {
    return name;
  }

  /// 获取推荐的模型列表
  List<String> get recommendedModels {
    switch (this) {
      case AIProvider.openai:
        return ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo'];
      case AIProvider.anthropic:
        return ['claude-3-5-sonnet-20241022', 'claude-3-haiku-20240307'];
      case AIProvider.deepseek:
        return ['deepseek-chat', 'deepseek-coder'];
      case AIProvider.ollama:
        return ['llama3', 'mistral', 'neural-chat', 'starcoder'];
    }
  }

  /// 获取默认模型
  String get defaultModel {
    return recommendedModels.first;
  }

  /// 是否需要API Key
  bool get requiresApiKey => this != AIProvider.ollama;
}

/// 模型参数配置
class ModelParameters {
  final int? maxTokens;
  final double? temperature;
  final double? topP;
  final double? frequencyPenalty;
  final double? presencePenalty;
  final List<String>? stopSequences;
  final Map<String, dynamic>? extra;

  ModelParameters({
    this.maxTokens,
    this.temperature,
    this.topP,
    this.frequencyPenalty,
    this.presencePenalty,
    this.stopSequences,
    this.extra,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (maxTokens != null) map['max_tokens'] = maxTokens;
    if (temperature != null) map['temperature'] = temperature;
    if (topP != null) map['top_p'] = topP;
    if (frequencyPenalty != null) map['frequency_penalty'] = frequencyPenalty;
    if (presencePenalty != null) map['presence_penalty'] = presencePenalty;
    if (stopSequences != null) map['stop'] = stopSequences;
    if (extra != null) map.addAll(extra!);
    return map;
  }

  factory ModelParameters.fromConfig(AIConfig config) {
    return ModelParameters(
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      topP: config.topP,
    );
  }
}

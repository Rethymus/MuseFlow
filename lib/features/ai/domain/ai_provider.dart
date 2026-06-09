/// AI provider type enumeration.
///
/// Each type corresponds to a known API provider with preset configuration.
enum AiProviderType {
  openai('openai'),
  deepseek('deepseek'),
  ollama('ollama'),
  claude('claude'),
  custom('custom');

  const AiProviderType(this.value);

  /// String value for JSON serialization.
  final String value;

  /// Creates an [AiProviderType] from its string value.
  static AiProviderType fromString(String value) {
    return AiProviderType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AiProviderType.custom,
    );
  }
}

/// Sentinel value for [AIProvider.copyWith] to distinguish "not provided"
/// from "explicitly set to null". Used because Dart optional parameters
/// cannot differentiate between omitted and passed-as-null.
const _nullSentinel = Object();

/// An AI provider configuration entity.
///
/// Immutable entity representing a configured AI model provider.
/// Use [copyWith] to create modified copies.
///
/// Per D-03: [temperature], [topP], and [maxTokens] are nullable model
/// parameters. Null means "use the model's default" -- the API request
/// omits these fields when null.
class AIProvider {
  final String id;
  final String name;
  final String baseUrl;
  final AiProviderType type;
  final String model;
  final bool isActive;
  final DateTime createdAt;

  /// Model sampling temperature. Range 0.0-2.0. Null = model default.
  final double? temperature;

  /// Nucleus sampling threshold. Range 0.0-1.0. Null = model default.
  final double? topP;

  /// Maximum tokens in the response. Range 1-128000. Null = model default.
  final int? maxTokens;

  const AIProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.type,
    required this.model,
    this.isActive = false,
    required this.createdAt,
    this.temperature,
    this.topP,
    this.maxTokens,
  });

  /// Creates a copy of this provider with the given fields replaced.
  ///
  /// To explicitly set [temperature], [topP], or [maxTokens] back to null,
  /// pass `null` as the value. Omitting the parameter preserves the current
  /// value.
  AIProvider copyWith({
    String? id,
    String? name,
    String? baseUrl,
    AiProviderType? type,
    String? model,
    bool? isActive,
    DateTime? createdAt,
    Object? temperature = _nullSentinel,
    Object? topP = _nullSentinel,
    Object? maxTokens = _nullSentinel,
  }) {
    return AIProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      type: type ?? this.type,
      model: model ?? this.model,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      temperature: temperature == _nullSentinel
          ? this.temperature
          : temperature as double?,
      topP: topP == _nullSentinel ? this.topP : topP as double?,
      maxTokens: maxTokens == _nullSentinel
          ? this.maxTokens
          : maxTokens as int?,
    );
  }

  /// Creates an [AIProvider] from a JSON map.
  factory AIProvider.fromJson(Map<String, dynamic> json) {
    return AIProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      type: AiProviderType.fromString(json['type'] as String),
      model: json['model'] as String,
      isActive: json['isActive'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      temperature: json['temperature'] as double?,
      topP: json['topP'] as double?,
      maxTokens: json['maxTokens'] as int?,
    );
  }

  /// Serializes this provider to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'type': type.value,
      'model': model,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'temperature': temperature,
      'topP': topP,
      'maxTokens': maxTokens,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIProvider &&
        other.id == id &&
        other.name == name &&
        other.baseUrl == baseUrl &&
        other.type == type &&
        other.model == model &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.temperature == temperature &&
        other.topP == topP &&
        other.maxTokens == maxTokens;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    baseUrl,
    type,
    model,
    isActive,
    createdAt,
    temperature,
    topP,
    maxTokens,
  );

  @override
  String toString() =>
      'AIProvider(id: $id, name: $name, baseUrl: $baseUrl, type: $type, '
      'model: $model, isActive: $isActive, temperature: $temperature, '
      'topP: $topP, maxTokens: $maxTokens, createdAt: $createdAt)';
}

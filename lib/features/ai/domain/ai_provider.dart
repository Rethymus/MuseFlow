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

/// An AI provider configuration entity.
///
/// Immutable entity representing a configured AI model provider.
/// Use [copyWith] to create modified copies.
class AIProvider {
  final String id;
  final String name;
  final String baseUrl;
  final AiProviderType type;
  final String model;
  final bool isActive;
  final DateTime createdAt;

  const AIProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.type,
    required this.model,
    this.isActive = false,
    required this.createdAt,
  });

  /// Creates a copy of this provider with the given fields replaced.
  AIProvider copyWith({
    String? id,
    String? name,
    String? baseUrl,
    AiProviderType? type,
    String? model,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AIProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      type: type ?? this.type,
      model: model ?? this.model,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
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
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, baseUrl, type, model, isActive, createdAt);

  @override
  String toString() =>
      'AIProvider(id: $id, name: $name, baseUrl: $baseUrl, type: $type, '
      'model: $model, isActive: $isActive, createdAt: $createdAt)';
}

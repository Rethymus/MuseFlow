/// AI服务共享类型定义
/// 包含ContextualAIService和RealTimeWritingAssistant共用的类型

/// 建议类型
enum SuggestionType {
  style,
  vocabulary,
  grammar,
  structure,
  content,
}

/// 情感基调（合并自EmotionTone和EmotionalTone）
enum EmotionTone {
  positive,
  negative,
  emotional,
  neutral,
}

/// 上下文建议（合并自两个服务的定义）
class ContextualSuggestion {
  final SuggestionType type;
  final String title;
  final String description;
  final double confidence;
  final DateTime timestamp;
  final String? applicableText;

  ContextualSuggestion({
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    DateTime? timestamp,
    this.applicableText,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type.toString(),
        'title': title,
        'description': description,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'applicableText': applicableText,
      };
}

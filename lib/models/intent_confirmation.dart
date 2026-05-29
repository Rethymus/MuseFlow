/// AI操作类型枚举
enum AIActionType {
  polish,
  expand,
  outline,
  summarize,
  changeStyle,
  smartReplace,
}

/// 意图确认模型
/// 在执行AI操作前，用于展示和确认AI对用户意图的理解
class IntentConfirmation {
  final String id;
  final AIActionType actionType;
  final String description;
  final String originalText;
  final Map<String, dynamic> parameters;
  final String explanation;
  final String expectedOutcome;
  final DateTime timestamp;

  IntentConfirmation({
    required this.id,
    required this.actionType,
    required this.description,
    required this.originalText,
    required this.parameters,
    required this.explanation,
    required this.expectedOutcome,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 复制并更新部分字段
  IntentConfirmation copyWith({
    String? id,
    AIActionType? actionType,
    String? description,
    String? originalText,
    Map<String, dynamic>? parameters,
    String? explanation,
    String? expectedOutcome,
    DateTime? timestamp,
  }) {
    return IntentConfirmation(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      description: description ?? this.description,
      originalText: originalText ?? this.originalText,
      parameters: parameters ?? this.parameters,
      explanation: explanation ?? this.explanation,
      expectedOutcome: expectedOutcome ?? this.expectedOutcome,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType.toString(),
      'description': description,
      'originalText': originalText,
      'parameters': parameters,
      'explanation': explanation,
      'expectedOutcome': expectedOutcome,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// 从JSON创建实例
  factory IntentConfirmation.fromJson(Map<String, dynamic> json) {
    return IntentConfirmation(
      id: json['id'] as String,
      actionType: _parseActionType(json['actionType'] as String),
      description: json['description'] as String,
      originalText: json['originalText'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      explanation: json['explanation'] as String,
      expectedOutcome: json['expectedOutcome'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  /// 解析操作类型
  static AIActionType _parseActionType(String typeString) {
    return AIActionType.values.firstWhere(
      (type) => type.toString() == typeString,
      orElse: () => AIActionType.polish,
    );
  }

  /// 创建唯一ID
  static String generateId() {
    return 'intent_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 创建润色意图
  factory IntentConfirmation.polish({
    required String originalText,
    String? context,
  }) {
    final hasContext = context != null && context.isNotEmpty;
    return IntentConfirmation(
      id: generateId(),
      actionType: AIActionType.polish,
      description: '对选中文本进行润色，使其更加通顺、准确、优雅',
      originalText: originalText,
      parameters: {
        'context': context ?? '',
        'preserve_original': true,
        'style_level': 'moderate',
      },
      explanation: hasContext
          ? '我将润色选中的文本，参考上下文内容使表达更加流畅自然。会保持原意不变，修正语法错误，优化词语选择。'
          : '我将润色选中的文本，使其更加通顺流畅。会保持原意不变，修正语法错误，优化词语选择。',
      expectedOutcome: '润色后的文本将保持原意，表达更加简洁流畅，语法和用词更加准确。',
    );
  }

  /// 创建扩写意图
  factory IntentConfirmation.expand({
    required String originalText,
    String? context,
    int? targetLength,
  }) {
    final hasContext = context != null && context.isNotEmpty;
    return IntentConfirmation(
      id: generateId(),
      actionType: AIActionType.expand,
      description: '对选中文本进行扩写，丰富内容和表达',
      originalText: originalText,
      parameters: {
        'context': context ?? '',
        'target_length': targetLength ?? (originalText.length * 2),
        'expand_ratio': '2x',
      },
      explanation: hasContext
          ? '我将根据原文核心观点进行扩写，参考上下文添加适当的细节和例子，使内容更加丰富完整。'
          : '我将根据原文核心观点进行扩写，添加适当的细节和例子，使内容更加丰富完整。',
      expectedOutcome: '扩写后的文本将保持原文核心观点，内容更加丰富，表达更加详细，自然衔接不生硬。',
    );
  }

  /// 创建大纲意图
  factory IntentConfirmation.outline({
    required String originalText,
    int? maxItems,
  }) {
    return IntentConfirmation(
      id: generateId(),
      actionType: AIActionType.outline,
      description: '为全文生成结构化大纲',
      originalText: originalText,
      parameters: {
        'max_items': maxItems ?? 10,
        'numbering_style': 'numeric',
        'include_details': true,
      },
      explanation: '我将分析全文内容，提取主要观点和论据，按逻辑层次生成结构化大纲。',
      expectedOutcome: '生成的大纲将使用数字编号，层次清晰，简洁明了，包含主要观点和支持细节。',
    );
  }

  /// 创建摘要意图
  factory IntentConfirmation.summarize({
    required String originalText,
    int? maxLength,
  }) {
    return IntentConfirmation(
      id: generateId(),
      actionType: AIActionType.summarize,
      description: '为选中文本生成摘要',
      originalText: originalText,
      parameters: {
        'max_length': maxLength ?? 100,
        'preserve_key_info': true,
        'abstract_type': 'general',
      },
      explanation: '我将提取文本的核心信息，保持逻辑连贯，生成简洁明确的摘要。',
      expectedOutcome: '摘要将包含文本的核心信息，逻辑连贯，简洁明确，字数控制在指定范围内。',
    );
  }

  /// 创建风格转换意图
  factory IntentConfirmation.changeStyle({
    required String originalText,
    required String targetStyle,
  }) {
    return IntentConfirmation(
      id: generateId(),
      actionType: AIActionType.changeStyle,
      description: '将选中文本转换为$targetStyle风格',
      originalText: originalText,
      parameters: {
        'target_style': targetStyle,
        'preserve_core_info': true,
        'conversion_strength': 'natural',
      },
      explanation: '我将调整文本的表达方式以匹配目标风格，同时保持核心信息不变，确保转换自然不生硬。',
      expectedOutcome: '转换后的文本将体现目标风格的特点，核心信息保持不变，表达自然流畅。',
    );
  }

  /// 创建智能替换意图
  factory IntentConfirmation.smartReplace({
    required String originalText,
    required String findText,
    required String replaceWith,
  }) {
    return IntentConfirmation(
      id: generateId(),
      actionType: AIActionType.smartReplace,
      description: '智能替换文本中的"$findText"为"$replaceWith"',
      originalText: originalText,
      parameters: {
        'find_text': findText,
        'replace_with': replaceWith,
        'preserve_context': true,
        'adjust_tense': true,
      },
      explanation: '我将在保持文本连贯性的前提下进行替换，自动调整时态和语态，确保替换后的表达自然。',
      expectedOutcome: '替换后的文本将保持连贯性，时态和语态自动调整，表达自然不生硬。',
    );
  }
}

/// 意图确认反馈
class IntentConfirmationFeedback {
  final String intentId;
  final bool confirmed;
  final String? adjustedDescription;
  final Map<String, dynamic>? adjustedParameters;
  final String? userComment;
  final DateTime timestamp;

  IntentConfirmationFeedback({
    required this.intentId,
    required this.confirmed,
    this.adjustedDescription,
    this.adjustedParameters,
    this.userComment,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'intentId': intentId,
      'confirmed': confirmed,
      'adjustedDescription': adjustedDescription,
      'adjustedParameters': adjustedParameters,
      'userComment': userComment,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// 从JSON创建实例
  factory IntentConfirmationFeedback.fromJson(Map<String, dynamic> json) {
    return IntentConfirmationFeedback(
      intentId: json['intentId'] as String,
      confirmed: json['confirmed'] as bool,
      adjustedDescription: json['adjustedDescription'] as String?,
      adjustedParameters: json['adjustedParameters'] as Map<String, dynamic>?,
      userComment: json['userComment'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }
}

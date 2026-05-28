/// AI响应模型
/// 包含AI返回的完整响应信息
class AIResponse {
  final String id;
  final String content;
  final String model;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final String? finishReason;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  AIResponse({
    required this.id,
    required this.content,
    required this.model,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    this.finishReason,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 计算总token数（如果没有提供）
  int get calculatedTotalTokens {
    return totalTokens ?? (inputTokens ?? 0) + (outputTokens ?? 0);
  }

  /// 是否响应完成
  bool get isFinished => finishReason == 'stop' || finishReason == 'eos';

  /// 是否因为长度限制而停止
  bool get isLengthLimited => finishReason == 'length';

  /// 是否因为内容过滤而停止
  bool get isContentFiltered => finishReason == 'content_filter';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'model': model,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalTokens': totalTokens,
      'finishReason': finishReason,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      id: json['id'] as String,
      content: json['content'] as String,
      model: json['model'] as String,
      inputTokens: json['inputTokens'] as int?,
      outputTokens: json['outputTokens'] as int?,
      totalTokens: json['totalTokens'] as int?,
      finishReason: json['finishReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  AIResponse copyWith({
    String? id,
    String? content,
    String? model,
    int? inputTokens,
    int? outputTokens,
    int? totalTokens,
    String? finishReason,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return AIResponse(
      id: id ?? this.id,
      content: content ?? this.content,
      model: model ?? this.model,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      finishReason: finishReason ?? this.finishReason,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// 创建简化的响应摘要
  String toSummary() {
    final buffer = StringBuffer();
    buffer.write('Model: $model');
    if (totalTokens != null) {
      buffer.write(', Tokens: $totalTokens');
    }
    if (finishReason != null) {
      buffer.write(', Finish: $finishReason');
    }
    return buffer.toString();
  }
}

/// 流式响应块
class AIStreamChunk {
  final String content;
  final bool isComplete;
  final String? finishReason;
  final int? inputTokens;
  final int? outputTokens;

  AIStreamChunk({
    required this.content,
    this.isComplete = false,
    this.finishReason,
    this.inputTokens,
    this.outputTokens,
  });

  factory AIStreamChunk.complete({
    required String content,
    String? finishReason,
    int? inputTokens,
    int? outputTokens,
  }) {
    return AIStreamChunk(
      content: content,
      isComplete: true,
      finishReason: finishReason,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );
  }

  factory AIStreamChunk.incomplete(String content) {
    return AIStreamChunk(
      content: content,
      isComplete: false,
    );
  }

  /// 转换为完整的AIResponse
  AIResponse toResponse({
    required String id,
    required String model,
    Map<String, dynamic>? metadata,
  }) {
    return AIResponse(
      id: id,
      content: content,
      model: model,
      finishReason: finishReason,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: (inputTokens ?? 0) + (outputTokens ?? 0),
      metadata: metadata,
    );
  }
}

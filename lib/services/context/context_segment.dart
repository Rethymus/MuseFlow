/// 上下文片段数据模型
///
/// 用于表示和管理对话历史中的单个片段
library;

import 'package:uuid/uuid.dart';

enum SegmentType {
  /// 用户消息
  userMessage,

  /// 系统响应
  systemResponse,

  /// 系统提示
  systemPrompt,

  /// 工具调用
  toolCall,

  /// 工具结果
  toolResult,

  /// 元数据
  metadata,
}

class ContextSegment {
  /// 唯一标识符
  final String id;

  /// 片段类型
  final SegmentType type;

  /// 内容文本
  final String content;

  /// 创建时间
  final DateTime createdAt;

  /// 重要性评分 (0.0-1.0)
  final double importanceScore;

  /// 估算的token数量
  final int estimatedTokens;

  /// 是否被锁定（不会被裁剪）
  final bool isLocked;

  /// 相关的元数据
  final Map<String, dynamic> metadata;

  /// 摘要（如果原始内容被压缩）
  final String? summary;

  /// 是否为摘要
  final bool isSummary;

  ContextSegment({
    String? id,
    required this.type,
    required this.content,
    DateTime? createdAt,
    this.importanceScore = 0.5,
    int? estimatedTokens,
    this.isLocked = false,
    this.metadata = const {},
    this.summary,
    this.isSummary = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       estimatedTokens = estimatedTokens ?? _estimateTokens(content);

  /// 计算中文字符的token数量
  /// 中文大约1.5字/token，英文大约4字/token
  static int _estimateTokens(String text) {
    if (text.isEmpty) return 0;

    int chineseChars = 0;
    int otherChars = 0;

    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      // 中文字符范围
      if (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) {
        chineseChars++;
      } else {
        otherChars++;
      }
    }

    // 中文约1.5字/token，英文约4字符/token
    return ((chineseChars / 1.5) + (otherChars / 4.0)).ceil();
  }

  /// 创建摘要版本
  ContextSegment asSummary(String summary) {
    return ContextSegment(
      id: id,
      type: type,
      content: summary,
      createdAt: createdAt,
      importanceScore: importanceScore,
      isLocked: isLocked,
      metadata: metadata,
      summary: content, // 保存原始内容作为摘要
      isSummary: true,
    );
  }

  /// 计算与另一个片段的相似度
  double similarityWith(ContextSegment other) {
    if (this.id == other.id) return 1.0;

    // 简单的内容相似度计算
    final thisWords = content.toLowerCase().split(RegExp(r'\s+'));
    final otherWords = other.content.toLowerCase().split(RegExp(r'\s+'));

    if (thisWords.isEmpty || otherWords.isEmpty) return 0.0;

    final intersection = thisWords.toSet().intersection(otherWords.toSet());
    final union = thisWords.toSet().union(otherWords.toSet());

    return intersection.length / union.length;
  }

  /// 创建副本
  ContextSegment copyWith({
    String? id,
    SegmentType? type,
    String? content,
    DateTime? createdAt,
    double? importanceScore,
    int? estimatedTokens,
    bool? isLocked,
    Map<String, dynamic>? metadata,
    String? summary,
    bool? isSummary,
  }) {
    return ContextSegment(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      importanceScore: importanceScore ?? this.importanceScore,
      estimatedTokens: estimatedTokens ?? this.estimatedTokens,
      isLocked: isLocked ?? this.isLocked,
      metadata: metadata ?? this.metadata,
      summary: summary ?? this.summary,
      isSummary: isSummary ?? this.isSummary,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'importanceScore': importanceScore,
      'estimatedTokens': estimatedTokens,
      'isLocked': isLocked,
      'metadata': metadata,
      'summary': summary,
      'isSummary': isSummary,
    };
  }

  /// 从JSON创建
  factory ContextSegment.fromJson(Map<String, dynamic> json) {
    return ContextSegment(
      id: json['id'] as String,
      type: SegmentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => SegmentType.metadata,
      ),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      importanceScore: json['importanceScore'] as double,
      estimatedTokens: json['estimatedTokens'] as int,
      isLocked: json['isLocked'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>,
      summary: json['summary'] as String?,
      isSummary: json['isSummary'] as bool,
    );
  }

  @override
  String toString() {
    return 'ContextSegment(id: $id, type: $type, tokens: $estimatedTokens, importance: $importanceScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContextSegment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

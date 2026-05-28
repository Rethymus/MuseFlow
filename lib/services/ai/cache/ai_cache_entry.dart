/// AI缓存条目模型
/// 存储单个AI请求的缓存数据
class AICacheEntry {
  final String cacheKey;
  final String content;
  final String model;
  final int? inputTokens;
  final int? outputTokens;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int hitCount;
  final DateTime lastAccessAt;
  final Map<String, dynamic>? metadata;

  AICacheEntry({
    required this.cacheKey,
    required this.content,
    required this.model,
    this.inputTokens,
    this.outputTokens,
    required this.createdAt,
    required this.expiresAt,
    this.hitCount = 0,
    required this.lastAccessAt,
    this.metadata,
  });

  /// 是否过期
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// 是否即将过期（1小时内）
  bool get isExpiringSoon {
    final hourFromNow = DateTime.now().add(const Duration(hours: 1));
    return expiresAt.isBefore(hourFromNow);
  }

  /// 缓存年龄（秒）
  int get ageInSeconds {
    return DateTime.now().difference(createdAt).inSeconds;
  }

  /// 剩余时间（秒）
  int get remainingSeconds {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inSeconds;
  }

  /// 计算总token数
  int get totalTokens => (inputTokens ?? 0) + (outputTokens ?? 0);

  /// 创建副本
  AICacheEntry copyWith({
    String? cacheKey,
    String? content,
    String? model,
    int? inputTokens,
    int? outputTokens,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? hitCount,
    DateTime? lastAccessAt,
    Map<String, dynamic>? metadata,
  }) {
    return AICacheEntry(
      cacheKey: cacheKey ?? this.cacheKey,
      content: content ?? this.content,
      model: model ?? this.model,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      hitCount: hitCount ?? this.hitCount,
      lastAccessAt: lastAccessAt ?? this.lastAccessAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 更新访问信息
  AICacheEntry updateAccess() {
    return copyWith(
      hitCount: hitCount + 1,
      lastAccessAt: DateTime.now(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'cacheKey': cacheKey,
      'content': content,
      'model': model,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'hitCount': hitCount,
      'lastAccessAt': lastAccessAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// 从JSON创建
  factory AICacheEntry.fromJson(Map<String, dynamic> json) {
    return AICacheEntry(
      cacheKey: json['cacheKey'] as String,
      content: json['content'] as String,
      model: json['model'] as String,
      inputTokens: json['inputTokens'] as int?,
      outputTokens: json['outputTokens'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      hitCount: json['hitCount'] as int? ?? 0,
      lastAccessAt: DateTime.parse(json['lastAccessAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 创建缓存摘要
  String toSummary() {
    final buffer = StringBuffer();
    buffer.write('CacheEntry[key=$cacheKey, ');
    buffer.write('model=$model, ');
    buffer.write('tokens=$totalTokens, ');
    buffer.write('hits=$hitCount, ');
    buffer.write('age=${ageInSeconds}s, ');
    buffer.write('expires_in=${remainingSeconds}s]');
    return buffer.toString();
  }
}

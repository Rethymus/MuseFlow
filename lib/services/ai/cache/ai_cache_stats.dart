/// AI缓存统计模型
/// 提供缓存性能指标和统计信息
class AICacheStats {
  final int totalRequests;
  final int cacheHits;
  final int cacheMisses;
  final int totalHits;
  final int totalMisses;
  final double hitRate;
  final double avgResponseTime;
  final int tokensSaved;
  final int requestsSaved;
  final DateTime resetAt;
  final DateTime lastUpdated;

  AICacheStats({
    required this.totalRequests,
    required this.cacheHits,
    required this.cacheMisses,
    required this.totalHits,
    required this.totalMisses,
    required this.hitRate,
    required this.avgResponseTime,
    required this.tokensSaved,
    required this.requestsSaved,
    required this.resetAt,
    required this.lastUpdated,
  });

  /// 创建初始统计
  factory AICacheStats.initial() {
    final now = DateTime.now();
    return AICacheStats(
      totalRequests: 0,
      cacheHits: 0,
      cacheMisses: 0,
      totalHits: 0,
      totalMisses: 0,
      hitRate: 0.0,
      avgResponseTime: 0.0,
      tokensSaved: 0,
      requestsSaved: 0,
      resetAt: now,
      lastUpdated: now,
    );
  }

  /// 是否有数据
  bool get hasData => totalRequests > 0;

  /// 缓存命中率百分比
  double get hitRatePercentage => hitRate * 100;

  /// 缓存效率（命中率 > 45% 为良好）
  bool get isEfficient => hitRate >= 0.45;

  /// 是否达到目标命中率
  bool get meetsTarget => hitRate >= 0.45;

  /// 每小时请求数（估算）
  double get requestsPerHour {
    final hours = DateTime.now().difference(resetAt).inSeconds / 3600;
    return hours > 0 ? totalRequests / hours : 0;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'totalRequests': totalRequests,
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'totalHits': totalHits,
      'totalMisses': totalMisses,
      'hitRate': hitRate,
      'avgResponseTime': avgResponseTime,
      'tokensSaved': tokensSaved,
      'requestsSaved': requestsSaved,
      'resetAt': resetAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// 从JSON创建
  factory AICacheStats.fromJson(Map<String, dynamic> json) {
    return AICacheStats(
      totalRequests: json['totalRequests'] as int,
      cacheHits: json['cacheHits'] as int,
      cacheMisses: json['cacheMisses'] as int,
      totalHits: json['totalHits'] as int,
      totalMisses: json['totalMisses'] as int,
      hitRate: json['hitRate'] as double,
      avgResponseTime: json['avgResponseTime'] as double,
      tokensSaved: json['tokensSaved'] as int,
      requestsSaved: json['requestsSaved'] as int,
      resetAt: DateTime.parse(json['resetAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// 创建副本（用于更新统计）
  AICacheStats copyWith({
    int? totalRequests,
    int? cacheHits,
    int? cacheMisses,
    int? totalHits,
    int? totalMisses,
    double? hitRate,
    double? avgResponseTime,
    int? tokensSaved,
    int? requestsSaved,
    DateTime? resetAt,
    DateTime? lastUpdated,
  }) {
    return AICacheStats(
      totalRequests: totalRequests ?? this.totalRequests,
      cacheHits: cacheHits ?? this.cacheHits,
      cacheMisses: cacheMisses ?? this.cacheMisses,
      totalHits: totalHits ?? this.totalHits,
      totalMisses: totalMisses ?? this.totalMisses,
      hitRate: hitRate ?? this.hitRate,
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
      tokensSaved: tokensSaved ?? this.tokensSaved,
      requestsSaved: requestsSaved ?? this.requestsSaved,
      resetAt: resetAt ?? this.resetAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// 记录缓存命中
  AICacheStats recordHit({int? responseTime, int? tokens}) {
    final now = DateTime.now();
    final newTotalHits = totalHits + 1;
    final newTotalRequests = totalRequests + 1;
    final newHitRate = newTotalHits / newTotalRequests;

    // 更新平均响应时间（移动平均）
    final newAvgResponseTime = responseTime != null
        ? (avgResponseTime * totalHits + responseTime) / newTotalHits
        : avgResponseTime;

    return copyWith(
      totalRequests: newTotalRequests,
      cacheHits: cacheHits + 1,
      totalHits: newTotalHits,
      hitRate: newHitRate,
      avgResponseTime: newAvgResponseTime,
      tokensSaved: tokensSaved + (tokens ?? 0),
      requestsSaved: requestsSaved + 1,
      lastUpdated: now,
    );
  }

  /// 记录缓存未命中
  AICacheStats recordMiss() {
    final now = DateTime.now();
    final newTotalMisses = totalMisses + 1;
    final newTotalRequests = totalRequests + 1;
    final newHitRate = totalHits / newTotalRequests;

    return copyWith(
      totalRequests: newTotalRequests,
      cacheMisses: cacheMisses + 1,
      totalMisses: newTotalMisses,
      hitRate: newHitRate,
      lastUpdated: now,
    );
  }

  /// 重置统计
  AICacheStats reset() {
    return AICacheStats.initial();
  }

  /// 生成统计报告
  String toReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== AI Cache Performance Report ===');
    buffer.writeln('Total Requests: $totalRequests');
    buffer.writeln('Cache Hits: $cacheHits');
    buffer.writeln('Cache Misses: $cacheMisses');
    buffer.writeln('Hit Rate: ${hitRatePercentage.toStringAsFixed(2)}%');
    buffer.writeln('Avg Response Time: ${avgResponseTime.toStringAsFixed(2)}ms');
    buffer.writeln('Tokens Saved: $tokensSaved');
    buffer.writeln('Requests Saved: $requestsSaved');
    buffer.writeln('Efficiency Status: ${isEfficient ? "✓ EFFICIENT" : "✗ NEEDS IMPROVEMENT"}');
    buffer.writeln('Requests/Hour: ${requestsPerHour.toStringAsFixed(1)}');
    buffer.writeln('Last Updated: ${lastUpdated.toIso8601String()}');
    return buffer.toString();
  }

  /// 生成简化的状态字符串
  String toStatusString() {
    return 'Cache: ${hitRatePercentage.toStringAsFixed(1)}% hit rate, '
           '$requestsSaved requests saved, $tokensSaved tokens saved';
  }
}

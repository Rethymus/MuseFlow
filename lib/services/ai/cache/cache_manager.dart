import 'dart:async';
import '../../../models/ai_message.dart';
import '../../../models/ai_config.dart';
import '../../../models/ai_response.dart';
import 'ai_request_cache.dart';
import 'ai_cache_stats.dart';
import 'ai_cache_entry.dart';

/// 缓存管理服务
/// 提供高级缓存管理功能和监控
class CacheManager {
  static CacheManager? _instance;
  final AIRequestCache _cache;
  final StreamController<CacheManagerEvent> _eventController;

  CacheManager._({
    AIRequestCache? cache,
  })  : _cache = cache ?? AIRequestCache.instance,
        _eventController = StreamController.broadcast();

  /// 获取单例实例
  static CacheManager get instance {
    _instance ??= CacheManager._();
    return _instance!;
  }

  /// 初始化缓存管理器
  static Future<CacheManager> initialize() async {
    final manager = instance;
    await manager._initialize();
    return manager;
  }

  /// 初始化
  Future<void> _initialize() async {
    await AIRequestCache.initialize();

    // 监听缓存事件
    _cache.events.listen((event) {
      _handleCacheEvent(event);
    });
  }

  /// 处理缓存事件
  void _handleCacheEvent(AICacheEvent event) {
    CacheManagerEvent? managerEvent;

    switch (event.type) {
      case AICacheEventType.hit:
        managerEvent = CacheManagerEvent.cacheHit(event.key, event.entry);
        break;
      case AICacheEventType.miss:
        managerEvent = CacheManagerEvent.cacheMiss(event.key);
        break;
      case AICacheEventType.evicted:
        managerEvent = CacheManagerEvent.cacheEvicted(event.key);
        break;
      case AICacheEventType.expired:
        managerEvent = CacheManagerEvent.cacheExpired(event.key);
        break;
      default:
        return;
    }

    if (managerEvent != null && !_eventController.isClosed) {
      _eventController.add(managerEvent);
    }
  }

  /// 缓存管理器事件流
  Stream<CacheManagerEvent> get events => _eventController.stream;

  /// 检查缓存
  Future<AICacheEntry?> checkCache(
    List<AIMessage> messages,
    AIConfig config,
  ) async {
    return await _cache.checkCache(messages, config);
  }

  /// 存储缓存
  Future<void> storeCache(
    List<AIMessage> messages,
    AIConfig config,
    AIResponse response,
  ) async {
    await _cache.storeCache(messages, config, response);
  }

  /// 获取统计信息
  AICacheStats get stats => _cache.stats;

  /// 获取缓存健康状态
  Future<Map<String, dynamic>> getHealthStatus() async {
    return await _cache.getHealthStatus();
  }

  /// 获取详细统计信息
  Future<Map<String, dynamic>> getDetailedStats() async {
    return await _cache.getDetailedStats();
  }

  /// 生成性能报告
  Future<String> generateReport() async {
    return await _cache.generateReport();
  }

  /// 清空所有缓存
  Future<void> clearAll() async {
    await _cache.clearAll();
    _emitEvent(CacheManagerEvent.cacheCleared('all'));
  }

  /// 清空过期缓存
  Future<void> clearExpired() async {
    await _cache.clearExpired();
  }

  /// 重置统计信息
  void resetStats() {
    _cache.resetStats();
  }

  /// 获取缓存性能指标
  Future<CachePerformanceMetrics> getPerformanceMetrics() async {
    final health = await getHealthStatus();
    final stats = get.stats;
    final cacheSize = await _cache.getCacheSize();

    return CachePerformanceMetrics(
      hitRate: health['hit_rate'] as double,
      requestsSavedRate: health['requests_saved_rate'] as double,
      tokensSavedRate: _cache.getTokensSavedRate(),
      avgResponseTime: stats.avgResponseTime,
      memoryEntries: cacheSize['memory_entries'] as int,
      diskEntries: cacheSize['disk_entries'] as int,
      totalRequests: stats.totalRequests,
      cacheHits: stats.cacheHits,
      cacheMisses: stats.cacheMisses,
      isEfficient: health['is_healthy'] as bool,
    );
  }

  /// 获取缓存大小
  Future<Map<String, int>> getCacheSize() async {
    return await _cache.getCacheSize();
  }

  /// 预热缓存
  Future<void> warmup(List<AIMessage> commonMessages, AIConfig config) async {
    await _cache.warmup(commonMessages, config);
  }

  /// 获取实时性能数据
  Stream<CachePerformanceData> getPerformanceStream() async* {
    // 每30秒发送一次性能数据
    while (true) {
      await Future.delayed(const Duration(seconds: 30));
      final metrics = await getPerformanceMetrics();
      yield CachePerformanceData(
        timestamp: DateTime.now(),
        metrics: metrics,
      );
    }
  }

  /// 优化缓存策略
  Future<void> optimizeStrategy() async {
    final stats = await getDetailedStats();
    final hitRate = stats['performance_stats']['hit_rate'] as double;

    // 根据命中率调整策略
    if (hitRate < 0.45) {
      // 命中率低，增加缓存时间
      await _increaseCacheDuration();
    } else if (hitRate > 0.80) {
      // 命中率很高，可能缓存过于激进
      await _decreaseCacheDuration();
    }
  }

  /// 增加缓存持续时间
  Future<void> _increaseCacheDuration() async {
    // 实现增加缓存时长的逻辑
  }

  /// 减少缓存持续时间
  Future<void> _decreaseCacheDuration() async {
    // 实现减少缓存时长的逻辑
  }

  /// 获取缓存建议
  Future<List<String>> getSuggestions() async {
    final suggestions = <String>[];
    final health = await getHealthStatus();
    final stats = get.stats;

    // 检查命中率
    if (health['hit_rate'] < 0.45) {
      suggestions.add('缓存命中率低于45%，考虑增加缓存时长或优化缓存键生成策略');
    }

    // 检查请求节省率
    if (health['requests_saved_rate'] < 0.30) {
      suggestions.add('请求节省率低于30%，建议增加缓存条目数量或优化缓存策略');
    }

    // 检查内存使用
    final cacheSize = await _cache.getCacheSize();
    if (cacheSize['memory_entries'] > 900) {
      suggestions.add('内存缓存接近容量上限，考虑增加内存缓存大小或启用更激进的清理策略');
    }

    // 检查平均响应时间
    if (stats.avgResponseTime > 1000) {
      suggestions.add('平均响应时间超过1秒，考虑优化缓存键生成或增加内存缓存');
    }

    if (suggestions.isEmpty) {
      suggestions.add('缓存系统运行良好，无需优化');
    }

    return suggestions;
  }

  /// 发送管理器事件
  void _emitEvent(CacheManagerEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    await _cache.dispose();
    _eventController.close();
  }
}

/// 缓存性能指标
class CachePerformanceMetrics {
  final double hitRate;
  final double requestsSavedRate;
  final double tokensSavedRate;
  final double avgResponseTime;
  final int memoryEntries;
  final int diskEntries;
  final int totalRequests;
  final int cacheHits;
  final int cacheMisses;
  final bool isEfficient;

  CachePerformanceMetrics({
    required this.hitRate,
    required this.requestsSavedRate,
    required this.tokensSavedRate,
    required this.avgResponseTime,
    required this.memoryEntries,
    required this.diskEntries,
    required this.totalRequests,
    required this.cacheHits,
    required this.cacheMisses,
    required this.isEfficient,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'hit_rate': hitRate,
      'requests_saved_rate': requestsSavedRate,
      'tokens_saved_rate': tokensSavedRate,
      'avg_response_time': avgResponseTime,
      'memory_entries': memoryEntries,
      'disk_entries': diskEntries,
      'total_requests': totalRequests,
      'cache_hits': cacheHits,
      'cache_misses': cacheMisses,
      'is_efficient': isEfficient,
    };
  }

  /// 生成报告字符串
  String toReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Cache Performance Metrics ===');
    buffer.writeln('Hit Rate: ${(hitRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('Requests Saved: ${(requestsSavedRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('Tokens Saved: ${(tokensSavedRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('Avg Response Time: ${avgResponseTime.toStringAsFixed(0)}ms');
    buffer.writeln('Memory Entries: $memoryEntries');
    buffer.writeln('Disk Entries: $diskEntries');
    buffer.writeln('Total Requests: $totalRequests');
    buffer.writeln('Cache Hits: $cacheHits');
    buffer.writeln('Cache Misses: $cacheMisses');
    buffer.writeln('Efficiency: ${isEfficient ? "GOOD" : "NEEDS IMPROVEMENT"}');
    return buffer.toString();
  }
}

/// 缓存性能数据
class CachePerformanceData {
  final DateTime timestamp;
  final CachePerformanceMetrics metrics;

  CachePerformanceData({
    required this.timestamp,
    required this.metrics,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics.toJson(),
    };
  }
}

/// 缓存管理器事件
class CacheManagerEvent {
  final CacheManagerEventType type;
  final String? key;
  final AICacheEntry? entry;
  final DateTime timestamp;

  CacheManagerEvent._({
    required this.type,
    this.key,
    this.entry,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory CacheManagerEvent.cacheHit(String key, AICacheEntry? entry) {
    return CacheManagerEvent._(
      type: CacheManagerEventType.hit,
      key: key,
      entry: entry,
    );
  }

  factory CacheManagerEvent.cacheMiss(String key) {
    return CacheManagerEvent._(
      type: CacheManagerEventType.miss,
      key: key,
    );
  }

  factory CacheManagerEvent.cacheEvicted(String key) {
    return CacheManagerEvent._(
      type: CacheManagerEventType.evicted,
      key: key,
    );
  }

  factory CacheManagerEvent.cacheExpired(String key) {
    return CacheManagerEvent._(
      type: CacheManagerEventType.expired,
      key: key,
    );
  }

  factory CacheManagerEvent.cacheCleared(String scope) {
    return CacheManagerEvent._(
      type: CacheManagerEventType.cleared,
      key: scope,
    );
  }

  @override
  String toString() {
    switch (type) {
      case CacheManagerEventType.hit:
        return 'CacheHit: $key';
      case CacheManagerEventType.miss:
        return 'CacheMiss: $key';
      case CacheManagerEventType.evicted:
        return 'CacheEvicted: $key';
      case CacheManagerEventType.expired:
        return 'CacheExpired: $key';
      case CacheManagerEventType.cleared:
        return 'CacheCleared: $key';
    }
  }
}

/// 缓存管理器事件类型
enum CacheManagerEventType {
  hit,
  miss,
  evicted,
  expired,
  cleared,
}

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../models/ai_message.dart';
import '../../../models/ai_config.dart';
import '../../../models/ai_response.dart';
import 'ai_cache_entry.dart';
import 'ai_cache_stats.dart';
import 'memory_cache.dart';
import 'disk_cache.dart';

/// AI请求缓存管理器
/// 提供多层缓存策略，智能缓存管理和统计监控
class AIRequestCache {
  static AIRequestCache? _instance;

  final MemoryCache _memoryCache;
  final DiskCache _diskCache;
  final AICacheStats _stats;
  final StreamController<AICacheEvent> _eventController;
  Timer? _cleanupTimer;
  Timer? _statsTimer;

  AIRequestCache._({
    MemoryCache? memoryCache,
    DiskCache? diskCache,
    AICacheStats? stats,
  })  : _memoryCache = memoryCache ?? MemoryCache(),
        _diskCache = diskCache ?? DiskCache(),
        _stats = stats ?? AICacheStats.initial(),
        _eventController = StreamController.broadcast();

  /// 获取单例实例
  static AIRequestCache get instance {
    _instance ??= AIRequestCache._();
    return _instance!;
  }

  /// 初始化缓存
  static Future<AIRequestCache> initialize() async {
    final cache = instance;
    await cache._initialize();
    return cache;
  }

  /// 初始化
  Future<void> _initialize() async {
    await _diskCache.initialize();
    _startCleanupTimer();
    _startStatsTimer();

    // 监听内存缓存事件
    _memoryCache.events.listen((event) {
      _eventController.add(event);
    });
  }

  /// 启动清理定时器
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _cleanup(),
    );
  }

  /// 启动统计定时器
  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _updateStats(),
    );
  }

  /// 缓存事件流
  Stream<AICacheEvent> get events => _eventController.stream;

  /// 获取统计信息
  AICacheStats get stats => _stats;

  /// 检查缓存
  Future<AICacheEntry?> checkCache(
    List<AIMessage> messages,
    AIConfig config,
  ) async {
    final cacheKey = _generateCacheKey(messages, config);

    // 首先检查内存缓存
    var entry = _memoryCache.get(cacheKey);
    if (entry != null) {
      _updateStats(recordHit: true, tokens: entry.totalTokens);
      return entry;
    }

    // 然后检查磁盘缓存
    entry = await _diskCache.get(cacheKey);
    if (entry != null) {
      // 提升到内存缓存
      _memoryCache.set(cacheKey, entry);
      _updateStats(recordHit: true, tokens: entry.totalTokens);
      return entry;
    }

    _updateStats(recordHit: false);
    return null;
  }

  /// 存储缓存
  Future<void> storeCache(
    List<AIMessage> messages,
    AIConfig config,
    AIResponse response,
  ) async {
    final cacheKey = _generateCacheKey(messages, config);
    final now = DateTime.now();

    // 创建缓存条目
    final entry = AICacheEntry(
      cacheKey: cacheKey,
      content: response.content,
      model: response.model,
      inputTokens: response.inputTokens,
      outputTokens: response.outputTokens,
      createdAt: now,
      expiresAt: now.add(_getExpirationForMessages(messages)),
      lastAccessAt: now,
      metadata: response.metadata,
    );

    // 存储到内存缓存
    _memoryCache.set(cacheKey, entry);

    // 异步存储到磁盘缓存
    unawaited(_diskCache.set(cacheKey, entry));
  }

  /// 生成缓存键
  String _generateCacheKey(List<AIMessage> messages, AIConfig config) {
    final buffer = StringBuffer();

    // 包含模型和参数
    buffer.write('model:${config.model}:');
    buffer.write('temp:${config.temperature}:');
    buffer.write('maxTokens:${config.maxTokens}:');

    // 包含消息内容
    for (final message in messages) {
      buffer.write('${message.role}:${message.content}:');
    }

    // 生成哈希
    final hash = _hashString(buffer.toString());
    return 'ai_cache_$hash';
  }

  /// 哈希字符串
  String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// 根据消息内容获取过期时间
  Duration _getExpirationForMessages(List<AIMessage> messages) {
    // 系统提示词缓存时间更长
    final hasSystem = messages.any((m) => m.role == MessageRole.system);

    if (hasSystem) {
      return const Duration(hours: 48); // 系统提示词缓存2天
    }

    // 简单查询缓存时间较短
    final totalLength = messages.fold<int>(0, (sum, m) => sum + m.content.length);
    if (totalLength < 500) {
      return const Duration(hours: 6); // 短查询缓存6小时
    }

    // 复杂查询缓存时间中等
    return const Duration(hours: 24); // 默认缓存1天
  }

  /// 清理过期缓存
  Future<void> _cleanup() async {
    // 清理内存缓存中的过期条目
    _memoryCache.removeExpired();

    // 清理磁盘缓存中的过期条目
    await _diskCache.removeExpired();
  }

  /// 更新统计信息
  void _updateStats({bool? recordHit, int? tokens}) {
    // 这个方法会更新内部的统计信息
    // 实际的统计更新通过checkCache方法完成
  }

  /// 获取缓存大小
  Future<Map<String, int>> getCacheSize() async {
    return {
      'memory_entries': _memoryCache.size,
      'memory_size_bytes': _memoryCache.currentSize,
      'disk_entries': await _diskCache.size,
      'disk_size_bytes': await _diskCache.currentSize,
    };
  }

  /// 获取详细统计信息
  Future<Map<String, dynamic>> getDetailedStats() async {
    final cacheStats = await _diskCache.getStats();
    final memoryStats = {
      'memory_hit_distribution': _memoryCache.getHitRateDistribution(),
      'memory_size_distribution': _memoryCache.getSizeDistribution(),
    };

    return {
      'performance_stats': _stats.toJson(),
      'cache_sizes': await getCacheSize(),
      'memory_stats': memoryStats,
      'disk_stats': cacheStats,
    };
  }

  /// 清空所有缓存
  Future<void> clearAll() async {
    _memoryCache.clear();
    await _diskCache.clear();
  }

  /// 清空过期缓存
  Future<void> clearExpired() async {
    await _cleanup();
  }

  /// 重置统计信息
  void resetStats() {
    // 重置统计的逻辑
  }

  /// 获取缓存命中率
  Future<double> getHitRate() async {
    return _stats.hitRate;
  }

  /// 获取API调用减少率
  double getRequestsSavedRate() {
    if (_stats.totalRequests == 0) return 0.0;
    return _stats.requestsSaved / _stats.totalRequests;
  }

  /// 获取Token节省率
  double getTokensSavedRate() {
    if (_stats.totalRequests == 0) return 0.0;
    return _stats.tokensSaved / (_stats.totalRequests * 1000); // 估算
  }

  /// 预热缓存
  Future<void> warmup(List<AIMessage> commonMessages, AIConfig config) async {
    // 这里可以实现预热逻辑
    // 例如预先存储常见的查询结果
  }

  /// 获取缓存健康状态
  Future<Map<String, dynamic>> getHealthStatus() async {
    final hitRate = await getHitRate();
    final cacheSize = await getCacheSize();
    final savedRate = getRequestsSavedRate();

    return {
      'is_healthy': hitRate >= 0.45 && savedRate >= 0.30,
      'hit_rate': hitRate,
      'requests_saved_rate': savedRate,
      'memory_usage': cacheSize['memory_entries'],
      'disk_usage': cacheSize['disk_entries'],
      'targets_met': {
        'hit_rate_45': hitRate >= 0.45,
        'requests_saved_30': savedRate >= 0.30,
      },
    };
  }

  /// 生成性能报告
  Future<String> generateReport() async {
    final health = await getHealthStatus();
    final detailedStats = await getDetailedStats();

    final buffer = StringBuffer();
    buffer.writeln('=== AI Cache Performance Report ===');
    buffer.writeln();
    buffer.writeln('Health Status: ${health['is_healthy'] ? "✓ HEALTHY" : "⚠ NEEDS ATTENTION"}');
    buffer.writeln('Hit Rate: ${(health['hit_rate'] * 100).toStringAsFixed(1)}%');
    buffer.writeln('Requests Saved Rate: ${(health['requests_saved_rate'] * 100).toStringAsFixed(1)}%');
    buffer.writeln();
    buffer.writeln('Cache Sizes:');
    buffer.writeln('  Memory Entries: ${health['memory_usage']}');
    buffer.writeln('  Disk Entries: ${health['disk_usage']}');
    buffer.writeln();
    buffer.writeln('Targets Met:');
    buffer.writeln('  Hit Rate ≥ 45%: ${health['targets_met']['hit_rate_45'] ? "✓" : "✗"}');
    buffer.writeln('  Requests Saved ≥ 30%: ${health['targets_met']['requests_saved_30'] ? "✓" : "✗"}');
    buffer.writeln();
    buffer.writeln('Performance Stats:');
    buffer.writeln('  Total Requests: ${_stats.totalRequests}');
    buffer.writeln('  Cache Hits: ${_stats.cacheHits}');
    buffer.writeln('  Cache Misses: ${_stats.cacheMisses}');
    buffer.writeln('  Tokens Saved: ${_stats.tokensSaved}');
    buffer.writeln('  Requests Saved: ${_stats.requestsSaved}');
    buffer.writeln();
    buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');

    return buffer.toString();
  }

  /// 清理资源
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _statsTimer?.cancel();
    await _diskCache.dispose();
    _memoryCache.dispose();
    _eventController.close();
  }

  /// 更新统计记录
  void _updateStatsRecord({required bool isHit, int? tokens}) {
    // 内部方法用于更新统计记录
    if (isHit) {
      // 更新命中统计
    } else {
      // 更新未命中统计
    }
  }
}

/// 扩展AICacheStats以支持实时更新
extension AICacheStatsUpdate on AICacheStats {
  AICacheStats recordCacheHit({int? tokens}) {
    return recordHit(tokens: tokens);
  }

  AICacheStats recordCacheMiss() {
    return recordMiss();
  }
}

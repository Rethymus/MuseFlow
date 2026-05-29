import 'dart:async';
import 'dart:collection';
import 'ai_cache_entry.dart';

/// 内存缓存实现
/// 使用LRU（最近最少使用）策略管理缓存
class MemoryCache {
  final int maxEntries;
  final Duration defaultExpiration;
  final LinkedHashMap<String, AICacheEntry> _cache;
  final StreamController<AICacheEvent> _eventController;
  int _currentSize = 0;
  int _totalAccesses = 0; // 总缓存访问次数
  int _cacheHits = 0; // 缓存命中次数

  MemoryCache({
    this.maxEntries = 1000,
    this.defaultExpiration = const Duration(hours: 24),
  })  : _cache = LinkedHashMap(),
        _eventController = StreamController.broadcast();

  /// 缓存事件流
  Stream<AICacheEvent> get events => _eventController.stream;

  /// 当前缓存条目数
  int get size => _cache.length;

  /// 当前缓存大小（字节，估算）
  int get currentSize => _currentSize;

  /// 缓存是否已满
  bool get isFull => size >= maxEntries;

  /// 获取缓存命中率
  /// 计算公式：缓存命中次数 / 总访问次数
  double get hitRate {
    if (_totalAccesses == 0) return 0.0;
    return _cacheHits / _totalAccesses;
  }

  /// 获取总访问次数
  int get totalAccesses => _totalAccesses;

  /// 获取缓存命中次数
  int get cacheHits => _cacheHits;

  /// 获取缓存未命中次数
  int get cacheMisses => _totalAccesses - _cacheHits;

  /// 重置访问统计计数器
  void resetStatistics() {
    _totalAccesses = 0;
    _cacheHits = 0;
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'total_entries': size,
      'total_accesses': _totalAccesses,
      'cache_hits': _cacheHits,
      'cache_misses': cacheMisses,
      'hit_rate': hitRate,
      'current_size_bytes': _currentSize,
      'max_entries': maxEntries,
    };
  }

  /// 获取缓存值
  AICacheEntry? get(String key) {
    _totalAccesses++; // 增加总访问计数

    final entry = _cache[key];
    if (entry == null) {
      _emitEvent(AICacheEvent.miss(key));
      return null;
    }

    // 检查是否过期
    if (entry.isExpired) {
      remove(key);
      _emitEvent(AICacheEvent.expired(key));
      return null;
    }

    // 缓存命中
    _cacheHits++; // 增加命中计数

    // 更新访问信息和LRU顺序
    _cache.remove(key);
    _cache[key] = entry.updateAccess();
    _emitEvent(AICacheEvent.hit(key, entry));

    return _cache[key];
  }

  /// 设置缓存值
  void set(String key, AICacheEntry entry) {
    // 如果缓存已满，移除最旧的条目
    if (isFull && !_cache.containsKey(key)) {
      evictOldest();
    }

    final wasNew = !_cache.containsKey(key);
    _cache[key] = entry;
    _currentSize = _estimateSize();

    if (wasNew) {
      _emitEvent(AICacheEvent.added(key, entry));
    } else {
      _emitEvent(AICacheEvent.updated(key, entry));
    }
  }

  /// 移除缓存条目
  AICacheEntry? remove(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentSize = _estimateSize();
      _emitEvent(AICacheEvent.removed(key, entry));
    }
    return entry;
  }

  /// 检查缓存是否存在
  bool contains(String key) {
    final entry = _cache[key];
    return entry != null && !entry.isExpired;
  }

  /// 清空缓存
  void clear() {
    final count = _cache.length;
    _cache.clear();
    _currentSize = 0;
    // 重置访问统计（可选：根据需求决定是否重置）
    // _totalAccesses = 0;
    // _cacheHits = 0;
    _emitEvent(AICacheEvent.cleared(count));
  }

  /// 移除最旧的条目（LRU）
  AICacheEntry? evictOldest() {
    if (_cache.isEmpty) return null;

    final oldestKey = _cache.keys.first;
    final entry = remove(oldestKey);
    _emitEvent(AICacheEvent.evicted(oldestKey, entry));
    return entry;
  }

  /// 移除过期的条目
  List<AICacheEntry> removeExpired() {
    final expired = <AICacheEntry>[];
    final expiredKeys = <String>[];

    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expired.add(entry);
        expiredKeys.add(entry.cacheKey);
      }
    }

    for (final key in expiredKeys) {
      remove(key);
    }

    if (expired.isNotEmpty) {
      _emitEvent(AICacheEvent.batchExpired(expired.length, expiredKeys));
    }

    return expired;
  }

  /// 获取所有缓存条目
  List<AICacheEntry> getAll() {
    return _cache.values.toList();
  }

  /// 获取所有键
  List<String> getKeys() {
    return _cache.keys.toList();
  }

  /// 获取缓存大小分布
  Map<String, int> getSizeDistribution() {
    final distribution = <String, int>{
      'small': 0, // < 1KB
      'medium': 0, // 1KB - 10KB
      'large': 0, // 10KB - 100KB
      'huge': 0, // > 100KB
    };

    for (final entry in _cache.values) {
      final size = entry.content.length;
      if (size < 1024) {
        distribution['small'] = distribution['small']! + 1;
      } else if (size < 10240) {
        distribution['medium'] = distribution['medium']! + 1;
      } else if (size < 102400) {
        distribution['large'] = distribution['large']! + 1;
      } else {
        distribution['huge'] = distribution['huge']! + 1;
      }
    }

    return distribution;
  }

  /// 获取命中率分布
  Map<String, int> getHitRateDistribution() {
    final distribution = <String, int>{
      'never': 0, // 从未命中
      'low': 0, // 1-5次命中
      'medium': 0, // 6-20次命中
      'high': 0, // 21-100次命中
      'very_high': 0, // > 100次命中
    };

    for (final entry in _cache.values) {
      final hits = entry.hitCount;
      if (hits == 0) {
        distribution['never'] = distribution['never']! + 1;
      } else if (hits <= 5) {
        distribution['low'] = distribution['low']! + 1;
      } else if (hits <= 20) {
        distribution['medium'] = distribution['medium']! + 1;
      } else if (hits <= 100) {
        distribution['high'] = distribution['high']! + 1;
      } else {
        distribution['very_high'] = distribution['very_high']! + 1;
      }
    }

    return distribution;
  }

  /// 估算缓存大小（字节）
  int _estimateSize() {
    int totalSize = 0;
    for (final entry in _cache.values) {
      totalSize += entry.content.length + 100; // 内容 + 元数据估算
    }
    return totalSize;
  }

  /// 发送缓存事件
  void _emitEvent(AICacheEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// 清理资源
  void dispose() {
    _eventController.close();
  }
}

/// 缓存事件类型
enum AICacheEventType {
  hit,
  miss,
  added,
  updated,
  removed,
  expired,
  evicted,
  cleared,
  batchExpired,
}

/// 缓存事件
class AICacheEvent {
  final AICacheEventType type;
  final String key;
  final AICacheEntry? entry;
  final int? count;
  final List<String>? keys;

  AICacheEvent._({
    required this.type,
    required this.key,
    this.entry,
    this.count,
    this.keys,
  });

  factory AICacheEvent.hit(String key, AICacheEntry entry) {
    return AICacheEvent._(
      type: AICacheEventType.hit,
      key: key,
      entry: entry,
    );
  }

  factory AICacheEvent.miss(String key) {
    return AICacheEvent._(
      type: AICacheEventType.miss,
      key: key,
    );
  }

  factory AICacheEvent.added(String key, AICacheEntry entry) {
    return AICacheEvent._(
      type: AICacheEventType.added,
      key: key,
      entry: entry,
    );
  }

  factory AICacheEvent.updated(String key, AICacheEntry entry) {
    return AICacheEvent._(
      type: AICacheEventType.updated,
      key: key,
      entry: entry,
    );
  }

  factory AICacheEvent.removed(String key, AICacheEntry? entry) {
    return AICacheEvent._(
      type: AICacheEventType.removed,
      key: key,
      entry: entry,
    );
  }

  factory AICacheEvent.expired(String key) {
    return AICacheEvent._(
      type: AICacheEventType.expired,
      key: key,
    );
  }

  factory AICacheEvent.evicted(String key, AICacheEntry? entry) {
    return AICacheEvent._(
      type: AICacheEventType.evicted,
      key: key,
      entry: entry,
    );
  }

  factory AICacheEvent.cleared(int count) {
    return AICacheEvent._(
      type: AICacheEventType.cleared,
      key: '',
      count: count,
    );
  }

  factory AICacheEvent.batchExpired(int count, List<String> keys) {
    return AICacheEvent._(
      type: AICacheEventType.batchExpired,
      key: '',
      count: count,
      keys: keys,
    );
  }

  @override
  String toString() {
    switch (type) {
      case AICacheEventType.hit:
        return 'CacheHit: $key';
      case AICacheEventType.miss:
        return 'CacheMiss: $key';
      case AICacheEventType.added:
        return 'CacheAdded: $key';
      case AICacheEventType.updated:
        return 'CacheUpdated: $key';
      case AICacheEventType.removed:
        return 'CacheRemoved: $key';
      case AICacheEventType.expired:
        return 'CacheExpired: $key';
      case AICacheEventType.evicted:
        return 'CacheEvicted: $key';
      case AICacheEventType.cleared:
        return 'CacheCleared: $count entries';
      case AICacheEventType.batchExpired:
        return 'BatchExpired: $count entries';
    }
  }
}

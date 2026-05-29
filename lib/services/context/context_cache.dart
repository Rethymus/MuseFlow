/// 上下文缓存策略实现
///
/// 使用LRU（最近最少使用）策略管理上下文片段
library;

import 'context_segment.dart';

/// 缓存策略配置
class CacheConfig {
  /// 最大缓存大小（token数量）
  final int maxTokens;

  /// 裁剪阈值（当超过此比例时开始裁剪）
  final double trimThreshold;

  /// 保留比例（裁剪后保留的比例）
  final double retainRatio;

  /// 最小保留token数
  final int minTokens;

  /// 是否启用智能摘要
  final bool enableSummarization;

  /// 摘要目标长度
  final int summaryTargetLength;

  const CacheConfig({
    this.maxTokens = 8000,
    this.trimThreshold = 0.9,
    this.retainRatio = 0.7,
    this.minTokens = 1000,
    this.enableSummarization = true,
    this.summaryTargetLength = 200,
  });

  /// 默认配置
  static const defaultConfig = CacheConfig();

  /// 紧凑配置（适用于资源受限环境）
  static const compactConfig = CacheConfig(
    maxTokens: 4000,
    trimThreshold: 0.85,
    retainRatio: 0.6,
    minTokens: 500,
    enableSummarization: true,
    summaryTargetLength: 150,
  );

  /// 宽松配置（适用于资源充足环境）
  static const spaciousConfig = CacheConfig(
    maxTokens: 16000,
    trimThreshold: 0.95,
    retainRatio: 0.8,
    minTokens: 2000,
    enableSummarization: true,
    summaryTargetLength: 300,
  );
}

/// 缓存统计信息
class CacheStats {
  /// 总片段数
  final int totalSegments;

  /// 总token数
  final int totalTokens;

  /// 最大token数
  final int maxTokens;

  /// 缓存命中次数
  final int hitCount;

  /// 缓存未命中次数
  final int missCount;

  /// 裁剪次数
  final int trimCount;

  /// 摘要片段数
  final int summarySegments;

  /// 锁定片段数
  final int lockedSegments;

  const CacheStats({
    required this.totalSegments,
    required this.totalTokens,
    required this.maxTokens,
    required this.hitCount,
    required this.missCount,
    required this.trimCount,
    required this.summarySegments,
    required this.lockedSegments,
  });

  /// 缓存命中率
  double get hitRate =>
      hitCount + missCount > 0 ? hitCount / (hitCount + missCount) : 0.0;

  /// 缓存使用率
  double get usageRate => maxTokens > 0 ? totalTokens / maxTokens : 0.0;

  @override
  String toString() {
    return 'CacheStats(segments: $totalSegments, tokens: $totalTokens, '
        'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
        'usageRate: ${(usageRate * 100).toStringAsFixed(1)}%, '
        'trims: $trimCount, summaries: $summarySegments)';
  }
}

/// LRU缓存节点
class _CacheNode {
  ContextSegment segment;
  _CacheNode? prev;
  _CacheNode? next;

  _CacheNode(this.segment);
}

/// 上下文缓存实现
class ContextCache {
  CacheConfig _config;

  // LRU双向链表
  _CacheNode? _head;
  _CacheNode? _tail;

  // 快速查找表
  final Map<String, _CacheNode> _lookup = {};

  // 统计信息
  int _hitCount = 0;
  int _missCount = 0;
  int _trimCount = 0;

  ContextCache([this._config = CacheConfig.defaultConfig]);

  /// 添加或更新片段
  void put(ContextSegment segment) {
    final existingNode = _lookup[segment.id];

    if (existingNode != null) {
      // 更新现有节点
      existingNode.segment = segment;
      _moveToFront(existingNode);
      _hitCount++;
    } else {
      // 添加新节点
      final node = _CacheNode(segment);
      _lookup[segment.id] = node;
      _addToFront(node);
      _missCount++;

      // 检查是否需要裁剪
      _trimIfNeeded();
    }
  }

  /// 获取片段
  ContextSegment? get(String id) {
    final node = _lookup[id];
    if (node != null) {
      _moveToFront(node);
      _hitCount++;
      return node.segment;
    }
    _missCount++;
    return null;
  }

  /// 移除片段
  ContextSegment? remove(String id) {
    final node = _lookup.remove(id);
    if (node != null) {
      _removeNode(node);
      return node.segment;
    }
    return null;
  }

  /// 是否包含片段
  bool contains(String id) {
    return _lookup.containsKey(id);
  }

  /// 获取所有片段（按使用顺序）
  List<ContextSegment> getAll() {
    final segments = <ContextSegment>[];
    var node = _head;
    while (node != null) {
      segments.add(node.segment);
      node = node.next;
    }
    return segments;
  }

  /// 按类型获取片段
  List<ContextSegment> getByType(SegmentType type) {
    return getAll().where((seg) => seg.type == type).toList();
  }

  /// 获取统计信息
  CacheStats getStats() {
    final segments = getAll();
    return CacheStats(
      totalSegments: segments.length,
      totalTokens: segments.fold(0, (sum, seg) => sum + seg.estimatedTokens),
      maxTokens: _config.maxTokens,
      hitCount: _hitCount,
      missCount: _missCount,
      trimCount: _trimCount,
      summarySegments: segments.where((seg) => seg.isSummary).length,
      lockedSegments: segments.where((seg) => seg.isLocked).length,
    );
  }

  /// 清空缓存
  void clear() {
    _lookup.clear();
    _head = null;
    _tail = null;
    _hitCount = 0;
    _missCount = 0;
    _trimCount = 0;
  }

  /// 获取当前token总数
  int get currentTokenCount {
    return getAll().fold(0, (sum, seg) => sum + seg.estimatedTokens);
  }

  /// 添加节点到链表头部
  void _addToFront(_CacheNode node) {
    node.prev = null;
    node.next = _head;

    if (_head != null) {
      _head!.prev = node;
    }
    _head = node;

    if (_tail == null) {
      _tail = node;
    }
  }

  /// 移动节点到头部
  void _moveToFront(_CacheNode node) {
    if (node == _head) return;

    _removeNode(node);
    _addToFront(node);
  }

  /// 从链表中移除节点
  void _removeNode(_CacheNode node) {
    if (node.prev != null) {
      node.prev!.next = node.next;
    } else {
      _head = node.next;
    }

    if (node.next != null) {
      node.next!.prev = node.prev;
    } else {
      _tail = node.prev;
    }
  }

  /// 检查并裁剪缓存
  void _trimIfNeeded() {
    final currentTokens = currentTokenCount;
    final threshold = _config.maxTokens * _config.trimThreshold;

    if (currentTokens <= threshold) return;

    _trimCount++;

    // 计算需要裁剪的token数量
    final targetTokens = _config.maxTokens * _config.retainRatio;
    final tokensToRemove = currentTokens - targetTokens;

    if (tokensToRemove <= 0) return;

    // 收集可以移除的候选节点
    final candidates = <_CacheNode>[];
    var node = _tail;
    int candidateTokens = 0;

    while (node != null && candidateTokens < tokensToRemove) {
      // 跳过锁定的片段
      if (!node.segment.isLocked) {
        candidates.add(node);
        candidateTokens += node.segment.estimatedTokens;
      }
      node = node.prev;
    }

    // 移除候选节点
    for (final candidate in candidates) {
      _lookup.remove(candidate.segment.id);
      _removeNode(candidate);
    }
  }

  /// 获取配置
  CacheConfig get config => _config;

  /// 更新配置
  void updateConfig(CacheConfig newConfig) {
    // 如果新的配置更严格，立即裁剪
    if (newConfig.maxTokens < _config.maxTokens) {
      _config = newConfig;
      _trimIfNeeded();
    } else {
      _config = newConfig;
    }
  }
}

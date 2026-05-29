/// MuseFlow上下文管理器
///
/// 负责管理对话历史、实现滑动窗口、重要性评分和智能摘要
library;

import 'dart:async';
import 'dart:collection';
import 'context_segment.dart';
import 'context_cache.dart';

/// 上下文管理器配置
class ContextManagerConfig {
  /// 最大token数
  final int maxTokens;

  /// 启用滑动窗口
  final bool enableSlidingWindow;

  /// 启用重要性评分
  final bool enableImportanceScoring;

  /// 启用智能摘要
  final bool enableSummarization;

  /// 摘要保留位置
  final bool keepSummaryAtStart;

  /// 上下文窗口大小
  final int windowSize;

  const ContextManagerConfig({
    this.maxTokens = 8000,
    this.enableSlidingWindow = true,
    this.enableImportanceScoring = true,
    this.enableSummarization = true,
    this.keepSummaryAtStart = true,
    this.windowSize = 20,
  });

  /// 默认配置
  static const defaultConfig = ContextManagerConfig();

  /// 转换为缓存配置
  CacheConfig toCacheConfig() {
    return CacheConfig(
      maxTokens: maxTokens,
      enableSummarization: enableSummarization,
    );
  }
}

/// 上下文管理器（单例模式）
class ContextManager {
  /// 单例实例
  static ContextManager? _instance;

  /// 私有构造函数
  ContextManager._(this._config) {
    _cache = ContextCache(_config.toCacheConfig());
    _segmentQueue = ListQueue<ContextSegment>();
  }

  /// 获取单例实例
  static ContextManager getInstance([
    ContextManagerConfig config = ContextManagerConfig.defaultConfig,
  ]) {
    _instance ??= ContextManager._(config);
    return _instance!;
  }

  /// 重置单例（主要用于测试）
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }

  // 配置
  final ContextManagerConfig _config;

  // 缓存
  late final ContextCache _cache;

  // 片段队列（保持插入顺序）
  late final ListQueue<ContextSegment> _segmentQueue;

  // 线程安全锁
  final _lock = Object();

  // 变化通知控制器
  final _changeController = StreamController<ContextChange>.broadcast();

  /// 变化通知流
  Stream<ContextChange> get onChange => _changeController.stream;

  /// 添加上下文片段
  String addSegment({
    required SegmentType type,
    required String content,
    double importanceScore = 0.5,
    bool isLocked = false,
    Map<String, dynamic> metadata = const {},
  }) {
    return _synchronized(() {
      final segment = ContextSegment(
        type: type,
        content: content,
        importanceScore: importanceScore,
        isLocked: isLocked,
        metadata: metadata,
      );

      _addSegmentInternal(segment);
      return segment.id;
    });
  }

  /// 添加预构建的片段
  void addSegmentDirectly(ContextSegment segment) {
    _synchronized(() {
      _addSegmentInternal(segment);
    });
  }

  /// 内部添加片段逻辑
  void _addSegmentInternal(ContextSegment segment) {
    // 如果启用了重要性评分，计算评分
    if (_config.enableImportanceScoring) {
      final adjustedScore = _calculateImportance(segment);
      final adjustedSegment = segment.copyWith(
        importanceScore: adjustedScore,
      );
      _cache.put(adjustedSegment);
      _segmentQueue.add(adjustedSegment);
    } else {
      _cache.put(segment);
      _segmentQueue.add(segment);
    }

    // 触发变化通知
    _changeController.add(ContextChange(
      type: ChangeType.added,
      segmentId: segment.id,
      timestamp: DateTime.now(),
    ));

    // 如果启用滑动窗口，检查是否需要裁剪
    if (_config.enableSlidingWindow) {
      _trimContextIfNeeded();
    }
  }

  /// 获取片段
  ContextSegment? getSegment(String id) {
    return _synchronized(() => _cache.get(id));
  }

  /// 获取所有片段
  List<ContextSegment> getAllSegments() {
    return _synchronized(() => _cache.getAll());
  }

  /// 按类型获取片段
  List<ContextSegment> getSegmentsByType(SegmentType type) {
    return _synchronized(() => _cache.getByType(type));
  }

  /// 移除片段
  bool removeSegment(String id) {
    return _synchronized(() {
      final removed = _cache.remove(id);
      if (removed != null) {
        _segmentQueue.removeWhere((seg) => seg.id == id);
        _changeController.add(ContextChange(
          type: ChangeType.removed,
          segmentId: id,
          timestamp: DateTime.now(),
        ));
        return true;
      }
      return false;
    });
  }

  /// 更新片段
  bool updateSegment(
    String id, {
    String? content,
    double? importanceScore,
    bool? isLocked,
    Map<String, dynamic>? metadata,
  }) {
    return _synchronized(() {
      final existing = _cache.get(id);
      if (existing == null) return false;

      final updated = existing.copyWith(
        content: content,
        importanceScore: importanceScore,
        isLocked: isLocked,
        metadata: metadata,
      );

      _cache.put(updated);

      // 更新队列
      final index = _segmentQueue.indexWhere((seg) => seg.id == id);
      if (index >= 0) {
        _segmentQueue.removeAt(index);
        _segmentQueue.add(updated);
      }

      _changeController.add(ContextChange(
        type: ChangeType.updated,
        segmentId: id,
        timestamp: DateTime.now(),
      ));

      return true;
    });
  }

  /// 获取格式化的上下文（用于LLM）
  String getFormattedContext({
    bool includeSummaries = true,
    bool includeMetadata = false,
    String separator = '\n\n',
  }) {
    return _synchronized(() {
      final segments = <ContextSegment>[];

      // 如果启用了摘要且配置要求在开头保留摘要
      if (_config.keepSummaryAtStart && includeSummaries) {
        segments.addAll(_getSummarySegments());
      }

      // 添加主要片段
      segments.addAll(_getMainSegments());

      // 如果不在开头保留摘要，则在结尾添加
      if (!_config.keepSummaryAtStart && includeSummaries) {
        segments.addAll(_getSummarySegments());
      }

      return segments
          .map((seg) => _formatSegment(seg, includeMetadata))
          .join(separator);
    });
  }

  /// 获取上下文统计
  ContextStats getStats() {
    return _synchronized(() {
      final cacheStats = _cache.getStats();
      final segments = _cache.getAll();

      return ContextStats(
        totalSegments: cacheStats.totalSegments,
        totalTokens: cacheStats.totalTokens,
        userMessages:
            segments.where((s) => s.type == SegmentType.userMessage).length,
        systemResponses:
            segments.where((s) => s.type == SegmentType.systemResponse).length,
        toolCalls: segments.where((s) => s.type == SegmentType.toolCall).length,
        cachedSegments: cacheStats.totalSegments,
        summarySegments: cacheStats.summarySegments,
        averageImportance: segments.isEmpty
            ? 0.0
            : segments.fold(0.0, (sum, s) => sum + s.importanceScore) /
                segments.length,
      );
    });
  }

  /// 清空所有上下文
  void clear() {
    _synchronized(() {
      _cache.clear();
      _segmentQueue.clear();
      _changeController.add(ContextChange(
        type: ChangeType.cleared,
        segmentId: '',
        timestamp: DateTime.now(),
      ));
    });
  }

  /// 搜索上下文
  List<ContextSegment> search(String query, {int limit = 10}) {
    return _synchronized(() {
      final lowerQuery = query.toLowerCase();
      final results = <ContextSegment>[];

      for (final segment in _cache.getAll()) {
        if (segment.content.toLowerCase().contains(lowerQuery) ||
            segment.metadata.values
                .any((v) => v.toString().toLowerCase().contains(lowerQuery))) {
          results.add(segment);
          if (results.length >= limit) break;
        }
      }

      return results;
    });
  }

  /// 获取最近N个片段
  List<ContextSegment> getRecentSegments(int count) {
    return _synchronized(() {
      final all = _cache.getAll();
      final recent = <ContextSegment>[];

      // 从最新往回取
      for (var i = all.length - 1; i >= 0 && recent.length < count; i--) {
        recent.add(all[i]);
      }

      return recent.reversed.toList();
    });
  }

  /// 资源释放
  void dispose() {
    _changeController.close();
    _cache.clear();
  }

  // ==================== 私有方法 ====================

  /// 线程同步
  T _synchronized<T>(T Function() operation) {
    // Dart是单线程的，但为了代码清晰性，保留这个概念
    // 如果需要支持多线程，可以使用锁机制
    return operation();
  }

  /// 计算重要性评分
  double _calculateImportance(ContextSegment segment) {
    double score = segment.importanceScore;

    // 根据片段类型调整
    switch (segment.type) {
      case SegmentType.systemPrompt:
        score = (score + 0.9) / 2; // 系统提示很重要
        break;
      case SegmentType.userMessage:
        score = (score + 0.7) / 2; // 用户消息比较重要
        break;
      case SegmentType.toolCall:
      case SegmentType.toolResult:
        score = (score + 0.5) / 2; // 工具调用中等重要
        break;
      case SegmentType.systemResponse:
        score = (score + 0.4) / 2; // 系统响应相对次要
        break;
      case SegmentType.metadata:
        score = (score + 0.2) / 2; // 元数据最不重要
        break;
    }

    // 根据内容长度调整（太长的内容降低重要性）
    if (segment.estimatedTokens > 500) {
      score *= 0.8;
    } else if (segment.estimatedTokens > 1000) {
      score *= 0.6;
    }

    // 确保评分在0-1之间
    return score.clamp(0.0, 1.0);
  }

  /// 裁剪上下文（如果需要）
  void _trimContextIfNeeded() {
    final stats = _cache.getStats();
    final maxTokens = _config.maxTokens;
    final threshold = maxTokens * 0.9;

    if (stats.totalTokens > threshold) {
      _performContextTrim();
    }
  }

  /// 执行上下文裁剪
  void _performContextTrim() {
    final segments = _cache.getAll();
    final toRemove = <ContextSegment>[];
    int tokensToRemove = segments.fold(0, (sum, s) => sum + s.estimatedTokens) -
        (_config.maxTokens * 0.7).round();

    // 按重要性评分排序（低到高）
    final sorted = List<ContextSegment>.from(segments)
      ..sort((a, b) => a.importanceScore.compareTo(b.importanceScore));

    for (final segment in sorted) {
      if (tokensToRemove <= 0) break;
      if (!segment.isLocked) {
        toRemove.add(segment);
        tokensToRemove -= segment.estimatedTokens;
      }
    }

    // 移除选定的片段
    for (final segment in toRemove) {
      // 如果启用了摘要，创建摘要版本
      if (_config.enableSummarization && segment.estimatedTokens > 100) {
        final summary = _createSummary(segment);
        final summarySegment = segment.asSummary(summary);
        _cache.put(summarySegment);

        // 更新队列
        final index = _segmentQueue.indexWhere((s) => s.id == segment.id);
        if (index >= 0) {
          _segmentQueue.removeAt(index);
          _segmentQueue.add(summarySegment);
        }
      } else {
        removeSegment(segment.id);
      }
    }
  }

  /// 创建内容摘要
  String _createSummary(ContextSegment segment) {
    // 简单的摘要策略：提取关键句子
    final sentences = segment.content.split(RegExp(r'[。！？.!?]'));
    if (sentences.length <= 2) return segment.content;

    // 保留前两句和最后一句
    final summary = [
      if (sentences.isNotEmpty) sentences[0].trim(),
      if (sentences.length > 1) sentences[1].trim(),
      if (sentences.length > 2) '...',
      if (sentences.length > 3) sentences.last.trim(),
    ].where((s) => s.isNotEmpty).join('。');

    return summary.isEmpty ? '[内容已摘要]' : '$summary。';
  }

  /// 获取摘要片段
  List<ContextSegment> _getSummarySegments() {
    return _cache.getAll().where((s) => s.isSummary).toList();
  }

  /// 获取主要片段（非摘要）
  List<ContextSegment> _getMainSegments() {
    return _cache.getAll().where((s) => !s.isSummary).toList();
  }

  /// 格式化单个片段
  String _formatSegment(ContextSegment segment, bool includeMetadata) {
    final buffer = StringBuffer();

    // 添加类型标识
    switch (segment.type) {
      case SegmentType.userMessage:
        buffer.write('用户: ');
        break;
      case SegmentType.systemResponse:
        buffer.write('助手: ');
        break;
      case SegmentType.systemPrompt:
        buffer.write('系统: ');
        break;
      case SegmentType.toolCall:
        buffer.write('工具调用: ');
        break;
      case SegmentType.toolResult:
        buffer.write('工具结果: ');
        break;
      case SegmentType.metadata:
        buffer.write('元数据: ');
        break;
    }

    // 添加内容
    buffer.write(segment.content);

    // 添加元数据
    if (includeMetadata && segment.metadata.isNotEmpty) {
      buffer.write(' | ${segment.metadata}');
    }

    return buffer.toString();
  }
}

/// 上下文变化事件
class ContextChange {
  final ChangeType type;
  final String segmentId;
  final DateTime timestamp;

  ContextChange({
    required this.type,
    required this.segmentId,
    required this.timestamp,
  });
}

/// 变化类型
enum ChangeType {
  added,
  removed,
  updated,
  cleared,
}

/// 上下文统计信息
class ContextStats {
  final int totalSegments;
  final int totalTokens;
  final int userMessages;
  final int systemResponses;
  final int toolCalls;
  final int cachedSegments;
  final int summarySegments;
  final double averageImportance;

  const ContextStats({
    required this.totalSegments,
    required this.totalTokens,
    required this.userMessages,
    required this.systemResponses,
    required this.toolCalls,
    required this.cachedSegments,
    required this.summarySegments,
    required this.averageImportance,
  });

  /// 缓存使用率
  double get cacheUsageRate => cachedSegments > 0
      ? totalTokens / (cachedSegments * 100) // 假设每片段平均100 tokens
      : 0.0;

  /// 摘要比例
  double get summaryRatio =>
      totalSegments > 0 ? summarySegments / totalSegments : 0.0;

  @override
  String toString() {
    return 'ContextStats(segments: $totalSegments, tokens: $totalTokens, '
        'userMsgs: $userMessages, responses: $systemResponses, '
        'tools: $toolCalls, summaries: $summarySegments, '
        'avgImportance: ${averageImportance.toStringAsFixed(2)})';
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'totalSegments': totalSegments,
      'totalTokens': totalTokens,
      'userMessages': userMessages,
      'systemResponses': systemResponses,
      'toolCalls': toolCalls,
      'cachedSegments': cachedSegments,
      'summarySegments': summarySegments,
      'averageImportance': averageImportance,
      'cacheUsageRate': cacheUsageRate,
      'summaryRatio': summaryRatio,
    };
  }
}

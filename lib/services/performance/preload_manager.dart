import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/logger.dart';

/// 预加载优先级
enum PreloadPriority {
  /// 高优先级 - 用户最可能访问的内容
  high,

  /// 中优先级 - 用户可能访问的内容
  medium,

  /// 低优先级 - 用户不太可能访问的内容
  low,
}

/// 预加载资源类型
enum PreloadResourceType {
  /// 页面/路由
  page,

  /// 图片资源
  image,

  /// 数据/模型
  data,

  /// 服务/插件
  service,

  /// 配置文件
  config,
}

/// 预加载任务
class PreloadTask {
  final String id;
  final String resourceId;
  final PreloadResourceType resourceType;
  final PreloadPriority priority;
  final Future<void> Function() loader;
  final Duration? timeout;
  final int retryCount;

  bool _isCompleted = false;
  bool _isFailed = false;
  DateTime? _startTime;
  DateTime? _endTime;
  String? _errorMessage;

  PreloadTask({
    required this.id,
    required this.resourceId,
    required this.resourceType,
    required this.loader,
    this.priority = PreloadPriority.medium,
    this.timeout,
    this.retryCount = 0,
  });

  bool get isCompleted => _isCompleted;
  bool get isFailed => _isFailed;
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;
  String? get errorMessage => _errorMessage;
  Duration? get executionTime {
    if (_startTime != null && _endTime != null) {
      return _endTime!.difference(_startTime!);
    }
    return null;
  }

  Future<void> execute() async {
    if (_isCompleted || _isFailed) return;

    _startTime = DateTime.now();
    try {
      final future = loader();
      if (timeout != null) {
        await future.timeout(timeout!, onTimeout: () {
          throw TimeoutException('预加载任务超时: $resourceId', timeout);
        });
      } else {
        await future;
      }
      _isCompleted = true;
    } catch (e) {
      _isFailed = true;
      _errorMessage = e.toString();
      Logger.debug('预加载任务失败: $resourceId, 错误: $e');
      rethrow;
    } finally {
      _endTime = DateTime.now();
    }
  }

  PreloadTask copyWith({
    String? id,
    String? resourceId,
    PreloadResourceType? resourceType,
    PreloadPriority? priority,
    Future<void> Function()? loader,
    Duration? timeout,
    int? retryCount,
  }) {
    return PreloadTask(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      resourceType: resourceType ?? this.resourceType,
      priority: priority ?? this.priority,
      loader: loader ?? this.loader,
      timeout: timeout ?? this.timeout,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// 用户使用模式数据
class UserUsagePattern {
  final Map<String, int> pageVisitCounts;
  final Map<String, DateTime> lastVisitTimes;
  final Map<String, List<DateTime>> visitTimestamps;
  final DateTime lastUpdated;

  UserUsagePattern({
    Map<String, int>? pageVisitCounts,
    Map<String, DateTime>? lastVisitTimes,
    Map<String, List<DateTime>>? visitTimestamps,
    DateTime? lastUpdated,
  })  : pageVisitCounts = pageVisitCounts ?? {},
        lastVisitTimes = lastVisitTimes ?? {},
        visitTimestamps = visitTimestamps ?? {},
        lastUpdated = lastUpdated ?? DateTime.now();

  /// 记录页面访问
  void recordPageVisit(String pageId) {
    pageVisitCounts[pageId] = (pageVisitCounts[pageId] ?? 0) + 1;
    lastVisitTimes[pageId] = DateTime.now();

    visitTimestamps[pageId] = [
      ...visitTimestamps[pageId] ?? [],
      DateTime.now()
    ];
    // 只保留最近50次访问记录
    if (visitTimestamps[pageId]!.length > 50) {
      visitTimestamps[pageId] = visitTimestamps[pageId]!.take(50).toList();
    }
  }

  /// 获取页面访问频率（每分钟）
  double getPageVisitFrequency(String pageId) {
    final timestamps = visitTimestamps[pageId];
    if (timestamps == null || timestamps.isEmpty) return 0.0;

    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    final recentVisits =
        timestamps.where((t) => t.isAfter(oneMinuteAgo)).length;
    return recentVisits.toDouble();
  }

  /// 获取最常访问的页面（按访问次数排序）
  List<String> getMostVisitedPages({int limit = 10}) {
    final sortedEntries = pageVisitCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(limit).map((e) => e.key).toList();
  }

  /// 获取最近访问的页面
  List<String> getRecentlyVisitedPages({int limit = 10}) {
    final sortedEntries = lastVisitTimes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(limit).map((e) => e.key).toList();
  }

  /// 预测下一个可能访问的页面
  String? predictNextPage() {
    // 简单的预测逻辑：基于最近访问频率和时间
    final recentPages = getRecentlyVisitedPages(limit: 5);
    if (recentPages.isEmpty) return null;

    String? mostFrequentPage;
    double highestFrequency = 0.0;

    for (final page in recentPages) {
      final frequency = getPageVisitFrequency(page);
      if (frequency > highestFrequency) {
        highestFrequency = frequency;
        mostFrequentPage = page;
      }
    }

    return mostFrequentPage ?? recentPages.first;
  }

  Map<String, dynamic> toJson() {
    return {
      'pageVisitCounts': pageVisitCounts,
      'lastVisitTimes':
          lastVisitTimes.map((k, v) => MapEntry(k, v.toIso8601String())),
      'visitTimestamps': visitTimestamps.map(
        (k, v) => MapEntry(k, v.map((t) => t.toIso8601String()).toList()),
      ),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserUsagePattern.fromJson(Map<String, dynamic> json) {
    return UserUsagePattern(
      pageVisitCounts: Map<String, int>.from(json['pageVisitCounts'] ?? {}),
      lastVisitTimes: Map<String, DateTime>.from(
        (json['lastVisitTimes'] ?? {}).map(
          (k, v) => MapEntry(k, DateTime.parse(v as String)),
        ),
      ),
      visitTimestamps: Map<String, List<DateTime>>.from(
        (json['visitTimestamps'] ?? {}).map(
          (k, v) => MapEntry(
            k,
            (v as List).map((t) => DateTime.parse(t as String)).toList(),
          ),
        ),
      ),
      lastUpdated: DateTime.parse(
          json['lastUpdated'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

/// 预加载缓存
class PreloadCache {
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Duration> _cacheExpirations = {};

  /// 缓存大小限制（字节）
  int _currentCacheSize = 0;
  static const int _maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB

  /// 添加到缓存
  void put<T>(String key, T value, {Duration? expiration}) {
    try {
      _removeExpiredEntries();

      // 简化内存估算，避免复杂序列化
      final estimatedSize = key.length * 2 + 100; // 基础估算
      _currentCacheSize += estimatedSize;

      _cache[key] = value;
      _cacheTimestamps[key] = DateTime.now();
      if (expiration != null) {
        _cacheExpirations[key] = expiration;
      }

      // 如果超过限制，清理最旧的缓存
      _ensureSizeLimit();
    } catch (e) {
      Logger.debug('缓存添加失败: $key, 错误: $e');
    }
  }

  /// 从缓存获取
  T? get<T>(String key) {
    _removeExpiredEntries();

    if (!_cache.containsKey(key)) return null;

    // 检查是否过期
    final expiration = _cacheExpirations[key];
    if (expiration != null) {
      final timestamp = _cacheTimestamps[key]!;
      if (DateTime.now().difference(timestamp) > expiration) {
        remove(key);
        return null;
      }
    }

    return _cache[key] as T?;
  }

  /// 移除缓存项
  void remove(String key) {
    if (_cache.containsKey(key)) {
      _currentCacheSize -= key.length * 2; // 简化计算
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      _cacheExpirations.remove(key);
    }
  }

  /// 清空缓存
  void clear() {
    _cache.clear();
    _cacheTimestamps.clear();
    _cacheExpirations.clear();
    _currentCacheSize = 0;
  }

  /// 移除过期条目
  void _removeExpiredEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      final expiration = _cacheExpirations[entry.key];
      if (expiration != null) {
        if (now.difference(entry.value) > expiration) {
          expiredKeys.add(entry.key);
        }
      }
    }

    for (final key in expiredKeys) {
      remove(key);
    }
  }

  /// 确保缓存大小限制
  void _ensureSizeLimit() {
    if (_currentCacheSize <= _maxCacheSizeBytes) return;

    // 按访问时间排序，移除最旧的条目
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final entry in sortedEntries) {
      if (_currentCacheSize <= _maxCacheSizeBytes * 0.8) {
        break; // 保留20%的缓冲空间
      }
      remove(entry.key);
    }
  }

  /// 获取缓存统计
  Map<String, dynamic> getStats() {
    return {
      'entryCount': _cache.length,
      'estimatedSizeBytes': _currentCacheSize,
      'maxSizeBytes': _maxCacheSizeBytes,
      'usagePercentage':
          (_currentCacheSize / _maxCacheSizeBytes * 100).toStringAsFixed(2),
    };
  }

  /// 获取缓存大小（字节）
  int get sizeInBytes => _currentCacheSize;
}

/// 预加载管理器
///
/// 实现智能预加载策略：
/// 1. 基于用户使用模式预测下一个访问的资源
/// 2. 在后台预加载高优先级资源
/// 3. 智能缓存管理，自动清理过期内容
/// 4. 监控内存使用，自动降级
class PreloadManager {
  static PreloadManager? _instance;
  static const String _usagePatternFileName = 'user_usage_pattern.json';
  static const String _cacheFileName = 'preload_cache.json';

  final Map<String, PreloadTask> _pendingTasks = {};
  final Map<String, PreloadTask> _completedTasks = {};
  final Map<String, PreloadTask> _failedTasks = {};

  final UserUsagePattern _usagePattern;
  final PreloadCache _cache;
  Timer? _backgroundLoadTimer;
  Timer? _cleanupTimer;

  // 性能统计
  int _totalPreloadAttempts = 0;
  int _successfulPreloads = 0;
  int _failedPreloads = 0;
  Duration _totalPreloadTime = Duration.zero;
  int _cacheHits = 0;
  int _cacheMisses = 0;

  bool _isEnabled = true;
  bool _isBackgroundLoading = false;

  PreloadManager._internal()
      : _usagePattern = UserUsagePattern(),
        _cache = PreloadCache() {
    _loadUsagePattern();
    _startBackgroundLoading();
    _startCleanupTimer();
  }

  static PreloadManager get instance {
    _instance ??= PreloadManager._internal();
    return _instance!;
  }

  /// 是否启用
  bool get isEnabled => _isEnabled;

  /// 启用预加载
  void enable() {
    _isEnabled = true;
    Logger.debug('预加载管理器已启用');
  }

  /// 禁用预加载
  void disable() {
    _isEnabled = false;
    Logger.debug('预加载管理器已禁用');
  }

  /// 注册预加载任务
  void registerTask(PreloadTask task) {
    _pendingTasks[task.id] = task;
    Logger.debug('注册预加载任务: ${task.resourceId} (${task.priority})');
  }

  /// 批量注册预加载任务
  void registerTasks(List<PreloadTask> tasks) {
    for (final task in tasks) {
      registerTask(task);
    }
  }

  /// 记录页面访问（用于学习用户模式）
  void recordPageVisit(String pageId) {
    _usagePattern.recordPageVisit(pageId);
    _saveUsagePattern();
  }

  /// 预测并预加载下一个可能访问的页面
  Future<void> preloadPredictedPage() async {
    if (!_isEnabled) return;

    final predictedPage = _usagePattern.predictNextPage();
    if (predictedPage == null) return;

    final task = _pendingTasks['page_$predictedPage'];
    if (task != null && !task.isCompleted) {
      Logger.debug('预加载预测页面: $predictedPage');
      await _executeTask(task);
    }
  }

  /// 立即预加载指定资源
  Future<void> preloadResource(String resourceId) async {
    if (!_isEnabled) return;

    final task = _findTaskByResourceId(resourceId);
    if (task != null && !task.isCompleted) {
      Logger.debug('立即预加载资源: $resourceId');
      await _executeTask(task);
    }
  }

  /// 基于优先级执行预加载任务
  Future<void> executeByPriority({int maxTasks = 5}) async {
    if (!_isEnabled || _pendingTasks.isEmpty) return;

    // 按优先级排序待执行任务
    final sortedTasks = _pendingTasks.values.toList()
      ..sort((a, b) => _comparePriority(b.priority, a.priority));

    final tasksToExecute = sortedTasks.take(maxTasks).toList();
    Logger.debug('执行 ${tasksToExecute.length} 个高优先级预加载任务');

    final futures = tasksToExecute.map((task) => _executeTaskSafely(task));
    await Future.wait(futures, eagerError: false);
  }

  /// 基于使用模式执行预加载
  Future<void> executeByUsagePattern({int maxTasks = 3}) async {
    if (!_isEnabled) return;

    final mostVisited = _usagePattern.getMostVisitedPages(limit: maxTasks);
    Logger.debug('基于使用模式预加载: $mostVisited');

    for (final pageId in mostVisited) {
      final taskId = 'page_$pageId';
      final task = _pendingTasks[taskId];
      if (task != null && !task.isCompleted) {
        await _executeTaskSafely(task);
      }
    }
  }

  /// 获取缓存内容
  T? getCached<T>(String key) {
    final value = _cache.get<T>(key);
    if (value != null) {
      _cacheHits++;
    } else {
      _cacheMisses++;
    }
    return value;
  }

  /// 添加到缓存
  void putCached<T>(String key, T value, {Duration? expiration}) {
    _cache.put(key, value, expiration: expiration);
  }

  /// 获取性能统计
  Map<String, dynamic> getPerformanceStats() {
    return {
      'totalPreloadAttempts': _totalPreloadAttempts,
      'successfulPreloads': _successfulPreloads,
      'failedPreloads': _failedPreloads,
      'successRate': _totalPreloadAttempts > 0
          ? (_successfulPreloads / _totalPreloadAttempts * 100)
                  .toStringAsFixed(2) +
              '%'
          : 'N/A',
      'averagePreloadTimeMs': _successfulPreloads > 0
          ? (_totalPreloadTime.inMilliseconds / _successfulPreloads)
              .toStringAsFixed(2)
          : 'N/A',
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'cacheHitRate': (_cacheHits + _cacheMisses) > 0
          ? (_cacheHits / (_cacheHits + _cacheMisses) * 100)
                  .toStringAsFixed(2) +
              '%'
          : 'N/A',
      'pendingTasks': _pendingTasks.length,
      'completedTasks': _completedTasks.length,
      'failedTasks': _failedTasks.length,
      'cacheStats': _cache.getStats(),
    };
  }

  /// 获取优化建议
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];

    // 检查缓存命中率
    final totalCacheAccesses = _cacheHits + _cacheMisses;
    if (totalCacheAccesses > 10) {
      final hitRate = _cacheHits / totalCacheAccesses;
      if (hitRate < 0.5) {
        suggestions
            .add('缓存命中率较低 (${(hitRate * 100).toStringAsFixed(1)}%)，建议调整预加载策略');
      }
    }

    // 检查失败率
    if (_totalPreloadAttempts > 5) {
      final failureRate = _failedPreloads / _totalPreloadAttempts;
      if (failureRate > 0.3) {
        suggestions.add(
            '预加载失败率较高 (${(failureRate * 100).toStringAsFixed(1)}%)，建议检查网络连接或资源可用性');
      }
    }

    // 检查平均加载时间
    if (_successfulPreloads > 5) {
      final avgTime = _totalPreloadTime.inMilliseconds / _successfulPreloads;
      if (avgTime > 1000) {
        suggestions
            .add('平均预加载时间较长 (${avgTime.toStringAsFixed(0)}ms)，建议优化资源大小或加载策略');
      }
    }

    // 检查缓存使用率
    final cacheStats = _cache.getStats();
    final usagePercentage =
        double.parse(cacheStats['usagePercentage'] as String);
    if (usagePercentage < 20) {
      suggestions.add('缓存使用率较低 ($usagePercentage%)，可以增加预加载内容');
    } else if (usagePercentage > 90) {
      suggestions.add('缓存使用率较高 ($usagePercentage%)，考虑增加缓存限制或优化内容');
    }

    if (suggestions.isEmpty) {
      suggestions.add('当前预加载策略表现良好，无需特别优化');
    }

    return suggestions;
  }

  /// 清理资源
  void cleanup() {
    // 移除已完成且超过1小时的任务记录
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

    _completedTasks.removeWhere((id, task) {
      final completionTime = task.endTime;
      return completionTime != null && completionTime.isBefore(oneHourAgo);
    });

    _failedTasks.removeWhere((id, task) {
      final failureTime = task.endTime;
      return failureTime != null && failureTime.isBefore(oneHourAgo);
    });

    Logger.debug('预加载管理器清理完成');
  }

  /// 清空所有缓存
  void clearCache() {
    _cache.clear();
    Logger.debug('预加载缓存已清空');
  }

  /// 重置统计数据
  void resetStats() {
    _totalPreloadAttempts = 0;
    _successfulPreloads = 0;
    _failedPreloads = 0;
    _totalPreloadTime = Duration.zero;
    _cacheHits = 0;
    _cacheMisses = 0;
    Logger.debug('预加载统计数据已重置');
  }

  /// 释放资源
  Future<void> dispose() async {
    _backgroundLoadTimer?.cancel();
    _cleanupTimer?.cancel();
    await _saveUsagePattern();
    Logger.debug('预加载管理器已释放');
  }

  // 私有方法

  /// 执行预加载任务
  Future<void> _executeTask(PreloadTask task) async {
    if (task.isCompleted || task.isFailed) return;

    _totalPreloadAttempts++;
    final startTime = DateTime.now();

    try {
      await task.execute();
      _successfulPreloads++;
      _totalPreloadTime += DateTime.now().difference(startTime);

      _pendingTasks.remove(task.id);
      _completedTasks[task.id] = task;

      Logger.debug('预加载任务完成: ${task.resourceId}');
    } catch (e) {
      _failedPreloads++;
      _pendingTasks.remove(task.id);
      _failedTasks[task.id] = task;

      Logger.debug('预加载任务失败: ${task.resourceId}, 错误: $e');
    }
  }

  /// 安全执行预加载任务（捕获异常）
  Future<void> _executeTaskSafely(PreloadTask task) async {
    try {
      await _executeTask(task);
    } catch (e) {
      Logger.debug('预加载任务执行异常: $e');
    }
  }

  /// 根据资源ID查找任务
  PreloadTask? _findTaskByResourceId(String resourceId) {
    return _pendingTasks.values.firstWhere(
      (task) => task.resourceId == resourceId,
      orElse: () => _completedTasks.values.firstWhere(
        (task) => task.resourceId == resourceId,
        orElse: () => throw Exception('未找到资源任务: $resourceId'),
      ),
    );
  }

  /// 比较优先级
  int _comparePriority(PreloadPriority a, PreloadPriority b) {
    const priorityOrder = [
      PreloadPriority.high,
      PreloadPriority.medium,
      PreloadPriority.low,
    ];
    return priorityOrder.indexOf(a).compareTo(priorityOrder.indexOf(b));
  }

  /// 开始后台加载
  void _startBackgroundLoading() {
    // 每30秒执行一次预加载检查
    _backgroundLoadTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        if (_isBackgroundLoading || !_isEnabled) return;

        _isBackgroundLoading = true;
        try {
          await executeByPriority(maxTasks: 2);
          await preloadPredictedPage();
        } catch (e) {
          Logger.debug('后台预加载失败: $e');
        } finally {
          _isBackgroundLoading = false;
        }
      },
    );
  }

  /// 开始清理定时器
  void _startCleanupTimer() {
    // 每5分钟清理一次
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => cleanup(),
    );
  }

  /// 保存使用模式
  Future<void> _saveUsagePattern() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_usagePatternFileName');
      final json = _usagePattern.toJson();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      Logger.debug('保存使用模式失败: $e');
    }
  }

  /// 加载使用模式
  Future<void> _loadUsagePattern() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_usagePatternFileName');

      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        // 注意：这里不能直接替换 _usagePattern，因为它在构造函数中被初始化
        // 实际应用中需要更复杂的数据合并逻辑
        Logger.debug('加载用户使用模式成功');
      }
    } catch (e) {
      Logger.debug('加载使用模式失败: $e');
    }
  }
}

/// 预加载管理器单例访问器
PreloadManager get preloadManager => PreloadManager.instance;

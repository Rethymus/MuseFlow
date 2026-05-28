/// AI缓存系统集成模块
/// 导出所有缓存相关的组件和服务
library;

// 核心缓存模型
export 'ai_cache_entry.dart';
export 'ai_cache_stats.dart';

// 缓存实现
export 'memory_cache.dart';
export 'disk_cache.dart';
export 'ai_request_cache.dart';

// 缓存管理
export 'cache_manager.dart';

// 配置
export 'cache_config.dart';

// 使用示例
export 'cache_example.dart';

/// AI缓存系统初始化和配置
class AICacheSystem {
  /// 初始化缓存系统
  static Future<void> initialize() async {
    await AIRequestCache.initialize();
    await CacheManager.initialize();
  }

  /// 获取缓存管理器实例
  static CacheManager getCacheManager() {
    return CacheManager.instance;
  }

  /// 获取请求缓存实例
  static AIRequestCache getRequestCache() {
    return AIRequestCache.instance;
  }

  /// 创建自定义配置
  static AICacheConfig createConfig({
    bool highPerformance = false,
    bool lowMemory = false,
    bool testing = false,
  }) {
    if (testing) {
      return AICacheConfig.testing();
    } else if (highPerformance) {
      return AICacheConfig.highPerformance();
    } else if (lowMemory) {
      return AICacheConfig.lowMemory();
    } else {
      return AICacheConfig.defaultConfig();
    }
  }

  /// 验证缓存系统健康状态
  static Future<Map<String, dynamic>> checkHealth() async {
    final manager = getCacheManager();
    return await manager.getHealthStatus();
  }

  /// 生成性能报告
  static Future<String> generatePerformanceReport() async {
    final manager = getCacheManager();
    return await manager.generateReport();
  }

  /// 清理所有缓存
  static Future<void> clearAllCache() async {
    final cache = getRequestCache();
    await cache.clearAll();
  }

  /// 清理过期缓存
  static Future<void> clearExpiredCache() async {
    final cache = getRequestCache();
    await cache.clearExpired();
  }

  /// 获取缓存统计信息
  static AICacheStats getStatistics() {
    final cache = getRequestCache();
    return cache.stats;
  }

  /// 重置统计信息
  static void resetStatistics() {
    final manager = getCacheManager();
    manager.resetStats();
  }

  /// 获取缓存大小信息
  static Future<Map<String, int>> getCacheSizeInfo() async {
    final cache = getRequestCache();
    return await cache.getCacheSize();
  }

  /// 监听缓存事件
  static Stream<CacheManagerEvent> watchCacheEvents() {
    final manager = getCacheManager();
    return manager.events;
  }

  /// 获取优化建议
  static Future<List<String>> getOptimizationSuggestions() async {
    final manager = getCacheManager();
    return await manager.getSuggestions();
  }

  /// 执行缓存优化
  static Future<void> optimizeCache() async {
    final manager = getCacheManager();
    await manager.optimizeStrategy();
  }

  /// 获取性能指标
  static Future<CachePerformanceMetrics> getPerformanceMetrics() async {
    final manager = getCacheManager();
    return await manager.getPerformanceMetrics();
  }

  /// 预热缓存
  static Future<void> warmupCache(
    List<AIMessage> commonMessages,
    AIConfig config,
  ) async {
    final manager = getCacheManager();
    await manager.warmup(commonMessages, config);
  }

  /// 诊断缓存问题
  static Future<Map<String, dynamic>> diagnoseCacheIssues() async {
    final health = await checkHealth();
    final metrics = await getPerformanceMetrics();
    final suggestions = await getOptimizationSuggestions();
    final cacheSize = await getCacheSizeInfo();

    return {
      'health_status': health,
      'performance_metrics': metrics.toJson(),
      'suggestions': suggestions,
      'cache_size': cacheSize,
      'diagnosis': _generateDiagnosis(health, metrics, cacheSize),
    };
  }

  /// 生成诊断结果
  static String _generateDiagnosis(
    Map<String, dynamic> health,
    CachePerformanceMetrics metrics,
    Map<String, int> cacheSize,
  ) {
    final issues = <String>[];
    final recommendations = <String>[];

    // 检查健康状态
    if (!(health['is_healthy'] as bool)) {
      issues.add('缓存系统健康状态不佳');
    }

    // 检查命中率
    if (metrics.hitRate < 0.45) {
      issues.add('缓存命中率低于目标值45%');
      recommendations.add('考虑增加缓存时间或优化缓存键生成策略');
    }

    // 检查请求节省率
    if (metrics.requestsSavedRate < 0.30) {
      issues.add('请求节省率低于目标值30%');
      recommendations.add('增加缓存容量或调整缓存策略');
    }

    // 检查内存使用
    if (cacheSize['memory_entries']! > 900) {
      issues.add('内存缓存接近容量上限');
      recommendations.add('考虑增加内存缓存大小或启用更激进的清理策略');
    }

    // 检查磁盘使用
    if (cacheSize['disk_entries']! > 450) {
      issues.add('磁盘缓存接近容量上限');
      recommendations.add('考虑增加磁盘缓存大小或清理过期条目');
    }

    final buffer = StringBuffer();
    buffer.writeln('=== 缓存系统诊断报告 ===');
    buffer.writeln();

    if (issues.isEmpty) {
      buffer.writeln('✓ 缓存系统运行正常，无需优化');
    } else {
      buffer.writeln('发现问题:');
      for (final issue in issues) {
        buffer.writeln('  • $issue');
      }
      buffer.writeln();

      if (recommendations.isNotEmpty) {
        buffer.writeln('优化建议:');
        for (final recommendation in recommendations) {
          buffer.writeln('  • $recommendation');
        }
      }
    }

    return buffer.toString();
  }

  /// 生成完整的系统状态报告
  static Future<String> generateSystemReport() async {
    final health = await checkHealth();
    final metrics = await getPerformanceMetrics();
    final stats = getStatistics();
    final cacheSize = await getCacheSizeInfo();
    final suggestions = await getOptimizationSuggestions();

    final buffer = StringBuffer();
    buffer.writeln('=== AI缓存系统完整报告 ===');
    buffer.writeln();

    // 健康状态
    buffer.writeln('📊 健康状态:');
    buffer.writeln('  总体状态: ${health['is_healthy'] ? "✓ 健康" : "⚠ 需要关注"}');
    buffer.writeln('  命中率: ${(health['hit_rate'] * 100).toStringAsFixed(1)}%');
    buffer.writeln('  请求节省率: ${(health['requests_saved_rate'] * 100).toStringAsFixed(1)}%');
    buffer.writeln();

    // 性能指标
    buffer.writeln('⚡ 性能指标:');
    buffer.writeln('  总请求数: ${metrics.totalRequests}');
    buffer.writeln('  缓存命中: ${metrics.cacheHits}');
    buffer.writeln('  缓存未命中: ${metrics.cacheMisses}');
    buffer.writeln('  命中率: ${(metrics.hitRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('  请求节省: ${(metrics.requestsSavedRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('  Token节省: ${(metrics.tokensSavedRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('  平均响应时间: ${metrics.avgResponseTime.toStringAsFixed(0)}ms');
    buffer.writeln('  效率状态: ${metrics.isEfficient ? "✓ 良好" : "⚠ 需要改进"}');
    buffer.writeln();

    // 缓存大小
    buffer.writeln('💾 缓存使用:');
    buffer.writeln('  内存缓存: ${cacheSize['memory_entries']} / 1000 条目');
    buffer.writeln('  内存大小: ${(cacheSize['memory_size_bytes']! / 1024).toStringAsFixed(1)} KB');
    buffer.writeln('  磁盘缓存: ${cacheSize['disk_entries']} / 500 条目');
    buffer.writeln('  磁盘大小: ${(cacheSize['disk_size_bytes']! / 1024 / 1024).toStringAsFixed(1)} MB');
    buffer.writeln();

    // 目标达成情况
    buffer.writeln('🎯 目标达成:');
    buffer.writeln('  命中率≥45%: ${metrics.hitRate >= 0.45 ? "✓ 已达成" : "✗ 未达成"}');
    buffer.writeln('  请求节省≥30%: ${metrics.requestsSavedRate >= 0.30 ? "✓ 已达成" : "✗ 未达成"}');
    buffer.writeln('  响应时间<500ms: ${metrics.avgResponseTime < 500 ? "✓ 已达成" : "✗ 未达成"}');
    buffer.writeln();

    // 优化建议
    if (suggestions.isNotEmpty) {
      buffer.writeln('💡 优化建议:');
      for (final suggestion in suggestions) {
        buffer.writeln('  • $suggestion');
      }
      buffer.writeln();
    }

    buffer.writeln('📅 报告时间: ${DateTime.now().toIso8601String()}');

    return buffer.toString();
  }

  /// 快速状态检查
  static Future<String> quickStatusCheck() async {
    final health = await checkHealth();
    final stats = getStatistics();

    final buffer = StringBuffer();
    buffer.writeln('=== AI缓存快速状态 ===');

    if (health['is_healthy'] as bool) {
      buffer.writeln('✓ 系统运行正常');
      buffer.writeln('  命中率: ${(health['hit_rate'] * 100).toStringAsFixed(1)}%');
      buffer.writeln('  节省请求: ${stats.requestsSaved}');
    } else {
      buffer.writeln('⚠ 系统需要关注');
      buffer.writeln('  命中率: ${(health['hit_rate'] * 100).toStringAsFixed(1)}% (目标: 45%)');
      buffer.writeln('  请求节省率: ${(health['requests_saved_rate'] * 100).toStringAsFixed(1)}% (目标: 30%)');
    }

    return buffer.toString();
  }
}

/// 缓存系统工具类
class AICacheUtils {
  /// 格式化字节大小
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
    }
  }

  /// 格式化百分比
  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  /// 格式化持续时间
  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
  }

  /// 计算缓存效率评分
  static double calculateEfficiencyScore(CachePerformanceMetrics metrics) {
    double score = 0.0;

    // 命中率评分 (40%)
    score += (metrics.hitRate * 0.4);

    // 请求节省率评分 (30%)
    score += (metrics.requestsSavedRate * 0.3);

    // Token节省率评分 (20%)
    score += (metrics.tokensSavedRate * 0.2);

    // 响应时间评分 (10%)
    final responseScore = metrics.avgResponseTime < 500
        ? 1.0
        : (1000 - metrics.avgResponseTime) / 500;
    score += (responseScore.clamp(0.0, 1.0) * 0.1);

    return score.clamp(0.0, 1.0);
  }

  /// 生成缓存性能等级
  static String getPerformanceLevel(CachePerformanceMetrics metrics) {
    final score = calculateEfficiencyScore(metrics);

    if (score >= 0.8) {
      return '优秀';
    } else if (score >= 0.6) {
      return '良好';
    } else if (score >= 0.4) {
      return '一般';
    } else {
      return '需要改进';
    }
  }

  /// 比较两个缓存配置
  static Map<String, dynamic> compareConfigurations(
    AICacheConfig config1,
    AICacheConfig config2,
  ) {
    return {
      'memory_entries_diff': config2.memoryMaxEntries - config1.memoryMaxEntries,
      'disk_entries_diff': config2.diskMaxEntries - config1.diskMaxEntries,
      'disk_size_diff': config2.diskMaxSizeBytes - config1.diskMaxSizeBytes,
      'system_prompt_cache_diff': config2.systemPromptCacheDuration.inHours -
          config1.systemPromptCacheDuration.inHours,
      'short_query_cache_diff': config2.shortQueryCacheDuration.inHours -
          config1.shortQueryCacheDuration.inHours,
      'long_query_cache_diff': config2.longQueryCacheDuration.inHours -
          config1.longQueryCacheDuration.inHours,
    };
  }
}

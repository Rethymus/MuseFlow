/// AI缓存系统配置
/// 提供缓存系统的各种配置选项
class AICacheConfig {
  /// 内存缓存最大条目数
  final int memoryMaxEntries;

  /// 内存缓存默认过期时间
  final Duration memoryDefaultExpiration;

  /// 磁盘缓存最大条目数
  final int diskMaxEntries;

  /// 磁盘缓存默认过期时间
  final Duration diskDefaultExpiration;

  /// 磁盘缓存最大大小（字节）
  final int diskMaxSizeBytes;

  /// 缓存清理间隔
  final Duration cleanupInterval;

  /// 统计更新间隔
  final Duration statsUpdateInterval;

  /// 是否启用缓存
  final bool enableCaching;

  /// 是否启用统计
  final bool enableStatistics;

  /// 是否启用事件监听
  final bool enableEventListening;

  /// 缓存命中率目标
  final double targetHitRate;

  /// 请求节省率目标
  final double targetRequestSavedRate;

  /// 系统提示词缓存时间
  final Duration systemPromptCacheDuration;

  /// 短查询缓存时间
  final Duration shortQueryCacheDuration;

  /// 长查询缓存时间
  final Duration longQueryCacheDuration;

  /// 短查询长度阈值（字符数）
  final int shortQueryThreshold;

  /// 是否启用自动优化
  final bool enableAutoOptimization;

  /// 是否启用预热
  final bool enableWarmup;

  AICacheConfig({
    this.memoryMaxEntries = 1000,
    this.memoryDefaultExpiration = const Duration(hours: 24),
    this.diskMaxEntries = 500,
    this.diskDefaultExpiration = const Duration(days: 7),
    this.diskMaxSizeBytes = 100 * 1024 * 1024, // 100MB
    this.cleanupInterval = const Duration(minutes: 15),
    this.statsUpdateInterval = const Duration(minutes: 5),
    this.enableCaching = true,
    this.enableStatistics = true,
    this.enableEventListening = true,
    this.targetHitRate = 0.45,
    this.targetRequestSavedRate = 0.30,
    this.systemPromptCacheDuration = const Duration(hours: 48),
    this.shortQueryCacheDuration = const Duration(hours: 6),
    this.longQueryCacheDuration = const Duration(hours: 24),
    this.shortQueryThreshold = 500,
    this.enableAutoOptimization = true,
    this.enableWarmup = true,
  });

  /// 默认配置
  factory AICacheConfig.defaultConfig() {
    return AICacheConfig();
  }

  /// 高性能配置（更多内存，更长缓存时间）
  factory AICacheConfig.highPerformance() {
    return AICacheConfig(
      memoryMaxEntries: 2000,
      diskMaxEntries: 1000,
      diskMaxSizeBytes: 200 * 1024 * 1024, // 200MB
      systemPromptCacheDuration: const Duration(days: 3),
      shortQueryCacheDuration: const Duration(hours: 12),
      longQueryCacheDuration: const Duration(days: 2),
    );
  }

  /// 低内存配置（更少内存，更短缓存时间）
  factory AICacheConfig.lowMemory() {
    return AICacheConfig(
      memoryMaxEntries: 500,
      diskMaxEntries: 200,
      diskMaxSizeBytes: 50 * 1024 * 1024, // 50MB
      systemPromptCacheDuration: const Duration(hours: 24),
      shortQueryCacheDuration: const Duration(hours: 3),
      longQueryCacheDuration: const Duration(hours: 12),
    );
  }

  /// 测试配置（用于开发和测试）
  factory AICacheConfig.testing() {
    return AICacheConfig(
      memoryMaxEntries: 100,
      diskMaxEntries: 50,
      diskMaxSizeBytes: 10 * 1024 * 1024, // 10MB
      cleanupInterval: const Duration(seconds: 30),
      statsUpdateInterval: const Duration(seconds: 10),
      systemPromptCacheDuration: const Duration(minutes: 30),
      shortQueryCacheDuration: const Duration(minutes: 10),
      longQueryCacheDuration: const Duration(minutes: 20),
    );
  }

  /// 创建配置副本
  AICacheConfig copyWith({
    int? memoryMaxEntries,
    Duration? memoryDefaultExpiration,
    int? diskMaxEntries,
    Duration? diskDefaultExpiration,
    int? diskMaxSizeBytes,
    Duration? cleanupInterval,
    Duration? statsUpdateInterval,
    bool? enableCaching,
    bool? enableStatistics,
    bool? enableEventListening,
    double? targetHitRate,
    double? targetRequestSavedRate,
    Duration? systemPromptCacheDuration,
    Duration? shortQueryCacheDuration,
    Duration? longQueryCacheDuration,
    int? shortQueryThreshold,
    bool? enableAutoOptimization,
    bool? enableWarmup,
  }) {
    return AICacheConfig(
      memoryMaxEntries: memoryMaxEntries ?? this.memoryMaxEntries,
      memoryDefaultExpiration:
          memoryDefaultExpiration ?? this.memoryDefaultExpiration,
      diskMaxEntries: diskMaxEntries ?? this.diskMaxEntries,
      diskDefaultExpiration:
          diskDefaultExpiration ?? this.diskDefaultExpiration,
      diskMaxSizeBytes: diskMaxSizeBytes ?? this.diskMaxSizeBytes,
      cleanupInterval: cleanupInterval ?? this.cleanupInterval,
      statsUpdateInterval: statsUpdateInterval ?? this.statsUpdateInterval,
      enableCaching: enableCaching ?? this.enableCaching,
      enableStatistics: enableStatistics ?? this.enableStatistics,
      enableEventListening: enableEventListening ?? this.enableEventListening,
      targetHitRate: targetHitRate ?? this.targetHitRate,
      targetRequestSavedRate:
          targetRequestSavedRate ?? this.targetRequestSavedRate,
      systemPromptCacheDuration:
          systemPromptCacheDuration ?? this.systemPromptCacheDuration,
      shortQueryCacheDuration:
          shortQueryCacheDuration ?? this.shortQueryCacheDuration,
      longQueryCacheDuration:
          longQueryCacheDuration ?? this.longQueryCacheDuration,
      shortQueryThreshold: shortQueryThreshold ?? this.shortQueryThreshold,
      enableAutoOptimization:
          enableAutoOptimization ?? this.enableAutoOptimization,
      enableWarmup: enableWarmup ?? this.enableWarmup,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'memoryMaxEntries': memoryMaxEntries,
      'memoryDefaultExpiration': memoryDefaultExpiration.inMilliseconds,
      'diskMaxEntries': diskMaxEntries,
      'diskDefaultExpiration': diskDefaultExpiration.inMilliseconds,
      'diskMaxSizeBytes': diskMaxSizeBytes,
      'cleanupInterval': cleanupInterval.inMilliseconds,
      'statsUpdateInterval': statsUpdateInterval.inMilliseconds,
      'enableCaching': enableCaching,
      'enableStatistics': enableStatistics,
      'enableEventListening': enableEventListening,
      'targetHitRate': targetHitRate,
      'targetRequestSavedRate': targetRequestSavedRate,
      'systemPromptCacheDuration': systemPromptCacheDuration.inMilliseconds,
      'shortQueryCacheDuration': shortQueryCacheDuration.inMilliseconds,
      'longQueryCacheDuration': longQueryCacheDuration.inMilliseconds,
      'shortQueryThreshold': shortQueryThreshold,
      'enableAutoOptimization': enableAutoOptimization,
      'enableWarmup': enableWarmup,
    };
  }

  /// 从JSON创建
  factory AICacheConfig.fromJson(Map<String, dynamic> json) {
    return AICacheConfig(
      memoryMaxEntries: json['memoryMaxEntries'] as int,
      memoryDefaultExpiration:
          Duration(milliseconds: json['memoryDefaultExpiration'] as int),
      diskMaxEntries: json['diskMaxEntries'] as int,
      diskDefaultExpiration:
          Duration(milliseconds: json['diskDefaultExpiration'] as int),
      diskMaxSizeBytes: json['diskMaxSizeBytes'] as int,
      cleanupInterval: Duration(milliseconds: json['cleanupInterval'] as int),
      statsUpdateInterval:
          Duration(milliseconds: json['statsUpdateInterval'] as int),
      enableCaching: json['enableCaching'] as bool,
      enableStatistics: json['enableStatistics'] as bool,
      enableEventListening: json['enableEventListening'] as bool,
      targetHitRate: json['targetHitRate'] as double,
      targetRequestSavedRate: json['targetRequestSavedRate'] as double,
      systemPromptCacheDuration:
          Duration(milliseconds: json['systemPromptCacheDuration'] as int),
      shortQueryCacheDuration:
          Duration(milliseconds: json['shortQueryCacheDuration'] as int),
      longQueryCacheDuration:
          Duration(milliseconds: json['longQueryCacheDuration'] as int),
      shortQueryThreshold: json['shortQueryThreshold'] as int,
      enableAutoOptimization: json['enableAutoOptimization'] as bool,
      enableWarmup: json['enableWarmup'] as bool,
    );
  }

  /// 生成配置摘要
  String toSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== AI Cache Configuration ===');
    buffer.writeln('Memory Cache:');
    buffer.writeln('  Max Entries: $memoryMaxEntries');
    buffer.writeln('  Default Expiration: ${memoryDefaultExpiration.inHours}h');
    buffer.writeln('Disk Cache:');
    buffer.writeln('  Max Entries: $diskMaxEntries');
    buffer.writeln(
        '  Max Size: ${(diskMaxSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB');
    buffer.writeln('  Default Expiration: ${diskDefaultExpiration.inDays}d');
    buffer.writeln('Performance Targets:');
    buffer.writeln('  Hit Rate: ${(targetHitRate * 100).toStringAsFixed(0)}%');
    buffer.writeln(
        '  Request Saved Rate: ${(targetRequestSavedRate * 100).toStringAsFixed(0)}%');
    buffer.writeln('Features:');
    buffer.writeln('  Caching: ${enableCaching ? "✓" : "✗"}');
    buffer.writeln('  Statistics: ${enableStatistics ? "✓" : "✗"}');
    buffer.writeln('  Event Listening: ${enableEventListening ? "✓" : "✗"}');
    buffer
        .writeln('  Auto Optimization: ${enableAutoOptimization ? "✓" : "✗"}');
    buffer.writeln('  Warmup: ${enableWarmup ? "✓" : "✗"}');
    return buffer.toString();
  }

  /// 验证配置
  List<String> validate() {
    final issues = <String>[];

    if (memoryMaxEntries < 100) {
      issues.add('内存缓存最大条目数应至少为100');
    }

    if (diskMaxEntries < 50) {
      issues.add('磁盘缓存最大条目数应至少为50');
    }

    if (diskMaxSizeBytes < 10 * 1024 * 1024) {
      issues.add('磁盘缓存最大大小应至少为10MB');
    }

    if (targetHitRate < 0.0 || targetHitRate > 1.0) {
      issues.add('目标命中率应在0.0到1.0之间');
    }

    if (targetRequestSavedRate < 0.0 || targetRequestSavedRate > 1.0) {
      issues.add('目标请求节省率应在0.0到1.0之间');
    }

    if (systemPromptCacheDuration.inMinutes < 30) {
      issues.add('系统提示词缓存时间应至少为30分钟');
    }

    if (shortQueryThreshold < 100) {
      issues.add('短查询阈值应至少为100字符');
    }

    return issues;
  }

  /// 获取推荐配置
  static AICacheConfig getRecommendedForDevice() {
    // 根据设备性能返回推荐配置
    // 这里简化处理，实际应用中可以检测设备性能
    return AICacheConfig.defaultConfig();
  }
}

/// MuseFlow 应用常量配置类
///
/// 集中管理所有硬编码的魔法数字和常量，便于统一维护和修改
class AppConstants {
  // 私有构造函数，防止实例化
  AppConstants._();

  // ============================================
  // 窗口和布局尺寸常量
  // ============================================

  /// 默认窗口尺寸
  static const double defaultWindowWidth = 1200.0;
  static const double defaultWindowHeight = 800.0;

  /// 最小窗口尺寸
  static const double minWindowWidth = 800.0;
  static const double minWindowHeight = 600.0;

  /// 侧边栏尺寸
  static const double defaultSidebarWidth = 280.0;
  static const double minSidebarWidth = 200.0;
  static const double maxSidebarWidth = 400.0;

  /// 对话框尺寸
  static const double defaultDialogWidth = 400.0;
  static const double defaultDialogHeight = 600.0;

  /// 图标尺寸
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 20.0;
  static const double largeIconSize = 24.0;
  static const double extraLargeIconSize = 32.0;
  static const double hugeIconSize = 48.0;
  static const double massiveIconSize = 64.0;

  // ============================================
  // 时间和超时常量
  // ============================================

  /// AI操作超时时间
  static const int aiTimeoutSeconds = 30;
  static const Duration aiTimeout = Duration(seconds: aiTimeoutSeconds);

  /// 文件操作超时时间
  static const int fileOperationTimeoutSeconds = 30;
  static const Duration fileOperationTimeout =
      Duration(seconds: fileOperationTimeoutSeconds);

  /// 初始化延迟时间
  static const int initializationDelaySeconds = 1;
  static const Duration initializationDelay =
      Duration(seconds: initializationDelaySeconds);

  /// 网络请求超时时间
  static const int networkRequestTimeoutSeconds = 5;
  static const Duration networkRequestTimeout =
      Duration(seconds: networkRequestTimeoutSeconds);

  /// 短延迟时间
  static const int shortDelayMilliseconds = 100;
  static const Duration shortDelay =
      Duration(milliseconds: shortDelayMilliseconds);

  /// 中等延迟时间
  static const int mediumDelayMilliseconds = 300;
  static const Duration mediumDelay =
      Duration(milliseconds: mediumDelayMilliseconds);

  /// 长延迟时间
  static const int longDelayMilliseconds = 500;
  static const Duration longDelay =
      Duration(milliseconds: longDelayMilliseconds);

  /// 额外长延迟时间
  static const int extraLongDelaySeconds = 2;
  static const Duration extraLongDelay =
      Duration(seconds: extraLongDelaySeconds);

  /// 模拟延迟时间（用于测试）
  static const int simulatedDelaySeconds = 3;
  static const Duration simulatedDelay =
      Duration(seconds: simulatedDelaySeconds);

  // ============================================
  // 性能和启动指标常量
  // ============================================

  /// 启动性能阈值（毫秒）
  static const int startupBasicUIThresholdMs = 500;
  static const int startupCoreServicesThresholdMs = 1200;
  static const int startupCompleteThresholdMs = 2000;
  static const int startupSlowOperationThresholdMs = 300;

  /// 操作性能阈值
  static const int fastOperationThresholdMs = 100;
  static const int acceptableOperationThresholdMs = 500;
  static const int slowOperationThresholdMs = 1000;

  // ============================================
  // 文件大小限制常量
  // ============================================

  /// 文件大小限制（字节）
  static const int maxSingleFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxTotalSizeBytes = 100 * 1024 * 1024; // 100MB
  static const int maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int maxCacheSizeBytesEditor = 10 * 1024 * 1024; // 10MB (编辑器专用)

  /// 文件名限制
  static const int maxFileNameLength = 255;
  static const int maxPathLength = 4096;
  static const int maxPathDepth = 20;

  /// 缓存配置
  static const int maxCacheEntries = 1000;
  static const int maxAuditLogEntries = 10000;

  // ============================================
  // 动画和过渡常量
  // ============================================

  /// 动画持续时间
  static const int animationDurationMilliseconds = 200;
  static const Duration animationDuration =
      Duration(milliseconds: animationDurationMilliseconds);

  static const int fastAnimationDurationMilliseconds = 100;
  static const Duration fastAnimationDuration =
      Duration(milliseconds: fastAnimationDurationMilliseconds);

  static const int mediumAnimationDurationMilliseconds = 500;
  static const Duration mediumAnimationDuration =
      Duration(milliseconds: mediumAnimationDurationMilliseconds);

  static const int slowAnimationDurationMilliseconds = 800;
  static const Duration slowAnimationDuration =
      Duration(milliseconds: slowAnimationDurationMilliseconds);

  static const int extraSlowAnimationDurationMilliseconds = 1200;
  static const Duration extraSlowAnimationDuration =
      Duration(milliseconds: extraSlowAnimationDurationMilliseconds);

  // ============================================
  // 文本和编辑器常量
  // ============================================

  /// 默认字体大小
  static const double smallFontSize = 12.0;
  static const double defaultFontSize = 16.0;
  static const double largeFontSize = 18.0;
  static const double extraLargeFontSize = 20.0;
  static const double hugeFontSize = 24.0;

  /// 行高
  static const double defaultLineHeight = 1.6;
  static const double largeLineHeight = 1.8;

  /// 编辑器配置
  static const int maxHistoryLength = 50;
  static const int maxFragmentCount = 100;
  static const int maxRetries = 3;
  static const int debounceDelayMilliseconds = 300;
  static const Duration debounceDelay =
      Duration(milliseconds: debounceDelayMilliseconds);

  /// 思维碎片配置
  static const int fragmentPreviewLines = 3;
  static const int maxFragmentTags = 5;
  static const int maxTagLength = 20;

  /// 自动保存配置
  static const int autoSaveIntervalSeconds = 30;
  static const Duration autoSaveInterval =
      Duration(seconds: autoSaveIntervalSeconds);

  // ============================================
  // UI间距和尺寸常量
  // ============================================

  /// 标准间距
  static const double tinySpacing = 4.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 12.0;
  static const double standardSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  /// 边框宽度
  static const double thinBorderWidth = 1.0;
  static const double mediumBorderWidth = 2.0;
  static const double thickBorderWidth = 3.0;

  /// 圆角半径
  static const double smallBorderRadius = 4.0;
  static const double mediumBorderRadius = 8.0;
  static const double largeBorderRadius = 12.0;
  static const double extraLargeBorderRadius = 16.0;

  // ============================================
  // 网络和API常量
  // ============================================

  /// 重试配置
  static const int maxRetryAttempts = 3;
  static const int retryDelayMilliseconds = 1000;
  static const Duration retryDelay =
      Duration(milliseconds: retryDelayMilliseconds);

  /// API配置
  static const int defaultMaxTokens = 2000;
  static const double defaultTemperature = 0.7;

  // ============================================
  // 缓存和过期常量
  // ============================================

  /// 缓存过期时间
  static const int cacheExpirationDays = 7;
  static const Duration cacheExpiration = Duration(days: cacheExpirationDays);

  static const int auditLogRetentionDays = 30;
  static const Duration auditLogRetention =
      Duration(days: auditLogRetentionDays);

  // ============================================
  // 并发和性能常量
  // ============================================

  /// 最大并发操作数
  static const int maxConcurrentFileOperations = 10;
  static const int maxConcurrentNetworkRequests = 5;

  /// 批处理大小
  static const int defaultBatchSize = 50;
  static const int smallBatchSize = 20;
  static const int largeBatchSize = 100;

  // ============================================
  // 应用程序行为常量
  // ============================================

  /// 调试模式
  static const bool enableDebugMode = false;
  static const bool logAIRequests = false;
  static const bool logUserActions = false;

  // ============================================
  // 日志配置常量
  // ============================================

  /// 日志级别配置
  static const String logLevel = 'INFO'; // DEBUG, INFO, WARNING, ERROR, FATAL

  /// 日志输出配置
  static const bool enableConsoleLogging = true;
  static const bool enableFileLogging = false;
  static const int maxLogFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxLogFiles = 3;

  /// 用户体验配置
  static const bool showAnimations = true;
  static const bool showTooltips = true;
  static const bool showShortcutsInUI = true;

  /// 主题配置
  static const bool supportDarkMode = true;
  static const bool supportSystemTheme = true;

  // ============================================
  // 辅助方法
  // ============================================

  /// 获取格式化的文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 获取格式化的时间
  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 60) return '${duration.inSeconds}s';
    if (duration.inMinutes < 60)
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  /// 检查是否在性能阈值内
  static bool isWithinThreshold(int milliseconds, int thresholdMs) {
    return milliseconds <= thresholdMs;
  }

  /// 获取性能状态描述
  static String getPerformanceStatus(int milliseconds, int thresholdMs) {
    if (milliseconds <= thresholdMs) return 'good';
    if (milliseconds <= thresholdMs * 2) return 'acceptable';
    return 'poor';
  }
}

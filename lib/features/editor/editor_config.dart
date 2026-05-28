import '../../config/app_constants.dart';

/// 编辑器配置类
/// 集中管理编辑器相关的配置选项
/// 部分通用配置值已迁移到 AppConstants，这里保留编辑器特有的配置
class EditorConfig {
  // AI配置
  static const String defaultAIProvider = 'openai';
  static const int maxRetries = AppConstants.maxRetries;
  static const Duration aiTimeout = AppConstants.aiTimeout;

  // 编辑器配置
  static const int maxHistoryLength = 50;
  static const int maxFragmentCount = 100;
  static const int defaultMaxLines = null; // 无限制
  static const double defaultFontSize = AppConstants.defaultFontSize;
  static const double defaultLineHeight = AppConstants.defaultLineHeight;

  // UI配置 (使用 AppConstants 中的尺寸值)
  static const double defaultSidebarWidth = AppConstants.defaultSidebarWidth;
  static const double minSidebarWidth = AppConstants.minSidebarWidth;
  static const double maxSidebarWidth = AppConstants.maxSidebarWidth;
  static const bool defaultShowSidebar = true;

  // 思维碎片配置
  static const int fragmentPreviewLines = AppConstants.fragmentPreviewLines;
  static const int maxFragmentTags = AppConstants.maxFragmentTags;
  static const int maxTagLength = AppConstants.maxTagLength;

  // 格式清洗配置
  static const bool preserveHeaders = true;
  static const bool preserveLists = true;
  static const bool preserveCodeBlocks = true;

  // 性能配置 (使用 AppConstants 中的时间和缓存配置)
  static const int debounceDelay = AppConstants.debounceDelayMilliseconds;
  static const int autoSaveInterval = AppConstants.autoSaveIntervalSeconds;
  static const int maxCacheSize = AppConstants.maxCacheSizeBytesEditor ~/ (1024 * 1024); // 转换为MB

  // 快捷键配置
  static const Map<String, String> defaultShortcuts = {
    'polish': 'Ctrl+K',
    'expand': 'Ctrl+E',
    'outline': 'Ctrl+O',
    'undo': 'Ctrl+Z',
    'redo': 'Ctrl+Y',
  };

  // 主题配置 (使用 AppConstants 中的配置)
  static const bool supportDarkMode = AppConstants.supportDarkMode;
  static const bool supportSystemTheme = AppConstants.supportSystemTheme;

  // 用户体验配置 (使用 AppConstants 中的配置)
  static const bool showAnimations = AppConstants.showAnimations;
  static const bool showTooltips = AppConstants.showTooltips;
  static const bool showShortcutsInUI = AppConstants.showShortcutsInUI;
  static const Duration animationDuration = AppConstants.animationDuration;

  // 调试配置 (使用 AppConstants 中的配置)
  static const bool enableDebugMode = AppConstants.enableDebugMode;
  static const bool logAIRequests = AppConstants.logAIRequests;
  static const bool logUserActions = AppConstants.logUserActions;
}

/// AI服务配置
class AIServiceConfig {
  final String provider;
  final String? apiKey;
  final String model;
  final double temperature;
  final int maxTokens;
  final int timeoutSeconds;

  const AIServiceConfig({
    this.provider = 'openai',
    this.apiKey,
    this.model = 'gpt-4',
    this.temperature = 0.7,
    this.maxTokens = 2000,
    this.timeoutSeconds = 30,
  });

  AIServiceConfig copyWith({
    String? provider,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    int? timeoutSeconds,
  }) {
    return AIServiceConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }

  // OpenAI 配置
  static const openai = AIServiceConfig(
    provider: 'openai',
    model: 'gpt-4',
    temperature: 0.7,
    maxTokens: 2000,
  );

  // Claude 配置
  static const claude = AIServiceConfig(
    provider: 'claude',
    model: 'claude-3-opus-20240229',
    temperature: 0.7,
    maxTokens: 2000,
  );

  // DeepSeek 配置
  static const deepseek = AIServiceConfig(
    provider: 'deepseek',
    model: 'deepseek-chat',
    temperature: 0.7,
    maxTokens: 2000,
  );

  // 本地模型配置
  static const local = AIServiceConfig(
    provider: 'local',
    model: 'llama2',
    temperature: 0.7,
    maxTokens: 2000,
    timeoutSeconds: 60,
  );
}

/// 编辑器主题配置
class EditorThemeConfig {
  final bool isDark;
  final double fontSize;
  final double lineHeight;
  final String fontFamily;
  final bool showLineNumbers;
  final bool showMiniMap;

  const EditorThemeConfig({
    this.isDark = false,
    this.fontSize = 16.0,
    this.lineHeight = 1.6,
    this.fontFamily = 'system',
    this.showLineNumbers = false,
    this.showMiniMap = false,
  });

  EditorThemeConfig copyWith({
    bool? isDark,
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    bool? showLineNumbers,
    bool? showMiniMap,
  }) {
    return EditorThemeConfig(
      isDark: isDark ?? this.isDark,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      showMiniMap: showMiniMap ?? this.showMiniMap,
    );
  }

  // 默认主题
  static const defaultTheme = EditorThemeConfig();

  // 暗色主题
  static const darkTheme = EditorThemeConfig(isDark: true);

  // 大字体主题
  static const largeFontTheme = EditorThemeConfig(
    fontSize: 20.0,
    lineHeight: 1.8,
  );
}

/// 编辑器行为配置
class EditorBehaviorConfig {
  final bool autoSave;
  final int autoSaveInterval;
  final bool enableSpellCheck;
  final bool enableAutoComplete;
  final bool enableSmartSelection;
  final bool enableUndoRedo;

  const EditorBehaviorConfig({
    this.autoSave = true,
    this.autoSaveInterval = 30,
    this.enableSpellCheck = true,
    this.enableAutoComplete = true,
    this.enableSmartSelection = true,
    this.enableUndoRedo = true,
  });

  EditorBehaviorConfig copyWith({
    bool? autoSave,
    int? autoSaveInterval,
    bool? enableSpellCheck,
    bool? enableAutoComplete,
    bool? enableSmartSelection,
    bool? enableUndoRedo,
  }) {
    return EditorBehaviorConfig(
      autoSave: autoSave ?? this.autoSave,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      enableSpellCheck: enableSpellCheck ?? this.enableSpellCheck,
      enableAutoComplete: enableAutoComplete ?? this.enableAutoComplete,
      enableSmartSelection: enableSmartSelection ?? this.enableSmartSelection,
      enableUndoRedo: enableUndoRedo ?? this.enableUndoRedo,
    );
  }

  // 默认行为
  static const defaultBehavior = EditorBehaviorConfig();

  // 保守模式（关闭自动功能）
  static const conservativeBehavior = EditorBehaviorConfig(
    autoSave: false,
    enableSpellCheck: false,
    enableAutoComplete: false,
    enableSmartSelection: false,
  );
}

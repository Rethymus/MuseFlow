import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'ai_service_integration.dart';
import '../../utils/logger.dart';

/// AI服务配置管理器
/// 管理AI服务的配置选项和用户偏好
class AIServicesConfigManager {
  static const String _configKey = 'ai_services_config';
  static const String _userPreferencesKey = 'ai_user_preferences';

  final FlutterSecureStorage _secureStorage;
  AIServiceIntegrationConfig _currentConfig;
  Map<String, dynamic> _userPreferences = {};

  AIServicesConfigManager._({
    FlutterSecureStorage? secureStorage,
    AIServiceIntegrationConfig? initialConfig,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _currentConfig = initialConfig ?? AIServiceIntegrationConfig.defaultConfig();

  /// 获取单例实例
  static AIServicesConfigManager? _instance;

  static Future<AIServicesConfigManager> initialize({
    FlutterSecureStorage? secureStorage,
    AIServiceIntegrationConfig? initialConfig,
  }) async {
    if (_instance == null) {
      _instance = AIServicesConfigManager._(
        secureStorage: secureStorage,
        initialConfig: initialConfig,
      );
      await _instance!._loadConfig();
      await _instance!._loadUserPreferences();
    }
    return _instance!;
  }

  /// 获取实例
  static AIServicesConfigManager get instance {
    if (_instance == null) {
      throw StateError('AIServicesConfigManager not initialized');
    }
    return _instance!;
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      final configJson = await _secureStorage.read(key: _configKey);
      if (configJson != null) {
        final data = json.decode(configJson) as Map<String, dynamic>;
        _currentConfig = AIServiceIntegrationConfig.fromJson(data);
        Logger.info('加载AI服务配置成功', tag: 'AIConfig');
      }
    } catch (e) {
      Logger.warning('加载AI服务配置失败: $e', tag: 'AIConfig');
    }
  }

  /// 加载用户偏好
  Future<void> _loadUserPreferences() async {
    try {
      final prefsJson = await _secureStorage.read(key: _userPreferencesKey);
      if (prefsJson != null) {
        _userPreferences = json.decode(prefsJson) as Map<String, dynamic>;
        Logger.info('加载用户偏好成功', tag: 'AIConfig');
      }
    } catch (e) {
      Logger.warning('加载用户偏好失败: $e', tag: 'AIConfig');
    }
  }

  /// 保存配置
  Future<void> saveConfig() async {
    try {
      final configJson = json.encode(_currentConfig.toJson());
      await _secureStorage.write(key: _configKey, value: configJson);
      Logger.info('保存AI服务配置成功', tag: 'AIConfig');
    } catch (e) {
      Logger.error('保存AI服务配置失败: $e', tag: 'AIConfig');
      rethrow;
    }
  }

  /// 保存用户偏好
  Future<void> saveUserPreferences() async {
    try {
      final prefsJson = json.encode(_userPreferences);
      await _secureStorage.write(key: _userPreferencesKey, value: prefsJson);
      Logger.info('保存用户偏好成功', tag: 'AIConfig');
    } catch (e) {
      Logger.error('保存用户偏好失败: $e', tag: 'AIConfig');
      rethrow;
    }
  }

  /// 获取当前配置
  AIServiceIntegrationConfig get currentConfig => _currentConfig;

  /// 更新配置
  Future<void> updateConfig(AIServiceIntegrationConfig newConfig) async {
    _currentConfig = newConfig;
    await saveConfig();
  }

  /// 启用个性化服务
  Future<void> enablePersonalizedService() async {
    _currentConfig = _currentConfig.copyWith(
      enablePersonalizedService: true,
    );
    await saveConfig();
  }

  /// 禁用个性化服务
  Future<void> disablePersonalizedService() async {
    _currentConfig = _currentConfig.copyWith(
      enablePersonalizedService: false,
    );
    await saveConfig();
  }

  /// 启用上下文服务
  Future<void> enableContextualService() async {
    _currentConfig = _currentConfig.copyWith(
      enableContextualService: true,
    );
    await saveConfig();
  }

  /// 禁用上下文服务
  Future<void> disableContextualService() async {
    _currentConfig = _currentConfig.copyWith(
      enableContextualService: false,
    );
    await saveConfig();
  }

  /// 启用写作助手
  Future<void> enableWritingAssistant() async {
    _currentConfig = _currentConfig.copyWith(
      enableWritingAssistant: true,
    );
    await saveConfig();
  }

  /// 禁用写作助手
  Future<void> disableWritingAssistant() async {
    _currentConfig = _currentConfig.copyWith(
      enableWritingAssistant: false,
    );
    await saveConfig();
  }

  /// 设置上下文历史大小
  Future<void> setMaxContextHistory(int size) async {
    _currentConfig = _currentConfig.copyWith(
      maxContextHistory: size,
    );
    await saveConfig();
  }

  /// 设置风格分析阈值
  Future<void> setStyleAnalysisThreshold(double threshold) async {
    _currentConfig = _currentConfig.copyWith(
      styleAnalysisThreshold: threshold.clamp(0.0, 1.0),
    );
    await saveConfig();
  }

  /// 设置最大对话轮数
  Future<void> setMaxConversationTurns(int turns) async {
    _currentConfig = _currentConfig.copyWith(
      maxConversationTurns: turns,
    );
    await saveConfig();
  }

  /// 重置为默认配置
  Future<void> resetToDefaults() async {
    _currentConfig = AIServiceIntegrationConfig.defaultConfig();
    await saveConfig();
  }

  /// 获取用户偏好
  dynamic getUserPreference(String key) {
    return _userPreferences[key];
  }

  /// 设置用户偏好
  Future<void> setUserPreference(String key, dynamic value) async {
    _userPreferences[key] = value;
    await saveUserPreferences();
  }

  /// 移除用户偏好
  Future<void> removeUserPreference(String key) async {
    _userPreferences.remove(key);
    await saveUserPreferences();
  }

  /// 清除所有用户偏好
  Future<void> clearUserPreferences() async {
    _userPreferences.clear();
    await saveUserPreferences();
  }

  /// 获取预设配置
  static Map<String, AIServiceIntegrationConfig> getPresetConfigs() {
    return {
      'basic': AIServiceIntegrationConfig.basicOnly(),
      'default': AIServiceIntegrationConfig.defaultConfig(),
      'full': AIServiceIntegrationConfig.fullFeatured(),
      'minimal': const AIServiceIntegrationConfig(
        enablePersonalizedService: false,
        enableContextualService: false,
        enableWritingAssistant: false,
        enableCaching: false,
      ),
      'creative_writing': const AIServiceIntegrationConfig(
        enablePersonalizedService: true,
        enableContextualService: true,
        enableWritingAssistant: true,
        enableCaching: true,
        maxContextHistory: 100,
        styleAnalysisThreshold: 0.5,
        maxConversationTurns: 50,
      ),
      'technical_writing': const AIServiceIntegrationConfig(
        enablePersonalizedService: true,
        enableContextualService: true,
        enableWritingAssistant: true,
        enableCaching: true,
        maxContextHistory: 150,
        styleAnalysisThreshold: 0.8,
        maxConversationTurns: 30,
      ),
    };
  }

  /// 应用预设配置
  Future<void> applyPresetConfig(String presetName) async {
    final presets = getPresetConfigs();
    final preset = presets[presetName];

    if (preset == null) {
      throw ArgumentError('Unknown preset: $presetName');
    }

    _currentConfig = preset;
    await saveConfig();
    Logger.info('应用预设配置: $presetName', tag: 'AIConfig');
  }

  /// 获取配置描述
  String getConfigDescription(AIServiceIntegrationConfig config) {
    final features = <String>[];

    if (config.enablePersonalizedService) {
      features.add('个性化学习');
    }
    if (config.enableContextualService) {
      features.add('上下文感知');
    }
    if (config.enableWritingAssistant) {
      features.add('实时写作助手');
    }
    if (config.enableCaching) {
      features.add('智能缓存');
    }

    if (features.isEmpty) {
      return '基础AI服务';
    }

    return 'AI服务 (${features.join(', ')})';
  }

  /// 验证配置
  List<String> validateConfig(AIServiceIntegrationConfig config) {
    final issues = <String>[];

    if (config.maxContextHistory < 10) {
      issues.add('上下文历史大小过小，建议至少10');
    }

    if (config.maxContextHistory > 500) {
      issues.add('上下文历史大小过大，可能影响性能');
    }

    if (config.styleAnalysisThreshold < 0.1) {
      issues.add('风格分析阈值过低，可能产生过多误报');
    }

    if (config.styleAnalysisThreshold > 0.9) {
      issues.add('风格分析阈值过高，可能遗漏有用建议');
    }

    if (config.maxConversationTurns < 5) {
      issues.add('最大对话轮数过少，可能影响交互体验');
    }

    if (config.maxConversationTurns > 100) {
      issues.add('最大对话轮数过多，可能消耗大量资源');
    }

    return issues;
  }

  /// 获取优化建议
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];

    // 基于当前配置提供优化建议
    if (!_currentConfig.enableCaching) {
      suggestions.add('启用缓存可以提高响应速度');
    }

    if (_currentConfig.maxContextHistory < 50 &&
        _currentConfig.enableContextualService) {
      suggestions.add('增加上下文历史大小可以提供更精准的建议');
    }

    if (_currentConfig.styleAnalysisThreshold > 0.7) {
      suggestions.add('降低风格分析阈值可以获得更多建议');
    }

    if (!_currentConfig.enablePersonalizedService) {
      suggestions.add('启用个性化服务可以改善用户体验');
    }

    return suggestions;
  }

  /// 导出配置
  String exportConfig() {
    return json.encode({
      'config': _currentConfig.toJson(),
      'userPreferences': _userPreferences,
    });
  }

  /// 导入配置
  Future<void> importConfig(String configJson) async {
    try {
      final data = json.decode(configJson) as Map<String, dynamic>;

      if (data.containsKey('config')) {
        _currentConfig = AIServiceIntegrationConfig.fromJson(
          data['config'] as Map<String, dynamic>,
        );
      }

      if (data.containsKey('userPreferences')) {
        _userPreferences = data['userPreferences'] as Map<String, dynamic>;
      }

      await saveConfig();
      await saveUserPreferences();

      Logger.info('导入配置成功', tag: 'AIConfig');
    } catch (e) {
      Logger.error('导入配置失败: $e', tag: 'AIConfig');
      rethrow;
    }
  }

  /// 获取配置统计
  Map<String, dynamic> getConfigStats() {
    return {
      'enabledServices': {
        'personalized': _currentConfig.enablePersonalizedService,
        'contextual': _currentConfig.enableContextualService,
        'writingAssistant': _currentConfig.enableWritingAssistant,
        'caching': _currentConfig.enableCaching,
      },
      'performanceSettings': {
        'maxContextHistory': _currentConfig.maxContextHistory,
        'styleAnalysisThreshold': _currentConfig.styleAnalysisThreshold,
        'maxConversationTurns': _currentConfig.maxConversationTurns,
      },
      'userPreferencesCount': _userPreferences.length,
      'configVersion': '1.0',
    };
  }

  /// 比较两个配置
  static Map<String, dynamic> compareConfigs(
    AIServiceIntegrationConfig config1,
    AIServiceIntegrationConfig config2,
  ) {
    final differences = <String, dynamic>{};

    if (config1.enablePersonalizedService != config2.enablePersonalizedService) {
      differences['personalizedService'] = {
        'old': config1.enablePersonalizedService,
        'new': config2.enablePersonalizedService,
      };
    }

    if (config1.enableContextualService != config2.enableContextualService) {
      differences['contextualService'] = {
        'old': config1.enableContextualService,
        'new': config2.enableContextualService,
      };
    }

    if (config1.enableWritingAssistant != config2.enableWritingAssistant) {
      differences['writingAssistant'] = {
        'old': config1.enableWritingAssistant,
        'new': config2.enableWritingAssistant,
      };
    }

    if (config1.maxContextHistory != config2.maxContextHistory) {
      differences['maxContextHistory'] = {
        'old': config1.maxContextHistory,
        'new': config2.maxContextHistory,
      };
    }

    if (config1.styleAnalysisThreshold != config2.styleAnalysisThreshold) {
      differences['styleAnalysisThreshold'] = {
        'old': config1.styleAnalysisThreshold,
        'new': config2.styleAnalysisThreshold,
      };
    }

    return differences;
  }

  /// 清理资源
  Future<void> dispose() async {
    await saveConfig();
    await saveUserPreferences();
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_preference.dart';
import 'preference_learning_algorithm.dart';
import 'feedback_collector.dart';
import 'writing_analyzer.dart';

/// 用户偏好管理器
/// 负责管理用户学习数据的存储、检索和更新
class UserPreferenceManager {
  static UserPreferenceManager? _instance;
  static const String _preferenceKey = 'user_preference_data';
  static const String _configKey = 'preference_learning_config';
  static const String _feedbackKey = 'user_feedback_history';
  static const String _analyticsKey = 'writing_analytics_data';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _preferences;
  final WritingAnalyzer _writingAnalyzer;
  final FeedbackCollector _feedbackCollector;
  final PreferenceLearningAlgorithm _learningAlgorithm;

  UserPreference? _currentPreference;
  PreferenceLearningConfig? _config;
  final List<UserFeedback> _feedbackHistory = [];
  final List<WritingAnalysis> _writingAnalytics = [];
  final StreamController<UserPreference> _preferenceUpdateController =
      StreamController.broadcast();

  UserPreferenceManager._({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? preferences,
    WritingAnalyzer? writingAnalyzer,
    FeedbackCollector? feedbackCollector,
    PreferenceLearningAlgorithm? learningAlgorithm,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _preferences = preferences ?? (throw ArgumentError('SharedPreferences required')),
       _writingAnalyzer = writingAnalyzer ?? WritingAnalyzer.instance,
       _feedbackCollector = feedbackCollector ?? FeedbackCollector.instance,
       _learningAlgorithm = learningAlgorithm ?? PreferenceLearningAlgorithm.instance;

  /// 获取单例实例
  static Future<UserPreferenceManager> initialize({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? preferences,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    final prefs = preferences ?? await SharedPreferences.getInstance();
    _instance = UserPreferenceManager._(preferences: prefs);
    await _instance!._initialize();
    return _instance!;
  }

  /// 获取实例
  static UserPreferenceManager get instance {
    if (_instance == null) {
      throw StateError('UserPreferenceManager not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// 初始化管理器
  Future<void> _initialize() async {
    await loadPreference();
    await loadConfig();
    await loadFeedbackHistory();
    await loadWritingAnalytics();
  }

  /// 加载用户偏好
  Future<void> loadPreference() async {
    try {
      final preferenceJson = await _secureStorage.read(key: _preferenceKey);
      if (preferanceJson != null) {
        final data = json.decode(preferenceJson);
        _currentPreference = UserPreference.fromJson(data);
      } else {
        // 创建新的偏好配置
        _currentPreference = UserPreference.create();
        await savePreference();
      }
    } catch (e) {
      // 如果加载失败，创建新的偏好配置
      _currentPreference = UserPreference.create();
      await savePreference();
    }
  }

  /// 保存用户偏好
  Future<void> savePreference() async {
    if (_currentPreference == null) return;

    try {
      final updatedPreference = _currentPreference!.copyWith(
        updatedAt: DateTime.now(),
      );
      final json = jsonEncode(updatedPreference.toJson());
      await _secureStorage.write(key: _preferenceKey, value: json);
      _currentPreference = updatedPreference;

      // 通知更新
      _preferenceUpdateController.add(_currentPreference!);
    } catch (e) {
      throw UserPreferenceException('Failed to save preference: $e');
    }
  }

  /// 加载学习配置
  Future<void> loadConfig() async {
    try {
      final configJson = _preferences.getString(_configKey);
      if (configJson != null) {
        final data = json.decode(configJson);
        _config = PreferenceLearningConfig.fromJson(data);
      } else {
        _config = PreferenceLearningConfig.defaultConfig();
        await saveConfig();
      }
    } catch (e) {
      _config = PreferenceLearningConfig.defaultConfig();
      await saveConfig();
    }
  }

  /// 保存学习配置
  Future<void> saveConfig() async {
    if (_config == null) return;

    try {
      final json = jsonEncode(_config!.toJson());
      await _preferences.setString(_configKey, json);
    } catch (e) {
      throw UserPreferenceException('Failed to save config: $e');
    }
  }

  /// 加载反馈历史
  Future<void> loadFeedbackHistory() async {
    try {
      final feedbackJson = _preferences.getString(_feedbackKey);
      if (feedbackJson != null) {
        final List<dynamic> data = json.decode(feedbackJson);
        _feedbackHistory.clear();
        _feedbackHistory.addAll(
          data.map((item) => UserFeedback.fromJson(item as Map<String, dynamic>))
        );
      }
    } catch (e) {
      // 忽略错误，保持空列表
    }
  }

  /// 保存反馈历史
  Future<void> saveFeedbackHistory() async {
    try {
      final json = jsonEncode(
        _feedbackHistory.map((f) => f.toJson()).toList()
      );
      await _preferences.setString(_feedbackKey, json);
    } catch (e) {
      throw UserPreferenceException('Failed to save feedback history: $e');
    }
  }

  /// 加载写作分析数据
  Future<void> loadWritingAnalytics() async {
    try {
      final analyticsJson = _preferences.getString(_analyticsKey);
      if (analyticsJson != null) {
        final List<dynamic> data = json.decode(analyticsJson);
        _writingAnalytics.clear();
        _writingAnalytics.addAll(
          data.map((item) => WritingAnalysis.fromJson(item as Map<String, dynamic>))
        );
      }
    } catch (e) {
      // 忽略错误，保持空列表
    }
  }

  /// 保存写作分析数据
  Future<void> saveWritingAnalytics() async {
    try {
      final json = jsonEncode(
        _writingAnalytics.map((a) => a.toJson()).toList()
      );
      await _preferences.setString(_analyticsKey, json);
    } catch (e) {
      throw UserPreferenceException('Failed to save writing analytics: $e');
    }
  }

  /// 获取当前用户偏好
  UserPreference? get currentPreference => _currentPreference;

  /// 获取学习配置
  PreferenceLearningConfig get config => _config ?? PreferenceLearningConfig.defaultConfig();

  /// 获取反馈历史
  List<UserFeedback> get feedbackHistory => List.unmodifiable(_feedbackHistory);

  /// 获取写作分析数据
  List<WritingAnalysis> get writingAnalytics => List.unmodifiable(_writingAnalytics);

  /// 偏好更新流
  Stream<UserPreference> get preferenceUpdates => _preferenceUpdateController.stream;

  /// 添加用户反馈
  Future<void> addFeedback(UserFeedback feedback) async {
    if (!config.enabled) return;

    _feedbackHistory.add(feedback);

    // 限制历史记录大小
    if (_feedbackHistory.length > config.maxFeedbackHistory) {
      _feedbackHistory.removeAt(0);
    }

    await saveFeedbackHistory();

    // 触发学习
    await learnFromFeedback(feedback);
  }

  /// 从反馈中学习
  Future<void> learnFromFeedback(UserFeedback feedback) async {
    if (_currentPreference == null) return;

    try {
      // 使用学习算法更新偏好
      final updatedPreference = await _learningAlgorithm.learnFromFeedback(
        feedback,
        _currentPreference!,
        config,
      );

      _currentPreference = updatedPreference;
      await savePreference();
    } catch (e) {
      throw UserPreferenceException('Failed to learn from feedback: $e');
    }
  }

  /// 分析写作风格
  Future<WritingAnalysis> analyzeWriting(String text, {String? context}) async {
    if (!config.enabled) {
      return WritingAnalysis.create(
        text: text,
        languageStyle: LanguageStyle.unknown,
        detailLevel: DetailLevel.unknown,
        paragraphStructure: ParagraphStructure.unknown,
        sentenceComplexity: SentenceComplexity.unknown,
      );
    }

    try {
      final analysis = await _writingAnalyzer.analyze(text, context: context);

      // 保存分析结果
      _writingAnalytics.add(analysis);

      // 限制分析数据大小
      if (_writingAnalytics.length > 500) {
        _writingAnalytics.removeAt(0);
      }

      await saveWritingAnalytics();

      // 从写作样本中学习
      await learnFromWriting(analysis);

      return analysis;
    } catch (e) {
      throw UserPreferenceException('Failed to analyze writing: $e');
    }
  }

  /// 从写作样本中学习
  Future<void> learnFromWriting(WritingAnalysis analysis) async {
    if (_currentPreference == null) return;

    try {
      final updatedPreference = await _learningAlgorithm.learnFromWriting(
        analysis,
        _currentPreference!,
        config,
      );

      _currentPreference = updatedPreference;
      await savePreference();
    } catch (e) {
      throw UserPreferenceException('Failed to learn from writing: $e');
    }
  }

  /// 获取个性化建议
  Map<String, dynamic> getPersonalizedSuggestions(String text) {
    if (_currentPreference == null || !config.enabled) {
      return {};
    }

    return _learningAlgorithm.generateSuggestions(text, _currentPreference!);
  }

  /// 调整AI建议
  String adjustAISuggestion(String originalSuggestion, String context) {
    if (_currentPreference == null || !config.enabled) {
      return originalSuggestion;
    }

    if (!_currentPreference!.hasSufficientConfidence(config.confidenceThreshold)) {
      return originalSuggestion;
    }

    return _learningAlgorithm.adjustSuggestion(
      originalSuggestion,
      context,
      _currentPreference!,
    );
  }

  /// 更新配置
  Future<void> updateConfig(PreferenceLearningConfig newConfig) async {
    _config = newConfig;
    await saveConfig();
  }

  /// 重置偏好数据
  Future<void> resetPreferences() async {
    _currentPreference = UserPreference.create();
    await savePreference();

    _feedbackHistory.clear();
    await saveFeedbackHistory();

    _writingAnalytics.clear();
    await saveWritingAnalytics();
  }

  /// 清除所有数据
  Future<void> clearAllData() async {
    await resetPreferences();

    await _secureStorage.delete(key: _preferenceKey);
    await _preferences.remove(_configKey);
    await _preferences.remove(_feedbackKey);
    await _preferences.remove(_analyticsKey);

    _currentPreference = null;
    _config = null;
  }

  /// 导出偏好数据
  Future<Map<String, dynamic>> exportData() async {
    return {
      'preference': _currentPreference?.toJson(),
      'config': _config?.toJson(),
      'feedbackCount': _feedbackHistory.length,
      'analyticsCount': _writingAnalytics.length,
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// 获取学习统计
  Map<String, dynamic> getLearningStats() {
    final preference = _currentPreference;
    if (preference == null) {
      return {'error': 'No preference data available'};
    }

    return {
      'learningDataPoints': preference.learningDataPoints,
      'confidenceScore': preference.confidenceScore,
      'learningProgress': preference.learningProgress,
      'overallAcceptanceRate': preference.overallAcceptanceRate,
      'hasSufficientConfidence': preference.hasSufficientConfidence(config.confidenceThreshold),
      'topModificationTypes': preference.getTopModificationTypes(5),
      'topTopics': preference.getTopTopics(10),
      'feedbackHistorySize': _feedbackHistory.length,
      'writingAnalyticsSize': _writingAnalytics.length,
      'summary': preference.getSummary(),
    };
  }

  /// 获取隐私报告
  Future<Map<String, dynamic>> getPrivacyReport() async {
    return {
      'dataStoredLocally': true,
      'dataStoredInSecureStorage': true,
      'feedbackHistorySize': _feedbackHistory.length,
      'writingAnalyticsSize': _writingAnalytics.length,
      'dataRetentionDays': config.dataRetentionDays,
      'anonymizeData': config.anonymizeData,
      'autoApplyEnabled': config.autoApply,
      'configEnabled': config.enabled,
      'learningDataPoints': _currentPreference?.learningDataPoints ?? 0,
      'lastUpdate': _currentPreference?.updatedAt.toIso8601String(),
    };
  }

  /// 清除过期数据
  Future<void> clearExpiredData() async {
    final cutoffDate = DateTime.now().subtract(Duration(days: config.dataRetentionDays));

    // 清除过期的反馈历史
    _feedbackHistory.removeWhere((feedback) =>
      feedback.timestamp.isBefore(cutoffDate));

    // 清除过期的写作分析
    _writingAnalytics.removeWhere((analysis) =>
      analysis.timestamp.isBefore(cutoffDate));

    await saveFeedbackHistory();
    await saveWritingAnalytics();
  }

  /// 释放资源
  void dispose() {
    _preferenceUpdateController.close();
  }
}

/// 用户偏好异常
class UserPreferenceException implements Exception {
  final String message;
  final dynamic originalError;

  UserPreferenceException(this.message, {this.originalError});

  @override
  String toString() => 'UserPreferenceException: $message';
}
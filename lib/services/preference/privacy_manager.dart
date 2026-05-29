import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_preference.dart';

/// 隐私管理器
/// 负责管理用户隐私设置和数据保护
class PrivacyManager {
  static PrivacyManager? _instance;
  static const String _consentKey = 'privacy_consent_given';
  static const String _privacyVersionKey = 'privacy_policy_version';
  static const String _dataDeletionScheduledKey = 'data_deletion_scheduled';
  static const int _currentPrivacyVersion = 1;

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _preferences;
  Timer? _cleanupTimer;

  PrivacyManager._({
    FlutterSecureStorage? secureStorage,
    required SharedPreferences preferences,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _preferences = preferences;

  /// 获取单例实例
  static Future<PrivacyManager> initialize({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? preferences,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    final prefs = preferences ?? await SharedPreferences.getInstance();
    _instance = PrivacyManager._(preferences: prefs);
    await _instance!._initialize();
    return _instance!;
  }

  /// 获取实例
  static PrivacyManager get instance {
    if (_instance == null) {
      throw StateError(
          'PrivacyManager not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// 初始化管理器
  Future<void> _initialize() async {
    // 启动定期清理任务
    _startCleanupTimer();
  }

  /// 启动清理定时器
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    // 每天检查一次过期数据
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => _performScheduledCleanup(),
    );
  }

  /// 执行定时清理
  Future<void> _performScheduledCleanup() async {
    final deletionScheduled =
        _preferences.getBool(_dataDeletionScheduledKey) ?? false;
    if (deletionScheduled) {
      await clearExpiredData();
      await _preferences.setBool(_dataDeletionScheduledKey, false);
    }
  }

  /// 检查是否需要隐私同意
  Future<bool> needsPrivacyConsent() async {
    final consentGiven = _preferences.getBool(_consentKey) ?? false;
    final privacyVersion = _preferences.getInt(_privacyVersionKey) ?? 0;

    return !consentGiven || privacyVersion < _currentPrivacyVersion;
  }

  /// 记录隐私同意
  Future<void> recordPrivacyConsent() async {
    await _preferences.setBool(_consentKey, true);
    await _preferences.setInt(_privacyVersionKey, _currentPrivacyVersion);
  }

  /// 撤销隐私同意
  Future<void> revokePrivacyConsent() async {
    await _preferences.setBool(_consentKey, false);

    // 安排删除所有数据
    await scheduleDataDeletion();
  }

  /// 安排数据删除
  Future<void> scheduleDataDeletion() async {
    await _preferences.setBool(_dataDeletionScheduledKey, true);
  }

  /// 清除过期数据
  Future<void> clearExpiredData({
    int? retentionDays,
    String? feedbackKey,
    String? analyticsKey,
  }) async {
    try {
      final days = retentionDays ?? 90;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      // 清除反馈历史
      await _clearExpiredFeedback(cutoffDate, feedbackKey);
      // 清除写作分析数据
      await _clearExpiredAnalytics(cutoffDate, analyticsKey);
    } catch (e) {
      throw PrivacyException('Failed to clear expired data: $e');
    }
  }

  /// 清除过期的反馈数据
  Future<void> _clearExpiredFeedback(DateTime cutoffDate, String? key) async {
    const feedbackKey = 'user_feedback_history';
    final finalKey = key ?? feedbackKey;

    try {
      final feedbackJson = _preferences.getString(finalKey);
      if (feedbackJson != null) {
        final List<dynamic> data = jsonDecode(feedbackJson);
        final validFeedbacks = data.where((item) {
          final feedback = UserFeedback.fromJson(item as Map<String, dynamic>);
          return feedback.timestamp.isAfter(cutoffDate);
        }).toList();

        await _preferences.setString(finalKey, jsonEncode(validFeedbacks));
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 清除过期的分析数据
  Future<void> _clearExpiredAnalytics(DateTime cutoffDate, String? key) async {
    const analyticsKey = 'writing_analytics_data';
    final finalKey = key ?? analyticsKey;

    try {
      final analyticsJson = _preferences.getString(finalKey);
      if (analyticsJson != null) {
        final List<dynamic> data = jsonDecode(analyticsJson);
        final validAnalytics = data.where((item) {
          final analysis =
              WritingAnalysis.fromJson(item as Map<String, dynamic>);
          return analysis.timestamp.isAfter(cutoffDate);
        }).toList();

        await _preferences.setString(finalKey, jsonEncode(validAnalytics));
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 匿名化数据
  Future<Map<String, dynamic>> anonymizeData(Map<String, dynamic> data) async {
    final anonymized = Map<String, dynamic>.from(data);

    // 移除或匿名化敏感字段
    final sensitiveKeys = ['userId', 'email', 'name', 'ipAddress'];
    for (final key in sensitiveKeys) {
      if (anonymized.containsKey(key)) {
        anonymized[key] = _hashValue(anonymized[key].toString());
      }
    }

    // 移除时间戳的具体信息
    if (anonymized.containsKey('timestamp')) {
      final timestamp = DateTime.parse(anonymized['timestamp']);
      anonymized['timestamp'] =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    }

    return anonymized;
  }

  /// 哈希值（用于匿名化）
  String _hashValue(String value) {
    // 简单的哈希函数，实际应用中应使用更安全的哈希算法
    var hash = 0;
    for (var i = 0; i < value.length; i++) {
      hash = (hash + value.codeUnitAt(i) * 31) % 0xFFFFFFFF;
    }
    return 'hash_$hash';
  }

  /// 获取隐私报告
  Future<Map<String, dynamic>> getPrivacyReport({
    String? preferenceKey,
    String? feedbackKey,
    String? analyticsKey,
  }) async {
    const prefKey = 'user_preference_data';
    const feedKey = 'user_feedback_history';
    const analyticKey = 'writing_analytics_data';

    try {
      // 统计数据量
      int feedbackCount = 0;
      int analyticsCount = 0;

      final feedbackJson = _preferences.getString(feedbackKey ?? feedKey);
      if (feedbackJson != null) {
        final List<dynamic> data = jsonDecode(feedbackJson);
        feedbackCount = data.length;
      }

      final analyticsJson = _preferences.getString(analyticsKey ?? analyticKey);
      if (analyticsJson != null) {
        final List<dynamic> data = jsonDecode(analyticsJson);
        analyticsCount = data.length;
      }

      return {
        'dataStoredLocally': true,
        'dataStoredInSecureStorage': true,
        'feedbackCount': feedbackCount,
        'analyticsCount': analyticsCount,
        'consentGiven': _preferences.getBool(_consentKey) ?? false,
        'privacyVersion': _preferences.getInt(_privacyVersionKey) ?? 0,
        'currentPrivacyVersion': _currentPrivacyVersion,
        'deletionScheduled':
            _preferences.getBool(_dataDeletionScheduledKey) ?? false,
      };
    } catch (e) {
      throw PrivacyException('Failed to generate privacy report: $e');
    }
  }

  /// 导出数据（用于用户查看）
  Future<Map<String, dynamic>> exportUserData({
    bool anonymize = false,
  }) async {
    try {
      Map<String, dynamic> userData = {};

      // 导出偏好数据
      final preferenceData =
          await _secureStorage.read(key: 'user_preference_data');
      if (preferenceData != null) {
        userData['preference'] = jsonDecode(preferenceData);
      }

      // 导出反馈历史（匿名化）
      final feedbackData = _preferences.getString('user_feedback_history');
      if (feedbackData != null) {
        final feedbacks = jsonDecode(feedbackData);
        userData['feedbackHistory'] = anonymize
            ? await Future.wait(
                (feedbacks as List)
                    .map((f) => anonymizeData(f as Map<String, dynamic>)),
              )
            : feedbacks;
      }

      // 导出分析数据（匿名化）
      final analyticsData = _preferences.getString('writing_analytics_data');
      if (analyticsData != null) {
        final analytics = jsonDecode(analyticsData);
        userData['writingAnalytics'] = anonymize
            ? await Future.wait(
                (analytics as List)
                    .map((a) => anonymizeData(a as Map<String, dynamic>)),
              )
            : analytics;
      }

      userData['exportDate'] = DateTime.now().toIso8601String();
      userData['anonymized'] = anonymize;

      return userData;
    } catch (e) {
      throw PrivacyException('Failed to export user data: $e');
    }
  }

  /// 完全删除所有用户数据
  Future<void> deleteAllUserData({
    List<String>? additionalKeys,
  }) async {
    try {
      // 删除偏好数据
      await _secureStorage.delete(key: 'user_preference_data');

      // 删除反馈历史
      await _preferences.remove('user_feedback_history');

      // 删除分析数据
      await _preferences.remove('writing_analytics_data');

      // 删除配置
      await _preferences.remove('preference_learning_config');

      // 删除同意记录
      await _preferences.remove(_consentKey);
      await _preferences.remove(_privacyVersionKey);
      await _preferences.remove(_dataDeletionScheduledKey);

      // 删除额外的键
      if (additionalKeys != null) {
        for (final key in additionalKeys) {
          await _preferences.remove(key);
          await _secureStorage.delete(key: key);
        }
      }
    } catch (e) {
      throw PrivacyException('Failed to delete all user data: $e');
    }
  }

  /// 获取数据大小估算
  Future<Map<String, int>> getDataSize() async {
    int preferenceSize = 0;
    int feedbackSize = 0;
    int analyticsSize = 0;

    try {
      final preferenceData =
          await _secureStorage.read(key: 'user_preference_data');
      preferenceSize = preferenceData?.length ?? 0;

      final feedbackData = _preferences.getString('user_feedback_history');
      feedbackSize = feedbackData?.length ?? 0;

      final analyticsData = _preferences.getString('writing_analytics_data');
      analyticsSize = analyticsData?.length ?? 0;
    } catch (e) {
      // 忽略错误
    }

    return {
      'preference': preferenceSize,
      'feedback': feedbackSize,
      'analytics': analyticsSize,
      'total': preferenceSize + feedbackSize + analyticsSize,
    };
  }

  /// 释放资源
  void dispose() {
    _cleanupTimer?.cancel();
  }
}

/// 隐私异常
class PrivacyException implements Exception {
  final String message;
  final dynamic originalError;

  PrivacyException(this.message, {this.originalError});

  @override
  String toString() => 'PrivacyException: $message';
}

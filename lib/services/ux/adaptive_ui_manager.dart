import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// AdaptiveUIManager - 自适应UI管理器
/// 负责学习用户习惯并生成个性化界面布局
class AdaptiveUIManager {
  static const String _preferencesKey = 'adaptive_ui_preferences';
  static AdaptiveUIManager? _instance;

  SharedPreferences? _prefs;
  Map<String, dynamic> _userHabits = {};
  Map<String, dynamic> _layoutPreferences = {};

  // 私有构造函数
  AdaptiveUIManager._();

  /// 获取单例实例
  static AdaptiveUIManager get instance {
    _instance ??= AdaptiveUIManager._();
    return _instance!;
  }

  /// 初始化管理器
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadUserHabits();
    await _loadLayoutPreferences();
  }

  /// 加载用户习惯数据
  Future<void> _loadUserHabits() async {
    final habitsJson = _prefs?.getString(_preferencesKey);
    if (habitsJson != null) {
      try {
        _userHabits = json.decode(habitsJson) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Failed to load user habits: $e');
        _userHabits = {};
      }
    }

    // 初始化默认习惯
    _userHabits.putIfAbsent('preferredFontSize', () => 16.0);
    _userHabits.putIfAbsent('preferredLineHeight', () => 1.5);
    _userHabits.putIfAbsent('preferredTheme', () => 'system');
    _userHabits.putIfAbsent('preferredLayoutDensity', () => 'comfortable');
    _userHabits.putIfAbsent('mostUsedFeatures', () => <String>[]);
    _userHabits.putIfAbsent('writingSessions', () => 0);
    _userHabits.putIfAbsent('avgSessionDuration', () => 0);
  }

  /// 加载布局偏好
  Future<void> _loadLayoutPreferences() async {
    final layoutJson = _prefs?.getString('$_preferencesKey${'\'}_layout');
    if (layoutJson != null) {
      try {
        _layoutPreferences = json.decode(layoutJson) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Failed to load layout preferences: $e');
        _layoutPreferences = {};
      }
    }
  }

  /// 记录用户行为
  Future<void> trackUserBehavior(
      String action, Map<String, dynamic> data) async {
    switch (action) {
      case 'feature_used':
        await _trackFeatureUsage(data['feature'] as String);
        break;
      case 'writing_session':
        await _trackWritingSession(data['duration'] as int);
        break;
      case 'font_size_changed':
        _userHabits['preferredFontSize'] = data['size'] as double;
        break;
      case 'theme_changed':
        _userHabits['preferredTheme'] = data['theme'] as String;
        break;
      case 'layout_density_changed':
        _userHabits['preferredLayoutDensity'] = data['density'] as String;
        break;
    }
    await _saveUserHabits();
  }

  /// 跟踪功能使用
  Future<void> _trackFeatureUsage(String feature) async {
    final usedFeatures = _userHabits['mostUsedFeatures'] as List<String>;
    if (!usedFeatures.contains(feature)) {
      usedFeatures.add(feature);
    }
    _userHabits['mostUsedFeatures'] = usedFeatures;
  }

  /// 跟踪写作会话
  Future<void> _trackWritingSession(int durationMinutes) async {
    final sessions = (_userHabits['writingSessions'] as int) + 1;
    final avgDuration = _userHabits['avgSessionDuration'] as int;

    _userHabits['writingSessions'] = sessions;
    _userHabits['avgSessionDuration'] =
        ((avgDuration * (sessions - 1) + durationMinutes) / sessions).round();
  }

  /// 保存用户习惯
  Future<void> _saveUserHabits() async {
    await _prefs?.setString(_preferencesKey, json.encode(_userHabits));
  }

  /// 生成个性化布局
  Widget buildAdaptiveLayout({
    required Widget child,
    Map<String, dynamic>? customPreferences,
  }) {
    final prefs = customPreferences ?? _layoutPreferences;
    final density = prefs['layoutDensity'] as String? ??
        _userHabits['preferredLayoutDensity'] as String;

    return AdaptiveLayout(
      density: density,
      fontSize: _userHabits['preferredFontSize'] as double,
      child: child,
    );
  }

  /// 获取推荐的UI组件
  List<UIComponentRecommendation> getRecommendedComponents() {
    final recommendations = <UIComponentRecommendation>[];
    final usedFeatures = _userHabits['mostUsedFeatures'] as List<String>;
    final sessions = _userHabits['writingSessions'] as int;

    // 基于使用频率推荐
    for (final feature in usedFeatures) {
      recommendations.add(UIComponentRecommendation(
        componentId: feature,
        priority: _calculatePriority(feature, usedFeatures),
        reason: '基于您的使用习惯推荐',
      ));
    }

    // 基于写作经验推荐
    if (sessions > 10) {
      recommendations.add(UIComponentRecommendation(
        componentId: 'advanced_statistics',
        priority: Priority.medium,
        reason: '您是一位活跃的作者，可能需要详细的数据分析',
      ));
    }

    // 按优先级排序
    recommendations
        .sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return recommendations;
  }

  /// 计算组件优先级
  Priority _calculatePriority(String feature, List<String> usedFeatures) {
    final index = usedFeatures.indexOf(feature);
    if (index == 0) return Priority.high;
    if (index < 3) return Priority.medium;
    return Priority.low;
  }

  /// 获取用户偏好
  Map<String, dynamic> getUserPreferences() {
    return Map<String, dynamic>.from(_userHabits);
  }

  /// 更新布局偏好
  Future<void> updateLayoutPreference(String key, dynamic value) async {
    _layoutPreferences[key] = value;
    await _prefs?.setString(
        '$_preferencesKey${'\'}_layout', json.encode(_layoutPreferences));
  }

  /// 重置所有习惯数据
  Future<void> resetHabits() async {
    _userHabits.clear();
    _layoutPreferences.clear();
    await _prefs?.remove(_preferencesKey);
    await _prefs?.remove('$_preferencesKey${'\'}_layout');
    await _loadUserHabits();
  }

  /// 获取自适应主题
  ThemeData getAdaptiveTheme(ThemeData baseTheme) {
    final fontSize = _userHabits['preferredFontSize'] as double;
    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.copyWith(
        bodyLarge: TextStyle(fontSize: fontSize),
        bodyMedium: TextStyle(fontSize: fontSize - 2),
      ),
    );
  }

  /// 智能组件推荐
  List<String> getSmartSuggestions() {
    final suggestions = <String>[];
    final usedFeatures = _userHabits['mostUsedFeatures'] as List<String>;
    final avgDuration = _userHabits['avgSessionDuration'] as int;

    // 基于写作时长建议
    if (avgDuration > 30) {
      suggestions.add('focus_mode');
      suggestions.add('break_reminder');
    }

    // 基于功能使用建议
    if (usedFeatures.contains('ai_assistant')) {
      suggestions.add('ai_shortcuts');
    }

    return suggestions;
  }
}

/// 自适应布局包装器
class AdaptiveLayout extends StatelessWidget {
  final String density;
  final double fontSize;
  final Widget child;

  const AdaptiveLayout({
    super.key,
    required this.density,
    required this.fontSize,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    double paddingValue;

    switch (density) {
      case 'compact':
        paddingValue = 8.0;
        spacingValue = 4.0;
        break;
      case 'comfortable':
        paddingValue = 16.0;
        spacingValue = 8.0;
        break;
      case 'spacious':
        paddingValue = 24.0;
        spacingValue = 16.0;
        break;
      default:
        paddingValue = 16.0;
        spacingValue = 8.0;
    }

    return Theme(
      data: Theme.of(context).copyWith(
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(paddingValue),
        child: child,
      ),
    );
  }
}

/// UI组件推荐数据类
class UIComponentRecommendation {
  final String componentId;
  final Priority priority;
  final String reason;

  UIComponentRecommendation({
    required this.componentId,
    required this.priority,
    required this.reason,
  });

  @override
  String toString() => '$componentId ($priority): $reason';
}

/// 优先级枚举
enum Priority { high, medium, low }

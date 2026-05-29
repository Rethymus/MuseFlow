import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

/// InteractionAnalyzer - 用户交互模式分析器
/// 学习用户交互模式，分析使用习惯，生成优化建议
class InteractionAnalyzer {
  static const String _interactionsKey = 'user_interactions';
  static const String _patternsKey = 'interaction_patterns';
  static InteractionAnalyzer? _instance;

  SharedPreferences? _prefs;
  final List<InteractionEvent> _interactionHistory = [];
  Map<String, InteractionPattern> _patterns = {};
  bool _isRecording = false;

  // 私有构造函数
  InteractionAnalyzer._();

  /// 获取单例实例
  static InteractionAnalyzer get instance {
    _instance ??= InteractionAnalyzer._();
    return _instance!;
  }

  /// 初始化分析器
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadInteractionHistory();
    await _loadPatterns();
    _isRecording = true;
  }

  /// 加载交互历史
  Future<void> _loadInteractionHistory() async {
    final historyJson = _prefs?.getString(_interactionsKey);
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = json.decode(historyJson) as List<dynamic>;
        _interactionHistory.addAll(
          decoded
              .map((e) => InteractionEvent.fromJson(e as Map<String, dynamic>)),
        );
      } catch (e) {
        debugPrint('Failed to load interaction history: $e');
      }
    }
  }

  /// 加载交互模式
  Future<void> _loadPatterns() async {
    final patternsJson = _prefs?.getString(_patternsKey);
    if (patternsJson != null) {
      try {
        final Map<String, dynamic> decoded =
            json.decode(patternsJson) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _patterns[key] =
              InteractionPattern.fromJson(value as Map<String, dynamic>);
        });
      } catch (e) {
        debugPrint('Failed to load patterns: $e');
      }
    }
  }

  /// 记录交互事件
  Future<void> recordInteraction(
    String eventType,
    Map<String, dynamic>? data,
  ) async {
    if (!_isRecording) return;

    final event = InteractionEvent(
      type: eventType,
      timestamp: DateTime.now(),
      data: data ?? {},
    );

    _interactionHistory.add(event);

    // 保持历史记录在合理范围内
    if (_interactionHistory.length > 1000) {
      _interactionHistory.removeAt(0);
    }

    // 分析新模式
    await _analyzeNewPattern(event);

    // 保存数据
    await _saveInteractionHistory();
  }

  /// 分析新模式
  Future<void> _analyzeNewPattern(InteractionEvent event) async {
    // 按事件类型分组
    final typeEvents =
        _interactionHistory.where((e) => e.type == event.type).toList();

    if (typeEvents.length < 3) return; // 需要足够的数据点

    // 分析时间模式
    final hourPatterns = _analyzeHourlyPatterns(typeEvents);
    final durationPatterns = _analyzeDurationPatterns(typeEvents);

    // 更新模式
    final patternId = event.type;
    final existingPattern = _patterns[patternId];

    _patterns[patternId] = InteractionPattern(
      eventType: event.type,
      frequency: typeEvents.length.toDouble(),
      lastOccurrence: event.timestamp,
      avgInterval: _calculateAvgInterval(typeEvents),
      preferredHour: hourPatterns,
      typicalDuration: durationPatterns,
      confidence: existingPattern?.confidence ?? 0.5,
    );

    await _savePatterns();
  }

  /// 分析小时级模式
  Map<int, double> _analyzeHourlyPatterns(List<InteractionEvent> events) {
    final hourCounts = <int, int>{};

    for (final event in events) {
      final hour = event.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    final total = hourCounts.values.reduce((a, b) => a + b);
    final normalized = <int, double>{};

    hourCounts.forEach((hour, count) {
      normalized[hour] = count / total;
    });

    return normalized;
  }

  /// 分析持续时长模式
  Map<String, double> _analyzeDurationPatterns(List<InteractionEvent> events) {
    final durations = <String, List<double>>{
      'short': [],
      'medium': [],
      'long': [],
    };

    for (var i = 0; i < events.length - 1; i++) {
      final duration =
          events[i + 1].timestamp.difference(events[i].timestamp).inMinutes;

      if (duration < 5) {
        durations['short']!.add(duration.toDouble());
      } else if (duration < 30) {
        durations['medium']!.add(duration.toDouble());
      } else {
        durations['long']!.add(duration.toDouble());
      }
    }

    final averages = <String, double>{};
    durations.forEach((key, values) {
      if (values.isNotEmpty) {
        averages[key] = values.reduce((a, b) => a + b) / values.length;
      }
    });

    return averages;
  }

  /// 计算平均间隔
  double _calculateAvgInterval(List<InteractionEvent> events) {
    if (events.length < 2) return 0.0;

    double totalInterval = 0;
    for (var i = 0; i < events.length - 1; i++) {
      totalInterval +=
          events[i + 1].timestamp.difference(events[i].timestamp).inSeconds;
    }

    return totalInterval / (events.length - 1);
  }

  /// 获取使用习惯分析
  List<UsageInsight> getUsageInsights() {
    final insights = <UsageInsight>[];

    // 分析写作时间偏好
    final writingEvents =
        _interactionHistory.where((e) => e.type == 'writing_session').toList();

    if (writingEvents.isNotEmpty) {
      final hourStats = _analyzeHourlyPatterns(writingEvents);
      final peakHour =
          hourStats.entries.reduce((a, b) => a.value > b.value ? a : b);

      insights.add(UsageInsight(
        type: InsightType.writingHabit,
        title: '写作时间偏好',
        description: '您最活跃的写作时间是 ${peakHour.key}:00',
        actionable: true,
        suggestion: '建议在这个时间段安排重要的写作任务',
      ));
    }

    // 分析使用频率
    if (_interactionHistory.length > 100) {
      insights.add(UsageInsight(
        type: InsightType.engagement,
        title: '使用频率分析',
        description: '您是我们的活跃用户',
        actionable: false,
        suggestion: '继续保持良好的使用习惯',
      ));
    }

    // 分析功能使用
    final featureUsage = _analyzeFeatureUsage();
    final mostUsed =
        featureUsage.entries.reduce((a, b) => a.value > b.value ? a : b);

    insights.add(UsageInsight(
      type: InsightType.featurePreference,
      title: '最常用功能',
      description: '您最常使用 ${mostUsed.key}',
      actionable: true,
      suggestion: '可以探索该功能的高级选项',
    ));

    return insights;
  }

  /// 分析功能使用情况
  Map<String, int> _analyzeFeatureUsage() {
    final usage = <String, int>{};

    for (final event in _interactionHistory) {
      if (event.type.startsWith('feature_')) {
        final feature = event.type.substring(8); // 移除 'feature_' 前缀
        usage[feature] = (usage[feature] ?? 0) + 1;
      }
    }

    return usage;
  }

  /// 获取优化建议
  List<OptimizationSuggestion> getOptimizationSuggestions() {
    final suggestions = <OptimizationSuggestion>[];

    // 基于使用模式提供建议
    for (final pattern in _patterns.values) {
      if (pattern.frequency > 10 && pattern.confidence > 0.7) {
        suggestions.add(OptimizationSuggestion(
          category: SuggestionCategory.efficiency,
          title: '优化 ${pattern.eventType}',
          description: '基于您的使用习惯，可以调整此功能的设置',
          priority: _calculateSuggestionPriority(pattern),
          estimatedImpact: _calculateEstimatedImpact(pattern),
        ));
      }
    }

    // 基于时间模式的建议
    final timeBasedSuggestion = _getTimeBasedSuggestion();
    if (timeBasedSuggestion != null) {
      suggestions.add(timeBasedSuggestion);
    }

    // 按优先级排序
    suggestions.sort((a, b) => b.priority.compareTo(a.priority));

    return suggestions;
  }

  /// 计算建议优先级
  SuggestionPriority _calculateSuggestionPriority(InteractionPattern pattern) {
    if (pattern.frequency > 50 && pattern.confidence > 0.8) {
      return SuggestionPriority.high;
    } else if (pattern.frequency > 20) {
      return SuggestionPriority.medium;
    }
    return SuggestionPriority.low;
  }

  /// 计算预期影响
  double _calculateEstimatedImpact(InteractionPattern pattern) {
    return pattern.confidence * (pattern.frequency / 100).clamp(0.0, 1.0);
  }

  /// 获取基于时间的建议
  OptimizationSuggestion? _getTimeBasedSuggestion() {
    final currentHour = DateTime.now().hour;
    double maxRelevance = 0;
    String? bestFeature;

    for (final pattern in _patterns.values) {
      final hourRelevance = pattern.preferredHour[currentHour] ?? 0.0;
      if (hourRelevance > maxRelevance) {
        maxRelevance = hourRelevance;
        bestFeature = pattern.eventType;
      }
    }

    if (bestFeature != null && maxRelevance > 0.3) {
      return OptimizationSuggestion(
        category: SuggestionCategory.personalization,
        title: '当前时间建议',
        description: '基于您的历史使用，现在可能适合使用 $bestFeature',
        priority: maxRelevance > 0.6
            ? SuggestionPriority.high
            : SuggestionPriority.medium,
        estimatedImpact: maxRelevance,
      );
    }

    return null;
  }

  /// 获取预测的下一步操作
  List<String> getPredictedNextActions(String currentAction) {
    final predictions = <String>[];

    // 查找当前操作后的常见后续操作
    final subsequentActions = <String, int>{};

    for (var i = 0; i < _interactionHistory.length - 1; i++) {
      if (_interactionHistory[i].type == currentAction) {
        final nextAction = _interactionHistory[i + 1].type;
        subsequentActions[nextAction] =
            (subsequentActions[nextAction] ?? 0) + 1;
      }
    }

    // 按频率排序并返回前3个
    final sorted = subsequentActions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var i = 0; i < min(3, sorted.length); i++) {
      predictions.add(sorted[i].key);
    }

    return predictions;
  }

  /// 保存交互历史
  Future<void> _saveInteractionHistory() async {
    if (_interactionHistory.length > 100) {
      final toSave =
          _interactionHistory.skip(_interactionHistory.length - 100).toList();
      await _prefs?.setString(
        _interactionsKey,
        json.encode(toSave.map((e) => e.toJson()).toList()),
      );
    } else {
      await _prefs?.setString(
        _interactionsKey,
        json.encode(_interactionHistory.map((e) => e.toJson()).toList()),
      );
    }
  }

  /// 保存模式
  Future<void> _savePatterns() async {
    final patternsJson = <String, dynamic>{};
    _patterns.forEach((key, value) {
      patternsJson[key] = value.toJson();
    });
    await _prefs?.setString(_patternsKey, json.encode(patternsJson));
  }

  /// 清除所有数据
  Future<void> clearAllData() async {
    _interactionHistory.clear();
    _patterns.clear();
    await _prefs?.remove(_interactionsKey);
    await _prefs?.remove(_patternsKey);
  }

  /// 获取统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'totalInteractions': _interactionHistory.length,
      'identifiedPatterns': _patterns.length,
      'isRecording': _isRecording,
      'eventTypes': _interactionHistory.map((e) => e.type).toSet().toList(),
    };
  }
}

/// 交互事件数据类
class InteractionEvent {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  InteractionEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }

  factory InteractionEvent.fromJson(Map<String, dynamic> json) {
    return InteractionEvent(
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>,
    );
  }
}

/// 交互模式数据类
class InteractionPattern {
  final String eventType;
  final double frequency;
  final DateTime lastOccurrence;
  final double avgInterval;
  final Map<int, double> preferredHour;
  final Map<String, double> typicalDuration;
  final double confidence;

  InteractionPattern({
    required this.eventType,
    required this.frequency,
    required this.lastOccurrence,
    required this.avgInterval,
    required this.preferredHour,
    required this.typicalDuration,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType,
      'frequency': frequency,
      'lastOccurrence': lastOccurrence.toIso8601String(),
      'avgInterval': avgInterval,
      'preferredHour': preferredHour,
      'typicalDuration': typicalDuration,
      'confidence': confidence,
    };
  }

  factory InteractionPattern.fromJson(Map<String, dynamic> json) {
    return InteractionPattern(
      eventType: json['eventType'] as String,
      frequency: json['frequency'] as double,
      lastOccurrence: DateTime.parse(json['lastOccurrence'] as String),
      avgInterval: json['avgInterval'] as double,
      preferredHour: Map<int, double>.from(
        (json['preferredHour'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(int.parse(key), value as double)),
      ),
      typicalDuration: Map<String, double>.from(
        json['typicalDuration'] as Map<String, dynamic>,
      ),
      confidence: json['confidence'] as double,
    );
  }
}

/// 使用洞察数据类
class UsageInsight {
  final InsightType type;
  final String title;
  final String description;
  final bool actionable;
  final String suggestion;

  UsageInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.actionable,
    required this.suggestion,
  });

  @override
  String toString() => '$title: $description';
}

/// 洞察类型枚举
enum InsightType { writingHabit, engagement, featurePreference, timePattern }

/// 优化建议数据类
class OptimizationSuggestion {
  final SuggestionCategory category;
  final String title;
  final String description;
  final SuggestionPriority priority;
  final double estimatedImpact;

  OptimizationSuggestion({
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedImpact,
  });

  @override
  String toString() =>
      '[$priority] $title: $description (影响: ${(estimatedImpact * 100).toStringAsFixed(0)}%)';
}

/// 建议分类枚举
enum SuggestionCategory {
  efficiency,
  personalization,
  performance,
  accessibility
}

/// 建议优先级枚举
enum SuggestionPriority { high, medium, low }

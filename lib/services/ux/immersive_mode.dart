import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// ImmersiveMode - 沉浸式专注写作模式
/// 提供无干扰的写作环境，支持环境适配和心流状态监测
class ImmersiveMode extends ChangeNotifier {
  static ImmersiveMode? _instance;
  bool _isActive = false;
  bool _isFlowState = false;
  Timer? _flowStateTimer;
  Timer? _sessionTimer;
  int _sessionDuration = 0;
  int _wordCount = 0;
  int _focusScore = 0;
  List<double> _typingSpeedHistory = [];
  DateTime? _lastTypingTime;

  // 环境设置
  ImmersiveEnvironment _environment = ImmersiveEnvironment();
  FlowStateSettings _flowSettings = FlowStateSettings();

  // 私有构造函数
  ImmersiveMode._();

  /// 获取单例实例
  static ImmersiveMode get instance {
    _instance ??= ImmersiveMode._();
    return _instance!;
  }

  /// 是否处于沉浸模式
  bool get isActive => _isActive;

  /// 是否处于心流状态
  bool get isFlowState => _isFlowState;

  /// 当前会话时长（分钟）
  int get sessionDuration => _sessionDuration;

  /// 当前字数统计
  int get wordCount => _wordCount;

  /// 专注度评分 (0-100)
  int get focusScore => _focusScore;

  /// 环境设置
  ImmersiveEnvironment get environment => _environment;

  /// 心流设置
  FlowStateSettings get flowSettings => _flowSettings;

  /// 启动沉浸模式
  Future<void> activate() async {
    if (_isActive) return;

    _isActive = true;
    _sessionDuration = 0;
    _wordCount = 0;
    _focusScore = 0;
    _typingSpeedHistory.clear();

    // 启动会话计时器
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _sessionDuration++;
      _updateFocusScore();
      notifyListeners();
    });

    // 启动心流状态监测
    _startFlowStateMonitoring();

    notifyListeners();
  }

  /// 退出沉浸模式
  Future<void> deactivate() async {
    if (!_isActive) return;

    _isActive = false;
    _isFlowState = false;
    _sessionTimer?.cancel();
    _flowStateTimer?.cancel();

    final sessionData = ImmersiveSessionSummary(
      duration: _sessionDuration,
      wordCount: _wordCount,
      focusScore: _focusScore,
      environment: _environment,
      timestamp: DateTime.now(),
    );

    notifyListeners();

    return Future.value(sessionData);
  }

  /// 记录打字事件
  void recordTyping() {
    if (!_isActive) return;

    final now = DateTime.now();
    if (_lastTypingTime != null) {
      final interval = now.difference(_lastTypingTime!).inMilliseconds;
      _typingSpeedHistory.add(1000.0 / interval);

      // 保持历史记录在合理范围内
      if (_typingSpeedHistory.length > 100) {
        _typingSpeedHistory.removeAt(0);
      }
    }

    _lastTypingTime = now;
    _wordCount++;
  }

  /// 启动心流状态监测
  void _startFlowStateMonitoring() {
    _flowStateTimer = Timer.periodic(
      Duration(seconds: _flowSettings.checkInterval),
      (_) => _checkFlowState(),
    );
  }

  /// 检查心流状态
  void _checkFlowState() {
    if (_typingSpeedHistory.isEmpty) {
      _isFlowState = false;
      notifyListeners();
      return;
    }

    // 计算平均打字速度和稳定性
    final avgSpeed = _typingSpeedHistory.reduce((a, b) => a + b) /
        _typingSpeedHistory.length;
    final variance = _typingSpeedHistory
            .map((s) => pow(s - avgSpeed, 2))
            .reduce((a, b) => a + b) /
        _typingSpeedHistory.length;
    final stability = 1.0 / (1.0 + variance);

    // 心流状态判断标准
    final speedThreshold = _flowSettings.minTypingSpeed;
    final stabilityThreshold = _flowSettings.minStability;

    final wasInFlow = _isFlowState;
    _isFlowState = avgSpeed > speedThreshold && stability > stabilityThreshold;

    // 如果进入心流状态，记录事件
    if (_isFlowState && !wasInFlow) {
      _onFlowStateEntered();
    } else if (!_isFlowState && wasInFlow) {
      _onFlowStateExited();
    }

    notifyListeners();
  }

  /// 进入心流状态时的处理
  void _onFlowStateEntered() {
    debugPrint('🎯 进入心流状态！');
    // 可以在这里触发环境优化
    if (_environment.autoOptimize) {
      _optimizeEnvironmentForFlow();
    }
  }

  /// 退出心流状态时的处理
  void _onFlowStateExited() {
    debugPrint('💫 退出心流状态');
  }

  /// 优化环境以支持心流状态
  void _optimizeEnvironmentForFlow() {
    // 降低通知干扰
    _environment.notificationLevel = NotificationLevel.minimal;
    // 调整光线
    _environment.brightness = Brightness.dark;
  }

  /// 更新专注度评分
  void _updateFocusScore() {
    if (_typingSpeedHistory.length < 10) {
      _focusScore = 0;
      return;
    }

    final recentSpeed =
        _typingSpeedHistory.reversed.take(10).reduce((a, b) => a + b) / 10;
    final speedFactor = (recentSpeed / 10.0).clamp(0.0, 1.0);

    final durationFactor = (_sessionDuration / 60.0).clamp(0.0, 1.0);

    _focusScore = ((speedFactor * 0.7 + durationFactor * 0.3) * 100).round();
  }

  /// 更新环境设置
  void updateEnvironment(ImmersiveEnvironment environment) {
    _environment = environment;
    notifyListeners();
  }

  /// 更新心流设置
  void updateFlowSettings(FlowStateSettings settings) {
    _flowSettings = settings;
    // 重新启动监测以应用新设置
    if (_isActive) {
      _flowStateTimer?.cancel();
      _startFlowStateMonitoring();
    }
    notifyListeners();
  }

  /// 获取当前状态摘要
  Map<String, dynamic> getStatusSummary() {
    return {
      'isActive': _isActive,
      'isFlowState': _isFlowState,
      'sessionDuration': _sessionDuration,
      'wordCount': _wordCount,
      'focusScore': _focusScore,
      'typingSpeed': _typingSpeedHistory.isNotEmpty
          ? _typingSpeedHistory.reduce((a, b) => a + b) /
              _typingSpeedHistory.length
          : 0.0,
    };
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _flowStateTimer?.cancel();
    super.dispose();
  }
}

/// 沉浸环境设置
class ImmersiveEnvironment {
  NotificationLevel notificationLevel = NotificationLevel.standard;
  Brightness brightness = Brightness.light;
  SoundProfile soundProfile = SoundProfile.quiet;
  bool autoOptimize = true;
  bool hideUI = true;
  bool reduceMotion = false;

  ImmersiveEnvironment({
    this.notificationLevel = NotificationLevel.standard,
    this.brightness = Brightness.light,
    this.soundProfile = SoundProfile.quiet,
    this.autoOptimize = true,
    this.hideUI = true,
    this.reduceMotion = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationLevel': notificationLevel.toString(),
      'brightness': brightness.toString(),
      'soundProfile': soundProfile.toString(),
      'autoOptimize': autoOptimize,
      'hideUI': hideUI,
      'reduceMotion': reduceMotion,
    };
  }

  factory ImmersiveEnvironment.fromJson(Map<String, dynamic> json) {
    return ImmersiveEnvironment(
      notificationLevel: NotificationLevel.values.firstWhere(
        (e) => e.toString() == json['notificationLevel'],
        orElse: () => NotificationLevel.standard,
      ),
      brightness: Brightness.values.firstWhere(
        (e) => e.toString() == json['brightness'],
        orElse: () => Brightness.light,
      ),
      soundProfile: SoundProfile.values.firstWhere(
        (e) => e.toString() == json['soundProfile'],
        orElse: () => SoundProfile.quiet,
      ),
      autoOptimize: json['autoOptimize'] as bool? ?? true,
      hideUI: json['hideUI'] as bool? ?? true,
      reduceMotion: json['reduceMotion'] as bool? ?? false,
    );
  }
}

/// 心流状态设置
class FlowStateSettings {
  int checkInterval = 30; // 秒
  double minTypingSpeed = 5.0; // 字符/秒
  double minStability = 0.7; // 稳定性阈值
  bool enableNotifications = true;
  int minFlowDuration = 5; // 最小心流持续时间（分钟）

  FlowStateSettings({
    this.checkInterval = 30,
    this.minTypingSpeed = 5.0,
    this.minStability = 0.7,
    this.enableNotifications = true,
    this.minFlowDuration = 5,
  });

  Map<String, dynamic> toJson() {
    return {
      'checkInterval': checkInterval,
      'minTypingSpeed': minTypingSpeed,
      'minStability': minStability,
      'enableNotifications': enableNotifications,
      'minFlowDuration': minFlowDuration,
    };
  }

  factory FlowStateSettings.fromJson(Map<String, dynamic> json) {
    return FlowStateSettings(
      checkInterval: json['checkInterval'] as int? ?? 30,
      minTypingSpeed: json['minTypingSpeed'] as double? ?? 5.0,
      minStability: json['minStability'] as double? ?? 0.7,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      minFlowDuration: json['minFlowDuration'] as int? ?? 5,
    );
  }
}

/// 沉浸会话摘要
class ImmersiveSessionSummary {
  final int duration;
  final int wordCount;
  final int focusScore;
  final ImmersiveEnvironment environment;
  final DateTime timestamp;

  ImmersiveSessionSummary({
    required this.duration,
    required this.wordCount,
    required this.focusScore,
    required this.environment,
    required this.timestamp,
  });

  double get wordsPerMinute => duration > 0 ? wordCount / duration : 0;

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'wordCount': wordCount,
      'focusScore': focusScore,
      'environment': environment.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return '沉浸会话: $duration分钟, $wordCount字, 专注度$focusScore%';
  }
}

/// 通知级别枚举
enum NotificationLevel { all, standard, minimal, none }

/// 声音配置枚举
enum SoundProfile { silent, quiet, normal }

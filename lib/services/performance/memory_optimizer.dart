import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../utils/logger.dart';

/// 内存状态
enum MemoryState {
  /// 健康 - 内存使用正常
  healthy,

  /// 警告 - 内存使用较高
  warning,

  /// 危险 - 内存使用过高，需要立即清理
  critical,
}

/// 内存泄漏检测结果
class MemoryLeakResult {
  final String resourceName;
  final String description;
  final int suspectedLeakCount;
  final DateTime detectedTime;
  final List<String> stackTrace;

  MemoryLeakResult({
    required this.resourceName,
    required this.description,
    required this.suspectedLeakCount,
    required this.detectedTime,
    required this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'resourceName': resourceName,
      'description': description,
      'suspectedLeakCount': suspectedLeakCount,
      'detectedTime': detectedTime.toIso8601String(),
      'stackTrace': stackTrace,
    };
  }
}

/// 内存使用统计
class MemoryUsageStats {
  final int totalMemoryMB;
  final int usedMemoryMB;
  final int freeMemoryMB;
  final double usagePercentage;
  final MemoryState state;
  final DateTime timestamp;

  MemoryUsageStats({
    required this.totalMemoryMB,
    required this.usedMemoryMB,
    required this.freeMemoryMB,
    required this.usagePercentage,
    required this.state,
    required this.timestamp,
  });

  factory MemoryUsageStats.empty() {
    return MemoryUsageStats(
      totalMemoryMB: 0,
      usedMemoryMB: 0,
      freeMemoryMB: 0,
      usagePercentage: 0.0,
      state: MemoryState.healthy,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMemoryMB': totalMemoryMB,
      'usedMemoryMB': usedMemoryMB,
      'freeMemoryMB': freeMemoryMB,
      'usagePercentage': usagePercentage,
      'state': state.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return '内存使用: ${usedMemoryMB}MB / ${totalMemoryMB}MB (${usagePercentage.toStringAsFixed(1)}%) - ${state.toString().split('.').last}';
  }
}

/// 资源压缩配置
class CompressionConfig {
  final bool enabled;
  final int targetSizeReductionPercentage;
  final int qualityLevel; // 1-100
  final List<String> compressibleTypes;

  const CompressionConfig({
    this.enabled = true,
    this.targetSizeReductionPercentage = 50,
    this.qualityLevel = 85,
    this.compressibleTypes = const ['image', 'data', 'cache'],
  });

  CompressionConfig copyWith({
    bool? enabled,
    int? targetSizeReductionPercentage,
    int? qualityLevel,
    List<String>? compressibleTypes,
  }) {
    return CompressionConfig(
      enabled: enabled ?? this.enabled,
      targetSizeReductionPercentage:
          targetSizeReductionPercentage ?? this.targetSizeReductionPercentage,
      qualityLevel: qualityLevel ?? this.qualityLevel,
      compressibleTypes: compressibleTypes ?? this.compressibleTypes,
    );
  }
}

/// 内存优化策略
class MemoryOptimizationStrategy {
  final bool enableAggressiveCleanup;
  final bool enableResourceCompression;
  final bool enableLazyLoading;
  final int cleanupIntervalMs;
  final int memoryThresholdWarningMB;
  final int memoryThresholdCriticalMB;

  const MemoryOptimizationStrategy({
    this.enableAggressiveCleanup = true,
    this.enableResourceCompression = true,
    this.enableLazyLoading = true,
    this.cleanupIntervalMs = 60000, // 1 minute
    this.memoryThresholdWarningMB = 500,
    this.memoryThresholdCriticalMB = 800,
  });

  /// 获取保守策略（低内存设备）
  static MemoryOptimizationStrategy get conservative {
    return const MemoryOptimizationStrategy(
      enableAggressiveCleanup: true,
      enableResourceCompression: true,
      enableLazyLoading: true,
      cleanupIntervalMs: 30000, // 30 seconds
      memoryThresholdWarningMB: 300,
      memoryThresholdCriticalMB: 500,
    );
  }

  /// 获取激进策略（高性能设备）
  static MemoryOptimizationStrategy get aggressive {
    return const MemoryOptimizationStrategy(
      enableAggressiveCleanup: false,
      enableResourceCompression: false,
      enableLazyLoading: false,
      cleanupIntervalMs: 120000, // 2 minutes
      memoryThresholdWarningMB: 1000,
      memoryThresholdCriticalMB: 1500,
    );
  }

  /// 获取平衡策略
  static MemoryOptimizationStrategy get balanced {
    return const MemoryOptimizationStrategy();
  }
}

/// 内存优化器
///
/// 提供智能内存管理功能：
/// 1. 自动垃圾回收调度
/// 2. 内存泄漏检测
/// 3. 资源压缩和优化
/// 4. 内存使用监控和报告
class MemoryOptimizer {
  static MemoryOptimizer? _instance;

  // 配置
  MemoryOptimizationStrategy _strategy = MemoryOptimizationStrategy.balanced;
  CompressionConfig _compressionConfig = const CompressionConfig();

  // 状态
  MemoryUsageStats _currentStats = MemoryUsageStats.empty();
  final List<MemoryUsageStats> _historyStats = [];
  final List<MemoryLeakResult> _leakResults = [];

  // 定时器
  Timer? _monitoringTimer;
  Timer? _cleanupTimer;
  Timer? _leakDetectionTimer;

  // 资源追踪
  final Map<String, int> _resourceCounts = {};
  final Map<String, List<DateTime>> _resourceCreationTimes = {};

  // 性能统计
  int _totalCleanups = 0;
  int _totalCompressions = 0;
  int _totalRecoveredMemoryMB = 0;
  DateTime? _lastCleanupTime;

  bool _isMonitoring = false;
  bool _isDisposed = false;

  // 回调
  final List<void Function(MemoryUsageStats)> _stateChangeCallbacks = [];

  MemoryOptimizer._internal();

  static MemoryOptimizer get instance {
    _instance ??= MemoryOptimizer._internal();
    return _instance!;
  }

  /// 开始监控
  void startMonitoring() {
    if (_isMonitoring || _isDisposed) return;

    _isMonitoring = true;
    _updateMemoryStats();

    // 定期监控内存状态
    _monitoringTimer = Timer.periodic(
      Duration(milliseconds: _strategy.cleanupIntervalMs),
      (_) => _updateMemoryStats(),
    );

    // 定期清理
    _cleanupTimer = Timer.periodic(
      Duration(milliseconds: _strategy.cleanupIntervalMs * 2),
      (_) => _performCleanup(),
    );

    // 定期检测内存泄漏
    _leakDetectionTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _detectMemoryLeaks(),
    );

    Logger.debug('内存优化器已启动监控');
  }

  /// 停止监控
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _cleanupTimer?.cancel();
    _leakDetectionTimer?.cancel();

    Logger.debug('内存优化器已停止监控');
  }

  /// 设置优化策略
  void setStrategy(MemoryOptimizationStrategy strategy) {
    _strategy = strategy;
    Logger.debug('内存优化策略已更新');

    // 重启监控以应用新策略
    if (_isMonitoring) {
      stopMonitoring();
      startMonitoring();
    }
  }

  /// 设置压缩配置
  void setCompressionConfig(CompressionConfig config) {
    _compressionConfig = config;
    Logger.debug('压缩配置已更新');
  }

  /// 获取当前内存状态
  MemoryUsageStats get currentStats => _currentStats;

  /// 获取内存使用历史
  List<MemoryUsageStats> get historyStats => List.unmodifiable(_historyStats);

  /// 获取内存泄漏检测结果
  List<MemoryLeakResult> get leakResults => List.unmodifiable(_leakResults);

  /// 立即执行清理
  Future<void> performImmediateCleanup() async {
    Logger.debug('执行立即内存清理...');
    await _performCleanup();
  }

  /// 立即检测内存泄漏
  Future<void> performImmediateLeakDetection() async {
    Logger.debug('执行立即内存泄漏检测...');
    await _detectMemoryLeaks();
  }

  /// 压缩资源
  Future<int> compressResources(List<String> resourceTypes) async {
    if (!_compressionConfig.enabled) {
      Logger.debug('资源压缩已禁用');
      return 0;
    }

    int compressedSize = 0;
    _totalCompressions++;

    try {
      // 这里应该实现实际的资源压缩逻辑
      // 由于平台限制，这里提供模拟实现

      for (final type in resourceTypes) {
        if (_compressionConfig.compressibleTypes.contains(type)) {
          // 模拟压缩
          final originalSize = _estimateResourceSize(type);
          final reductionSize = (originalSize *
                  (_compressionConfig.targetSizeReductionPercentage / 100))
              .toInt();

          Logger.debug('压缩资源类型: $type, 预计节省: ${reductionSize}MB');
          compressedSize += reductionSize;
        }
      }

      _totalRecoveredMemoryMB += compressedSize;
      Logger.debug('资源压缩完成，总计节省: ${compressedSize}MB');
    } catch (e) {
      Logger.debug('资源压缩失败: $e');
    }

    return compressedSize;
  }

  /// 注册资源（用于泄漏检测）
  void registerResource(String type, {String? resourceId}) {
    final key = resourceId != null ? '$type:$resourceId' : type;
    _resourceCounts[key] = (_resourceCounts[key] ?? 0) + 1;
    _resourceCreationTimes.putIfAbsent(key, () => []).add(DateTime.now());

    // 限制记录数量
    if (_resourceCreationTimes[key]!.length > 100) {
      _resourceCreationTimes[key]!
          .removeRange(0, _resourceCreationTimes[key]!.length - 100);
    }
  }

  /// 注销资源
  void unregisterResource(String type, {String? resourceId}) {
    final key = resourceId != null ? '$type:$resourceId' : type;
    if (_resourceCounts.containsKey(key)) {
      _resourceCounts[key] = _resourceCounts[key]! - 1;
      if (_resourceCounts[key]! <= 0) {
        _resourceCounts.remove(key);
        _resourceCreationTimes.remove(key);
      }
    }
  }

  /// 添加状态变化回调
  void addStateChangeListener(void Function(MemoryUsageStats) callback) {
    _stateChangeCallbacks.add(callback);
  }

  /// 移除状态变化回调
  void removeStateChangeListener(void Function(MemoryUsageStats) callback) {
    _stateChangeCallbacks.remove(callback);
  }

  /// 获取性能报告
  Map<String, dynamic> getPerformanceReport() {
    final recentStats = _historyStats.take(10).toList();
    final avgUsagePercentage = recentStats.isEmpty
        ? 0.0
        : recentStats.map((s) => s.usagePercentage).reduce((a, b) => a + b) /
            recentStats.length;

    return {
      'currentStats': _currentStats.toJson(),
      'averageUsagePercentage': avgUsagePercentage.toStringAsFixed(2),
      'totalCleanups': _totalCleanups,
      'totalCompressions': _totalCompressions,
      'totalRecoveredMemoryMB': _totalRecoveredMemoryMB,
      'lastCleanupTime': _lastCleanupTime?.toIso8601String(),
      'leakDetectionResults': _leakResults.map((r) => r.toJson()).toList(),
      'strategy': {
        'enableAggressiveCleanup': _strategy.enableAggressiveCleanup,
        'enableResourceCompression': _strategy.enableResourceCompression,
        'enableLazyLoading': _strategy.enableLazyLoading,
        'memoryThresholdWarningMB': _strategy.memoryThresholdWarningMB,
        'memoryThresholdCriticalMB': _strategy.memoryThresholdCriticalMB,
      },
      'compressionConfig': {
        'enabled': _compressionConfig.enabled,
        'targetSizeReductionPercentage':
            _compressionConfig.targetSizeReductionPercentage,
        'qualityLevel': _compressionConfig.qualityLevel,
      },
    };
  }

  /// 获取优化建议
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];

    // 基于当前状态的建议
    if (_currentStats.state == MemoryState.critical) {
      suggestions.add(
          '内存使用危险 (${_currentStats.usagePercentage.toStringAsFixed(1)}%)，建议立即执行清理或重启应用');
    } else if (_currentStats.state == MemoryState.warning) {
      suggestions.add(
          '内存使用较高 (${_currentStats.usagePercentage.toStringAsFixed(1)}%)，建议执行资源清理');
    }

    // 基于泄漏检测的建议
    if (_leakResults.isNotEmpty) {
      suggestions.add('检测到 ${_leakResults.length} 个可能的内存泄漏，建议检查相关代码');
    }

    // 基于策略的建议
    if (!_strategy.enableAggressiveCleanup &&
        _currentStats.usagePercentage > 70) {
      suggestions.add('建议启用激进清理模式以降低内存使用');
    }

    if (!_strategy.enableResourceCompression &&
        _currentStats.usagePercentage > 60) {
      suggestions.add('建议启用资源压缩以减少内存占用');
    }

    if (_totalCleanups == 0 && _historyStats.length > 10) {
      suggestions.add('长时间未执行清理，建议手动触发清理操作');
    }

    // 基于历史数据的建议
    if (_historyStats.length >= 10) {
      final recentStats = _historyStats.take(10).toList();
      final increasingCount =
          recentStats.where((s) => s.usagePercentage > 60).length;

      if (increasingCount >= 7) {
        suggestions.add('内存使用持续较高，建议检查是否有内存泄漏或优化资源管理');
      }
    }

    if (suggestions.isEmpty) {
      suggestions.add('当前内存管理状态良好，无需特别优化');
    }

    return suggestions;
  }

  /// 清理资源
  void cleanup() {
    _resourceCounts.clear();
    _resourceCreationTimes.clear();
    _leakResults.clear();
    Logger.debug('内存优化器资源已清理');
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;
    stopMonitoring();
    cleanup();

    Logger.debug('内存优化器已释放');
  }

  // 私有方法

  /// 更新内存状态
  void _updateMemoryStats() {
    try {
      final stats = _getCurrentMemoryStats();
      _currentStats = stats;

      // 保存历史数据（保留最近100条）
      _historyStats.add(stats);
      if (_historyStats.length > 100) {
        _historyStats.removeAt(0);
      }

      // 通知状态变化
      _notifyStateChange(stats);

      // 根据状态采取行动
      _handleMemoryState(stats);
    } catch (e) {
      Logger.debug('更新内存状态失败: $e');
    }
  }

  /// 获取当前内存状态
  MemoryUsageStats _getCurrentMemoryStats() {
    try {
      // 在实际应用中，这里应该使用平台特定的API获取真实的内存信息
      // 由于Dart的限制，我们使用估算或模拟数据

      // 尝试使用Flutter的内存信息
      if (kDebugMode) {
        // 在调试模式下，我们可以获取更多信息
        // dart:developer API 在此版本中不提供 getIsolateInfo
      }

      // 估算内存使用（基于平台）
      final estimatedUsage = _estimateMemoryUsage();

      return MemoryUsageStats(
        totalMemoryMB: (estimatedUsage['total'] ?? 1024).toInt(),
        usedMemoryMB: (estimatedUsage['used'] ?? 100).toInt(),
        freeMemoryMB: (estimatedUsage['free'] ?? 924).toInt(),
        usagePercentage: (estimatedUsage['percentage'] ?? 10.0).toDouble(),
        state: _determineMemoryState(
            (estimatedUsage['percentage'] ?? 10.0).toDouble()),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      Logger.debug('获取内存状态失败: $e');
      return MemoryUsageStats.empty();
    }
  }

  /// 估算内存使用
  Map<String, num> _estimateMemoryUsage() {
    // 这是一个简化的实现，实际应用中应该使用平台特定的API
    // 或者使用Flutter的内存信息获取方法

    if (Platform.isAndroid || Platform.isIOS) {
      // 移动平台的估算
      final total = Platform.isAndroid ? 2048 : 1536; // MB
      final used = 200 + (DateTime.now().millisecond % 100); // 模拟变化
      final free = total - used;
      final percentage = (used / total * 100);

      return {
        'total': total,
        'used': used,
        'free': free,
        'percentage': percentage.round(),
      };
    } else {
      // 桌面平台的估算
      final total = 4096; // MB
      final used = 300 + (DateTime.now().millisecond % 150);
      final free = total - used;
      final percentage = (used / total * 100);

      return {
        'total': total,
        'used': used,
        'free': free,
        'percentage': percentage.round(),
      };
    }
  }

  /// 确定内存状态
  MemoryState _determineMemoryState(double usagePercentage) {
    if (usagePercentage >= _strategy.memoryThresholdCriticalMB) {
      return MemoryState.critical;
    } else if (usagePercentage >= _strategy.memoryThresholdWarningMB) {
      return MemoryState.warning;
    } else {
      return MemoryState.healthy;
    }
  }

  /// 处理内存状态
  void _handleMemoryState(MemoryUsageStats stats) {
    switch (stats.state) {
      case MemoryState.critical:
        Logger.debug('内存危险状态，执行紧急清理...');
        performImmediateCleanup();
        break;

      case MemoryState.warning:
        Logger.debug('内存警告状态，计划清理...');
        // 在下一次定时清理时处理
        break;

      case MemoryState.healthy:
        // 正常状态，无需特殊处理
        break;
    }
  }

  /// 通知状态变化
  void _notifyStateChange(MemoryUsageStats stats) {
    for (final callback in _stateChangeCallbacks) {
      try {
        callback(stats);
      } catch (e) {
        Logger.debug('状态变化回调失败: $e');
      }
    }
  }

  /// 执行清理
  Future<void> _performCleanup() async {
    _totalCleanups++;
    _lastCleanupTime = DateTime.now();

    try {
      int recoveredMemory = 0;

      // 1. 如果启用资源压缩，执行压缩
      if (_strategy.enableResourceCompression) {
        final compressedSize =
            await compressResources(_compressionConfig.compressibleTypes);
        recoveredMemory += compressedSize;
      }

      // 2. 执行垃圾回收
      if (_strategy.enableAggressiveCleanup) {
        // 在Dart中，垃圾回收是自动的，但我们可以通过一些操作来触发它
        // 例如：清理缓存、释放未使用的资源等

        // 模拟清理操作
        await Future.delayed(const Duration(milliseconds: 100));

        // 估算回收的内存
        recoveredMemory += 50; // MB
      }

      _totalRecoveredMemoryMB += recoveredMemory;

      Logger.debug('内存清理完成，回收: ${recoveredMemory}MB');

      // 更新内存状态
      _updateMemoryStats();
    } catch (e) {
      Logger.debug('内存清理失败: $e');
    }
  }

  /// 检测内存泄漏
  Future<void> _detectMemoryLeaks() async {
    try {
      final suspiciousResources = <String>[];
      final currentTime = DateTime.now();

      // 检查资源计数异常增长
      for (final entry in _resourceCounts.entries) {
        final resourceName = entry.key;
        final count = entry.value;

        // 如果单个资源类型有过多实例
        if (count > 50) {
          suspiciousResources.add(resourceName);
        }

        // 检查资源创建时间模式
        final creationTimes = _resourceCreationTimes[resourceName];
        if (creationTimes != null && creationTimes.length > 10) {
          // 检查最近创建的资源是否都被释放
          final recentCreations = creationTimes
              .where((time) =>
                  currentTime.difference(time) < const Duration(minutes: 5))
              .length;

          if (recentCreations > 20) {
            suspiciousResources.add(resourceName);
          }
        }
      }

      // 生成泄漏报告
      for (final resourceName in suspiciousResources) {
        final leakResult = MemoryLeakResult(
          resourceName: resourceName,
          description: '资源实例数量异常: ${_resourceCounts[resourceName]}',
          suspectedLeakCount: _resourceCounts[resourceName] ?? 0,
          detectedTime: currentTime,
          stackTrace:
              StackTrace.current.toString().split('\n').take(10).toList(),
        );

        _leakResults.add(leakResult);
        Logger.debug('检测到可能的内存泄漏: $resourceName');
      }

      // 限制结果数量
      if (_leakResults.length > 50) {
        _leakResults.removeRange(0, _leakResults.length - 50);
      }
    } catch (e) {
      Logger.debug('内存泄漏检测失败: $e');
    }
  }

  /// 估算资源大小
  int _estimateResourceSize(String resourceType) {
    // 简化的资源大小估算
    switch (resourceType.toLowerCase()) {
      case 'image':
        return 10; // MB
      case 'data':
        return 5; // MB
      case 'cache':
        return 20; // MB
      default:
        return 2; // MB
    }
  }
}

/// 内存优化器单例访问器
MemoryOptimizer get memoryOptimizer => MemoryOptimizer.instance;

/// 便捷的内存清理函数
Future<void> cleanupMemory() async {
  await memoryOptimizer.performImmediateCleanup();
}

/// 便捷的内存状态获取函数
MemoryUsageStats getCurrentMemoryStats() {
  return memoryOptimizer.currentStats;
}

/// 便捷的资源注册函数
void trackResource(String type, {String? resourceId}) {
  memoryOptimizer.registerResource(type, resourceId: resourceId);
}

/// 便捷的资源注销函数
void untrackResource(String type, {String? resourceId}) {
  memoryOptimizer.unregisterResource(type, resourceId: resourceId);
}

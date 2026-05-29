import '../utils/logger.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'lazy_storage_service.dart';
import 'secure_data_service.dart';
import 'database_service.dart';
import 'ai/ai_service.dart';
import '../config/app_constants.dart';
import 'performance/preload_manager.dart';
import 'performance/memory_optimizer.dart';
import 'performance/performance_metrics.dart';

// 导入性能相关的枚举类型
export 'performance/memory_optimizer.dart'
    show MemoryState, MemoryOptimizationStrategy;

/// 启动阶段
enum StartupPhase {
  /// 基础UI准备 - 必须 <500ms
  basicUI,

  /// 核心服务初始化 - 必须 <1.2s
  coreServices,

  /// 辅助功能初始化 - 必须 <2.0s
  auxiliaryServices,

  /// 完成状态
  completed,
}

/// 初始化状态
class InitializationState {
  final StartupPhase currentPhase;
  final double progress;
  final String? message;
  final bool isLoading;
  final DateTime startTime;

  InitializationState({
    required this.currentPhase,
    this.progress = 0.0,
    this.message,
    this.isLoading = false,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  Duration get elapsed => DateTime.now().difference(startTime);

  InitializationState copyWith({
    StartupPhase? currentPhase,
    double? progress,
    String? message,
    bool? isLoading,
  }) {
    return InitializationState(
      currentPhase: currentPhase ?? this.currentPhase,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
      startTime: startTime,
    );
  }
}

/// 初始化阶段配置
class PhaseConfig {
  final String name;
  final Duration targetDuration;
  final List<Future<void> Function()> tasks;

  const PhaseConfig({
    required this.name,
    required this.targetDuration,
    required this.tasks,
  });
}

/// 渐进式初始化器
///
/// 实现分阶段初始化策略：
/// - 阶段1：基础UI准备 (<500ms)
/// - 阶段2：核心服务初始化 (<1.2s总计)
/// - 阶段3：辅助功能初始化 (<2.0s总计)
class ProgressiveInitializer {
  static ProgressiveInitializer? _instance;
  // 使用 AppConstants 中的启动性能阈值
  static const Duration _phase1Target =
      Duration(milliseconds: AppConstants.startupBasicUIThresholdMs);
  static const Duration _phase2Target =
      Duration(milliseconds: AppConstants.startupCoreServicesThresholdMs);
  static const Duration _phase3Target =
      Duration(milliseconds: AppConstants.startupCompleteThresholdMs);

  final _stateController = StreamController<InitializationState>.broadcast();
  InitializationState _state = InitializationState(
    currentPhase: StartupPhase.basicUI,
    progress: 0.0,
    message: '准备启动...',
    isLoading: true,
  );

  bool _isInitialized = false;
  bool _isInitializing = false;

  // 性能监控
  DateTime? _performanceStartTime;
  Map<String, Duration> _phaseDurations = {};
  final Map<String, Stopwatch> _phaseTimers = {};

  ProgressiveInitializer._internal() {
    // 初始化性能监控
    _setupPerformanceMonitoring();
  }

  static ProgressiveInitializer get instance {
    _instance ??= ProgressiveInitializer._internal();
    return _instance!;
  }

  /// 获取初始化状态流
  Stream<InitializationState> get stateStream => _stateController.stream;

  /// 获取当前状态
  InitializationState get currentState => _state;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否正在初始化
  bool get isInitializing => _isInitializing;

  /// 开始渐进式初始化
  Future<void> initialize() async {
    if (_isInitializing) {
      Logger.debug('初始化已在进行中');
      return;
    }

    if (_isInitialized) {
      Logger.debug('已经初始化完成');
      return;
    }

    _isInitializing = true;
    _performanceStartTime = DateTime.now();
    final startTime = DateTime.now();

    try {
      // 启动内存监控
      memoryOptimizer.startMonitoring();

      // 阶段1：基础UI准备
      final phase1Start = DateTime.now();
      await _initializePhase1();
      _phaseDurations['phase1'] = DateTime.now().difference(phase1Start);

      // 阶段2：核心服务初始化
      final phase2Start = DateTime.now();
      await _initializePhase2();
      _phaseDurations['phase2'] = DateTime.now().difference(phase2Start);

      // 阶段3：辅助功能初始化
      final phase3Start = DateTime.now();
      await _initializePhase3();
      _phaseDurations['phase3'] = DateTime.now().difference(phase3Start);

      // 启动预加载管理器
      _startPreloadManager();

      _isInitialized = true;
      _updateState(
        currentPhase: StartupPhase.completed,
        progress: 1.0,
        message: '初始化完成',
        isLoading: false,
      );

      final totalTime = DateTime.now().difference(startTime);
      Logger.debug('初始化完成，总耗时: ${totalTime.inMilliseconds}ms');

      if (totalTime.inMilliseconds > 2000) {
        Logger.debug('警告：初始化时间超过目标2秒');
      }

      // 记录性能报告
      _reportPerformanceMetrics(totalTime);
    } catch (e, stackTrace) {
      Logger.debug('初始化失败: $e');
      Logger.debug(stackTrace.toString());
      _updateState(
        message: '初始化失败: $e',
        isLoading: false,
      );
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// 阶段1：基础UI准备 (<500ms)
  ///
  /// 此阶段只执行UI渲染所需的最小初始化
  Future<void> _initializePhase1() async {
    final phaseStart = DateTime.now();
    _updateState(
      currentPhase: StartupPhase.basicUI,
      progress: 0.0,
      message: '准备UI...',
    );

    try {
      // 快速执行UI相关的最小初始化
      // 这些操作应该在500ms内完成

      // 性能优化：移除无用的50ms延迟，减少启动时间
      // await Future.delayed(const Duration(milliseconds: 50));

      final phaseTime = DateTime.now().difference(phaseStart);
      Logger.debug('阶段1完成: ${phaseTime.inMilliseconds}ms');

      if (phaseTime.inMilliseconds > 500) {
        Logger.debug('警告：阶段1超过目标时间500ms');
      }
    } catch (e) {
      Logger.debug('阶段1初始化失败: $e');
      rethrow;
    }
  }

  /// 阶段2：核心服务初始化 (<1.2s总计)
  ///
  /// 初始化应用核心功能所需的服务
  Future<void> _initializePhase2() async {
    final phaseStart = DateTime.now();
    _updateState(
      currentPhase: StartupPhase.coreServices,
      progress: 0.3,
      message: '初始化核心服务...',
    );

    try {
      // 初始化加密服务 - 必须在存储服务之前
      await _initializeEncryptionService();
      _updateState(progress: 0.4, message: '加密服务就绪');

      // 初始化Hive存储服务 - 异步加载
      await _initializeStorage();
      _updateState(progress: 0.5, message: '存储服务就绪');

      // 初始化数据库 - 可延迟到首次使用时
      await _initializeDatabaseLazy();
      _updateState(progress: 0.7, message: '数据库就绪');

      final phaseTime = DateTime.now().difference(phaseStart);
      Logger.debug('阶段2完成: ${phaseTime.inMilliseconds}ms');

      if (phaseTime.inMilliseconds > 700) {
        Logger.debug('警告：阶段2超过目标时间700ms');
      }
    } catch (e) {
      Logger.debug('阶段2初始化失败: $e');
      rethrow;
    }
  }

  /// 阶段3：辅助功能初始化 (<2.0s总计)
  ///
  /// 初始化AI服务等辅助功能
  Future<void> _initializePhase3() async {
    final phaseStart = DateTime.now();
    _updateState(
      currentPhase: StartupPhase.auxiliaryServices,
      progress: 0.8,
      message: '初始化辅助服务...',
    );

    try {
      // AI服务初始化 - 可在后台进行
      await _initializeAIService();
      _updateState(progress: 0.9, message: 'AI服务就绪');

      // 其他辅助服务可以在这里添加
      // 性能优化：移除无用的shortDelay延迟，减少启动时间
      // await Future.delayed(AppConstants.shortDelay);

      final phaseTime = DateTime.now().difference(phaseStart);
      Logger.debug('阶段3完成: ${phaseTime.inMilliseconds}ms');

      if (phaseTime.inMilliseconds > 800) {
        Logger.debug('警告：阶段3超过目标时间800ms');
      }
    } catch (e) {
      Logger.debug('阶段3初始化失败: $e');
      // 辅助服务失败不应阻止应用启动
      Logger.debug('辅助服务初始化失败，继续运行');
    }
  }

  /// 初始化加密服务
  Future<void> _initializeEncryptionService() async {
    try {
      // SecureDataService必须在存储服务之前初始化
      await SecureDataService.instance.initialize();

      Logger.debug('加密服务初始化完成');
    } catch (e) {
      Logger.debug('加密服务初始化失败: $e');
      rethrow;
    }
  }

  /// 初始化存储服务
  Future<void> _initializeStorage() async {
    try {
      // Hive初始化
      await Hive.initFlutter();

      // 使用延迟加载的存储服务
      // 先快速初始化基础功能
      await LazyStorageService.instance.quickInitialize();

      // 在后台继续完整初始化
      LazyStorageService.instance.fullInitialize().catchError((e) {
        Logger.debug('存储服务完整初始化失败: $e');
      });

      Logger.debug('存储服务快速初始化完成');
    } catch (e) {
      Logger.debug('存储服务初始化失败: $e');
      rethrow;
    }
  }

  /// 延迟初始化数据库
  ///
  /// 数据库可以在首次使用时再完全初始化
  /// 这里只做基本的准备工作
  Future<void> _initializeDatabaseLazy() async {
    try {
      // 只初始化数据库服务，不打开数据库连接
      // 实际的数据库连接将在首次使用时建立
      await DatabaseService.instance.initialize();

      Logger.debug('数据库服务初始化完成');
    } catch (e) {
      Logger.debug('数据库服务初始化失败: $e');
      rethrow;
    }
  }

  /// 初始化AI服务
  Future<void> _initializeAIService() async {
    try {
      // AI服务初始化
      await AIService.initialize();

      Logger.debug('AI服务初始化完成');
    } catch (e) {
      Logger.debug('AI服务初始化失败: $e');
      // AI服务失败不应阻止应用启动
    }
  }

  /// 快速初始化 - 仅初始化UI所需内容
  ///
  /// 用于快速启动，其他服务将在后台异步初始化
  Future<void> quickInitialize() async {
    if (_isInitializing || _isInitialized) return;

    _isInitializing = true;

    try {
      await _initializePhase1();

      // 在后台继续初始化其他服务
      _initializePhase2().then((_) => _initializePhase3()).catchError((e) {
        Logger.debug('后台初始化失败: $e');
      });
    } finally {
      _isInitializing = false;
    }
  }

  /// 更新状态
  void _updateState({
    StartupPhase? currentPhase,
    double? progress,
    String? message,
    bool? isLoading,
  }) {
    _state = _state.copyWith(
      currentPhase: currentPhase,
      progress: progress,
      message: message,
      isLoading: isLoading,
    );

    _stateController.add(_state);
  }

  /// 释放资源
  void dispose() {
    _stateController.close();
    memoryOptimizer.dispose();
    preloadManager.dispose();
  }

  /// 设置性能监控
  void _setupPerformanceMonitoring() {
    // 监听内存状态变化
    memoryOptimizer.addStateChangeListener((stats) {
      if (stats.state == MemoryState.critical) {
        Logger.debug('内存危险状态，执行紧急清理...');
        _handleMemoryCriticalState();
      }
    });
  }

  /// 启动预加载管理器
  void _startPreloadManager() {
    // 注册常见预加载任务
    _registerPreloadTasks();

    // 开始预测性预加载
    Future.delayed(const Duration(seconds: 2), () {
      preloadManager.preloadPredictedPage();
    });
  }

  /// 注册预加载任务
  void _registerPreloadTasks() {
    // 这里可以根据应用需要注册预加载任务
    // 示例：
    // preloadManager.registerTask(PreloadTask(
    //   id: 'editor_page',
    //   resourceId: 'editor',
    //   resourceType: PreloadResourceType.page,
    //   priority: PreloadPriority.high,
    //   loader: () async {
    //     // 预加载编辑器资源
    //   },
    // ));
  }

  /// 处理内存危险状态
  Future<void> _handleMemoryCriticalState() async {
    Logger.debug('执行内存紧急清理...');
    await memoryOptimizer.performImmediateCleanup();

    // 如果内存仍然危险，考虑采取更激进的措施
    final stats = memoryOptimizer.currentStats;
    if (stats.state == MemoryState.critical) {
      Logger.debug('内存持续危险，启用降级模式...');
      _enableDegradedMode();
    }
  }

  /// 启用降级模式
  void _enableDegradedMode() {
    // 禁用非关键功能
    preloadManager.disable();

    // 设置保守的内存策略
    memoryOptimizer.setStrategy(MemoryOptimizationStrategy.conservative);

    Logger.debug('已启用降级模式');
  }

  /// 报告性能指标
  void _reportPerformanceMetrics(Duration totalTime) {
    Logger.debug('=== 性能报告 ===');
    Logger.debug('总启动时间: ${totalTime.inMilliseconds}ms');

    // 记录到性能指标系统
    performanceMetrics.recordMetric(
      metricName: 'startup_total_time',
      metricType: MetricType.startupTime,
      value: totalTime.inMilliseconds.toDouble(),
      unit: 'ms',
    );

    if (_phaseDurations.isNotEmpty) {
      Logger.debug('各阶段耗时:');
      _phaseDurations.forEach((phase, duration) {
        Logger.debug('  $phase: ${duration.inMilliseconds}ms');

        // 记录各阶段耗时
        performanceMetrics.recordMetric(
          metricName: 'startup_phase_$phase',
          metricType: MetricType.startupTime,
          value: duration.inMilliseconds.toDouble(),
          unit: 'ms',
        );
      });
    }

    // 内存使用报告
    final memoryStats = memoryOptimizer.currentStats;
    Logger.debug(
        '内存使用: ${memoryStats.usedMemoryMB}MB / ${memoryStats.totalMemoryMB}MB');

    // 记录内存使用
    performanceMetrics.recordMetric(
      metricName: 'startup_memory_usage',
      metricType: MetricType.memoryUsage,
      value: memoryStats.usedMemoryMB.toDouble(),
      unit: 'MB',
      metadata: {
        'totalMB': memoryStats.totalMemoryMB,
        'usagePercentage': memoryStats.usagePercentage,
        'state': memoryStats.state.toString(),
      },
    );

    // 预加载报告
    final preloadStats = preloadManager.getPerformanceStats();
    Logger.debug(
        '预加载统计: ${preloadStats['totalPreloadAttempts']} 次尝试, ${preloadStats['successfulPreloads']} 次成功');

    // 生成优化报告
    final report = performanceMetrics.generateOptimizationReport();
    Logger.debug('性能健康状态: ${report.summary['healthStatus']}');

    // 性能建议
    final suggestions = [
      ...memoryOptimizer.getOptimizationSuggestions(),
      ...preloadManager.getOptimizationSuggestions(),
      ...report.recommendations,
    ];

    if (suggestions.isNotEmpty) {
      Logger.debug('优化建议:');
      for (final suggestion in suggestions) {
        Logger.debug('  - $suggestion');
      }
    }

    Logger.debug('=== 报告结束 ===');
  }

  /// 获取详细的性能报告
  Map<String, dynamic> getDetailedPerformanceReport() {
    return {
      'startup': {
        'totalTimeMs': _performanceStartTime != null
            ? DateTime.now().difference(_performanceStartTime!).inMilliseconds
            : 0,
        'phaseDurations': _phaseDurations.map(
          (key, value) => MapEntry(key, value.inMilliseconds),
        ),
      },
      'memory': memoryOptimizer.getPerformanceReport(),
      'preload': preloadManager.getPerformanceStats(),
    };
  }

  /// 获取性能改进建议
  List<String> getPerformanceImprovements() {
    final improvements = <String>[];

    // 分析启动时间
    if (_phaseDurations.isNotEmpty) {
      final totalTime = _phaseDurations.values.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );

      if (totalTime.inMilliseconds > 2000) {
        improvements.add('启动时间超过2秒，建议优化各阶段初始化逻辑');

        // 找出最慢的阶段
        final slowestPhase = _phaseDurations.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        improvements.add(
            '最慢阶段: ${slowestPhase.key} (${slowestPhase.value.inMilliseconds}ms)');
      }
    }

    // 添加其他建议
    improvements.addAll(memoryOptimizer.getOptimizationSuggestions());
    improvements.addAll(preloadManager.getOptimizationSuggestions());

    return improvements;
  }
}

/// 初始化状态监听器
///
/// 用于监听初始化状态变化
class InitializationListener {
  final ProgressiveInitializer _initializer;
  StreamSubscription<InitializationState>? _subscription;

  InitializationListener(this._initializer);

  /// 开始监听
  void listen(void Function(InitializationState) onData) {
    _subscription = _initializer.stateStream.listen(onData);
  }

  /// 停止监听
  void cancel() {
    _subscription?.cancel();
  }

  /// 释放资源
  void dispose() {
    cancel();
  }
}

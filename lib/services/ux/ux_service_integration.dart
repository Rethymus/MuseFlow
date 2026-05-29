import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'adaptive_ui_manager.dart';
import 'immersive_mode.dart';
import 'interaction_analyzer.dart';

// 导出类型以方便使用
export 'adaptive_ui_manager.dart'
    show AdaptiveUIManager, UIComponentRecommendation, Priority;
export 'immersive_mode.dart'
    show
        ImmersiveMode,
        ImmersiveEnvironment,
        FlowStateSettings,
        ImmersiveSessionSummary;
export 'interaction_analyzer.dart'
    show
        InteractionAnalyzer,
        InteractionEvent,
        InteractionPattern,
        UsageInsight,
        OptimizationSuggestion,
        InsightType,
        SuggestionCategory,
        SuggestionPriority;

/// UX服务集成类 - 提供统一的UX服务接口
class UXServiceIntegration {
  static const String _version = '1.0.0';

  static bool _isInitialized = false;
  static final AdaptiveUIManager _uiManager = AdaptiveUIManager.instance;
  static final ImmersiveMode _immersiveMode = ImmersiveMode.instance;
  static final InteractionAnalyzer _interactionAnalyzer =
      InteractionAnalyzer.instance;

  /// 是否已初始化
  static bool get isInitialized => _isInitialized;

  /// 初始化所有UX服务
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Future.wait([
        _uiManager.initialize(),
        _interactionAnalyzer.initialize(),
      ]);

      // 不自动激活沉浸模式，由用户手动控制
      _isInitialized = true;

      debugPrint('🎨 UX服务已初始化 (版本 $_version)');
    } catch (e) {
      debugPrint('❌ UX服务初始化失败: $e');
      rethrow;
    }
  }

  /// 获取自适应UI管理器
  static AdaptiveUIManager get uiManager => _uiManager;

  /// 获取沉浸模式管理器
  static ImmersiveMode get immersiveMode => _immersiveMode;

  /// 获取交互分析器
  static InteractionAnalyzer get interactionAnalyzer => _interactionAnalyzer;

  /// 记录用户行为
  static Future<void> trackUserBehavior(
    String action,
    Map<String, dynamic>? data,
  ) async {
    await Future.wait([
      _uiManager.trackUserBehavior(action, data ?? {}),
      _interactionAnalyzer.recordInteraction(action, data ?? {}),
    ]);
  }

  /// 获取UX服务状态摘要
  static Map<String, dynamic> getStatusSummary() {
    return {
      'version': _version,
      'isInitialized': _isInitialized,
      'adaptiveUI': {
        'isInitialized': _uiManager.getUserPreferences().isNotEmpty,
        'preferences': _uiManager.getUserPreferences(),
      },
      'immersiveMode': {
        'isActive': _immersiveMode.isActive,
        'isFlowState': _immersiveMode.isFlowState,
        'sessionDuration': _immersiveMode.sessionDuration,
      },
      'interactionAnalyzer': {
        'isRecording': _interactionAnalyzer.getStatistics()['isRecording'],
        'totalInteractions':
            _interactionAnalyzer.getStatistics()['totalInteractions'],
        'identifiedPatterns':
            _interactionAnalyzer.getStatistics()['identifiedPatterns'],
      },
    };
  }

  /// 清除所有UX数据
  static Future<void> clearAllData() async {
    await Future.wait([
      _uiManager.resetHabits(),
      _interactionAnalyzer.clearAllData(),
    ]);

    debugPrint('🧹 所有UX数据已清除');
  }
}

/// UX服务提供商 - 用于依赖注入
class UXServiceProvider extends ChangeNotifier {
  final AdaptiveUIManager uiManager;
  final ImmersiveMode immersiveMode;
  final InteractionAnalyzer interactionAnalyzer;

  UXServiceProvider({
    required this.uiManager,
    required this.immersiveMode,
    required this.interactionAnalyzer,
  });

  /// 创建UX服务提供商
  static Future<UXServiceProvider> create() async {
    await UXServiceIntegration.initialize();

    return UXServiceProvider(
      uiManager: UXServiceIntegration.uiManager,
      immersiveMode: UXServiceIntegration.immersiveMode,
      interactionAnalyzer: UXServiceIntegration.interactionAnalyzer,
    );
  }

  /// 获取UX状态摘要
  Map<String, dynamic> get status => UXServiceIntegration.getStatusSummary();

  /// 记录用户行为
  Future<void> trackBehavior(String action, Map<String, dynamic>? data) async {
    await UXServiceIntegration.trackUserBehavior(action, data);
    notifyListeners();
  }

  /// 获取使用洞察
  List<UsageInsight> getUsageInsights() {
    return interactionAnalyzer.getUsageInsights();
  }

  /// 获取优化建议
  List<OptimizationSuggestion> getOptimizationSuggestions() {
    return interactionAnalyzer.getOptimizationSuggestions();
  }

  /// 获取推荐组件
  List<UIComponentRecommendation> getRecommendedComponents() {
    return uiManager.getRecommendedComponents();
  }

  /// 切换沉浸模式
  Future<void> toggleImmersiveMode() async {
    if (immersiveMode.isActive) {
      await immersiveMode.deactivate();
    } else {
      await immersiveMode.activate();
    }
    notifyListeners();
  }

  /// 更新环境设置
  void updateEnvironment(ImmersiveEnvironment environment) {
    immersiveMode.updateEnvironment(environment);
    notifyListeners();
  }

  /// 更新心流设置
  void updateFlowSettings(FlowStateSettings settings) {
    immersiveMode.updateFlowSettings(settings);
    notifyListeners();
  }

  /// 清除所有数据
  Future<void> clearAllData() async {
    await UXServiceIntegration.clearAllData();
    notifyListeners();
  }

  @override
  void dispose() {
    // 不释放单例实例，因为可能被其他地方使用
    super.dispose();
  }
}

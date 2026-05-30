import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ux/adaptive_ui_manager.dart';
import '../services/ux/immersive_mode.dart';
import '../services/ux/interaction_analyzer.dart';
import '../services/global_search_service.dart';
import '../models/app_state.dart';
import '../widgets/note_list.dart';
import '../widgets/note_editor.dart';
import '../widgets/global_search_widget.dart';
import '../models/note.dart';
import '../utils/logger.dart';
import 'package:window_manager/window_manager.dart';

/// UX增强版首页 - 集成自适应UI、沉浸模式和交互分析
class UXEnhancedHomePage extends StatefulWidget {
  const UXEnhancedHomePage({super.key});

  @override
  State<UXEnhancedHomePage> createState() => _UXEnhancedHomePageState();
}

class _UXEnhancedHomePageState extends State<UXEnhancedHomePage>
    with WindowListener {
  final AdaptiveUIManager _uiManager = AdaptiveUIManager.instance;
  final ImmersiveMode _immersiveMode = ImmersiveMode.instance;
  final InteractionAnalyzer _interactionAnalyzer = InteractionAnalyzer.instance;

  bool _isInitialized = false;
  bool _showUXRecommendations = false;

  @override
  void initState() {
    super.initState();
    _initializeUXServices();
    if (Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    try {
      final appState = context.read<AppState>();
      await appState.saveBeforeExit();
      await windowManager.destroy();
    } catch (e) {
      Logger.debug('Error during window close: $e');
      await windowManager.destroy();
    }
  }

  /// 初始化UX服务
  Future<void> _initializeUXServices() async {
    try {
      await _uiManager.initialize();
      await _interactionAnalyzer.initialize();

      // 记录页面访问事件
      await _interactionAnalyzer.recordInteraction('page_visit', {
        'page': 'home',
        'timestamp': DateTime.now().toIso8601String(),
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      Logger.debug('Failed to initialize UX services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ListenableBuilder(
      listenable: _immersiveMode,
      builder: (context, child) {
        return _immersiveMode.isActive
            ? _buildImmersiveMode()
            : _buildNormalMode();
      },
    );
  }

  /// 构建普通模式
  Widget _buildNormalMode() {
    final adaptiveLayout = _uiManager.buildAdaptiveLayout(
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Row(
          children: const [
            Expanded(flex: 1, child: NoteList()),
            Expanded(flex: 2, child: NoteEditor()),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_showUXRecommendations) _buildUXRecommendations(),
            const SizedBox(height: 8),
            _buildActionButtons(),
          ],
        ),
      ),
    );

    return adaptiveLayout;
  }

  /// 构建沉浸模式
  Widget _buildImmersiveMode() {
    return Scaffold(
      backgroundColor: _immersiveMode.environment.brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildImmersiveHeader(),
            const Expanded(child: NoteEditor()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: _toggleImmersiveMode,
        child: const Icon(Icons.exit_to_app),
      ),
    );
  }

  /// 构建应用栏
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('MuseFlow'),
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(_immersiveMode.isActive
              ? Icons.exit_to_app
              : Icons.center_focus_strong),
          onPressed: _toggleImmersiveMode,
          tooltip: '沉浸模式',
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _handleSearch(context),
        ),
        IconButton(
          icon: const Icon(Icons.lightbulb_outline),
          onPressed: () => _showUXInsights(context),
          tooltip: '使用洞察',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('请使用底部导航栏的设置功能'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  /// 构建沉浸模式头部
  Widget _buildImmersiveHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '专注写作',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Spacer(),
          _buildFlowStatus(),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _toggleImmersiveMode,
          ),
        ],
      ),
    );
  }

  /// 构建心流状态指示器
  Widget _buildFlowStatus() {
    return ListenableBuilder(
      listenable: _immersiveMode,
      builder: (context, child) {
        final isFlow = _immersiveMode.isFlowState;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isFlow ? '🎯 心流状态' : '💪 专注中',
              style: TextStyle(
                color: isFlow ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_immersiveMode.sessionDuration}分钟 | ${_immersiveMode.wordCount}字',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return FloatingActionButton(
      onPressed: () {
        context.read<AppState>().createNewNote();
        _recordInteraction('create_note');
      },
      child: const Icon(Icons.add),
    );
  }

  /// 构建UX推荐
  Widget _buildUXRecommendations() {
    final recommendations = _uiManager.getRecommendedComponents();

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '个性化推荐',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recommendations.take(3).map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        _getPriorityIcon(rec.priority),
                        size: 16,
                        color: _getPriorityColor(rec.priority),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec.componentId)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// 切换沉浸模式
  Future<void> _toggleImmersiveMode() async {
    if (_immersiveMode.isActive) {
      await _immersiveMode.deactivate();
      await _interactionAnalyzer.recordInteraction('immersive_session_end', {
        'duration': _immersiveMode.sessionDuration,
        'wordCount': _immersiveMode.wordCount,
        'focusScore': _immersiveMode.focusScore,
      });
    } else {
      await _immersiveMode.activate();
      await _interactionAnalyzer.recordInteraction('immersive_session_start', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    setState(() {});
  }

  /// 处理搜索操作
  void _handleSearch(BuildContext context) async {
    _recordInteraction('search');

    await GlobalSearchDialog.show(context);
  }

  /// 处理搜索结果选择
  void _handleSearchResult(BuildContext context, GlobalSearchResult result) {
    _recordInteraction(
        'search_result_selected', {'type': result.type.toString()});

    switch (result.type) {
      case GlobalSearchResultType.note:
        final note = result.data as Note;
        context.read<AppState>().selectNote(note);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已打开笔记: ${note.title}')),
        );
        break;

      case GlobalSearchResultType.character:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已选择角色: ${result.title}')),
        );
        break;

      case GlobalSearchResultType.world:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已选择世界观: ${result.title}')),
        );
        break;

      case GlobalSearchResultType.location:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已选择地点: ${result.title}')),
        );
        break;

      case GlobalSearchResultType.organization:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已选择组织: ${result.title}')),
        );
        break;
    }
  }

  /// 显示UX洞察
  void _showUXInsights(BuildContext context) {
    _recordInteraction('show_ux_insights');

    final insights = _interactionAnalyzer.getUsageInsights();
    final suggestions = _interactionAnalyzer.getOptimizationSuggestions();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用洞察'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text('使用习惯', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...insights.map((insight) => ListTile(
                    leading: Icon(_getInsightIcon(insight.type)),
                    title: Text(insight.title),
                    subtitle: Text(insight.description),
                    trailing: insight.actionable
                        ? const Icon(Icons.arrow_forward_ios, size: 16)
                        : null,
                  )),
              const Divider(),
              const Text('优化建议', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...suggestions.take(5).map((suggestion) => ListTile(
                    leading: Icon(_getSuggestionIcon(suggestion.category)),
                    title: Text(suggestion.title),
                    subtitle: Text(suggestion.description),
                    trailing: Text(
                      '${(suggestion.estimatedImpact * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: _getPriorityColor(suggestion.priority),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 记录交互事件
  void _recordInteraction(String type, [Map<String, dynamic>? data]) {
    _interactionAnalyzer.recordInteraction(type, data);
  }

  /// 获取优先级图标
  IconData _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Icons.star;
      case Priority.medium:
        return Icons.star_half;
      case Priority.low:
        return Icons.star_border;
    }
  }

  /// 获取优先级颜色
  Color _getPriorityColor(dynamic priority) {
    if (priority is Priority) {
      switch (priority) {
        case Priority.high:
          return Colors.red;
        case Priority.medium:
          return Colors.orange;
        case Priority.low:
          return Colors.grey;
      }
    } else if (priority is SuggestionPriority) {
      switch (priority) {
        case SuggestionPriority.high:
          return Colors.red;
        case SuggestionPriority.medium:
          return Colors.orange;
        case SuggestionPriority.low:
          return Colors.grey;
      }
    }
    return Colors.grey;
  }

  /// 获取洞察图标
  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.writingHabit:
        return Icons.schedule;
      case InsightType.engagement:
        return Icons.favorite;
      case InsightType.featurePreference:
        return Icons.apps;
      case InsightType.timePattern:
        return Icons.access_time;
    }
  }

  /// 获取建议图标
  IconData _getSuggestionIcon(SuggestionCategory category) {
    switch (category) {
      case SuggestionCategory.efficiency:
        return Icons.speed;
      case SuggestionCategory.personalization:
        return Icons.person;
      case SuggestionCategory.performance:
        return Icons.memory;
      case SuggestionCategory.accessibility:
        return Icons.accessibility;
    }
  }
}

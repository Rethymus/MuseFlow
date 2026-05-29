import 'package:flutter/material.dart';
import '../services/ux/ux_service_integration.dart';

/// UX功能演示小部件 - 展示新增的UX功能
class UXFeaturesDemo extends StatefulWidget {
  const UXFeaturesDemo({super.key});

  @override
  State<UXFeaturesDemo> createState() => _UXFeaturesDemoState();
}

class _UXFeaturesDemoState extends State<UXFeaturesDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UX功能演示'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UXSettingsPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildAdaptiveUISection(),
          const SizedBox(height: 16),
          _buildImmersiveModeSection(),
          const SizedBox(height: 16),
          _buildAnalyticsSection(),
        ],
      ),
    );
  }

  /// 构建状态卡片
  Widget _buildStatusCard() {
    final status = UXServiceIntegration.getStatusSummary();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UX服务状态',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Text('版本: ${status['version']}'),
            Text('初始化状态: ${status['isInitialized'] ? "已初始化" : "未初始化"}'),
            const SizedBox(height: 8),
            Text('自适应UI: ${status['adaptiveUI']['isInitialized'] ? "运行中" : "未运行"}'),
            Text('交互分析: ${status['interactionAnalyzer']['totalInteractions']} 个事件'),
            Text('识别模式: ${status['interactionAnalyzer']['identifiedPatterns']} 种'),
          ],
        ),
      ),
    );
  }

  /// 构建自适应UI部分
  Widget _buildAdaptiveUISection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette),
                const SizedBox(width: 8),
                Text(
                  '自适应UI',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            const Text('根据您的使用习惯自动调整界面布局和样式：'),
            const SizedBox(height: 8),
            const BulletPoint('个性化布局密度'),
            const BulletPoint('智能字体大小'),
            const BulletPoint('基于使用频率的功能推荐'),
            const BulletPoint('主题和样式自适应'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAdaptiveUIRecommendations(),
              child: const Text('查看个性化推荐'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建沉浸模式部分
  Widget _buildImmersiveModeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.center_focus_strong),
                const SizedBox(width: 8),
                Text(
                  '沉浸模式',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            const Text('提供无干扰的专注写作环境：'),
            const SizedBox(height: 8),
            const BulletPoint('自动心流状态监测'),
            const BulletPoint('专注度评分'),
            const BulletPoint('环境自动优化'),
            const BulletPoint('写作统计数据'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _toggleImmersiveMode(),
                  child: const Text('启动沉浸模式'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showEnvironmentSettings(),
                  child: const Text('环境设置'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建分析功能部分
  Widget _buildAnalyticsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics),
                const SizedBox(width: 8),
                Text(
                  '使用分析',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            const Text('学习您的使用模式并提供优化建议：'),
            const SizedBox(height: 8),
            const BulletPoint('使用习惯分析'),
            const BulletPoint('交互模式识别'),
            const BulletPoint('个性化优化建议'),
            const BulletPoint('预测性操作推荐'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showUsageInsights(),
              child: const Text('查看使用洞察'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示自适应UI推荐
  void _showAdaptiveUIRecommendations() {
    final recommendations = UXServiceIntegration.uiManager.getRecommendedComponents();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('个性化推荐'),
        content: recommendations.isEmpty
            ? const Text('暂无推荐，继续使用应用后将获得个性化建议。')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: recommendations.map((rec) => ListTile(
                  leading: Icon(
                    _getPriorityIcon(rec.priority),
                    color: _getPriorityColor(rec.priority),
                  ),
                  title: Text(rec.componentId),
                  subtitle: Text(rec.reason),
                )).toList(),
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

  /// 切换沉浸模式
  Future<void> _toggleImmersiveMode() async {
    final immersiveMode = UXServiceIntegration.immersiveMode;

    if (immersiveMode.isActive) {
      await immersiveMode.deactivate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已退出沉浸模式')),
        );
      }
    } else {
      await immersiveMode.activate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('沉浸模式已启动，开始专注写作！')),
        );
      }
    }

    setState(() {});
  }

  /// 显示环境设置
  void _showEnvironmentSettings() {
    // 简化的环境设置对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('环境设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('自动优化'),
              subtitle: const Text('进入心流时自动调整环境'),
              trailing: Switch(
                value: UXServiceIntegration.immersiveMode.environment.autoOptimize,
                onChanged: (value) {
                  final env = UXServiceIntegration.immersiveMode.environment;
                  UXServiceIntegration.immersiveMode.updateEnvironment(
                    ImmersiveEnvironment(
                      notificationLevel: env.notificationLevel,
                      brightness: env.brightness,
                      soundProfile: env.soundProfile,
                      autoOptimize: value,
                      hideUI: env.hideUI,
                      reduceMotion: env.reduceMotion,
                    ),
                  );
                  setState(() {});
                },
              ),
            ),
          ],
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

  /// 显示使用洞察
  void _showUsageInsights() {
    final insights = UXServiceIntegration.interactionAnalyzer.getUsageInsights();
    final suggestions = UXServiceIntegration.interactionAnalyzer.getOptimizationSuggestions();

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
              if (insights.isEmpty)
                const Text('暂无足够数据生成洞察')
              else
                ...insights.map((insight) => ListTile(
                  leading: Icon(_getInsightIcon(insight.type)),
                  title: Text(insight.title),
                  subtitle: Text(insight.description),
                )),
              const Divider(),
              const Text('优化建议', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (suggestions.isEmpty)
                const Text('暂无优化建议')
              else
                ...suggestions.take(5).map((suggestion) => ListTile(
                  leading: Icon(_getSuggestionIcon(suggestion.category)),
                  title: Text(suggestion.title),
                  subtitle: Text(suggestion.description),
                  trailing: Text(
                    '${(suggestion.estimatedImpact * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: _getSuggestionPriorityColor(suggestion.priority),
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
  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.grey;
    }
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

  /// 获取建议优先级颜色
  Color _getSuggestionPriorityColor(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.high:
        return Colors.red;
      case SuggestionPriority.medium:
        return Colors.orange;
      case SuggestionPriority.low:
        return Colors.grey;
    }
  }
}

/// 列表要点小部件
class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// 简化的UX设置页面
class UXSettingsPage extends StatelessWidget {
  const UXSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UX设置'),
      ),
      body: const Center(
        child: Text('完整设置页面请参考 lib/pages/ux_settings_page.dart'),
      ),
    );
  }
}
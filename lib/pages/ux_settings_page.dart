import 'package:flutter/material.dart';
import '../services/ux/adaptive_ui_manager.dart';
import '../services/ux/immersive_mode.dart';
import '../services/ux/interaction_analyzer.dart';

/// UX设置页面 - 配置个性化UI、沉浸模式和分析设置
class UXSettingsPage extends StatefulWidget {
  const UXSettingsPage({super.key});

  @override
  State<UXSettingsPage> createState() => _UXSettingsPageState();
}

class _UXSettingsPageState extends State<UXSettingsPage> {
  final AdaptiveUIManager _uiManager = AdaptiveUIManager.instance;
  final ImmersiveMode _immersiveMode = ImmersiveMode.instance;
  final InteractionAnalyzer _interactionAnalyzer = InteractionAnalyzer.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户体验设置'),
      ),
      body: ListView(
        children: [
          _buildAdaptiveUISection(),
          _buildImmersiveModeSection(),
          _buildAnalyticsSection(),
          _buildAdvancedSection(),
        ],
      ),
    );
  }

  /// 构建自适应UI设置区域
  Widget _buildAdaptiveUISection() {
    final preferences = _uiManager.getUserPreferences();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette),
                const SizedBox(width: 8),
                const Text(
                  '自适应界面',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: 实现启用/禁用功能
                  },
                ),
              ],
            ),
            const Divider(),
            ListTile(
              title: const Text('布局密度'),
              subtitle: Text(_getLayoutDensityName(preferences['preferredLayoutDensity'])),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _showLayoutDensityDialog(),
            ),
            ListTile(
              title: const Text('字体大小'),
              subtitle: Text('${preferences['preferredFontSize']}px'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _showFontSizeDialog(),
            ),
            ListTile(
              title: const Text('个性化推荐'),
              subtitle: const Text('基于使用习惯推荐功能'),
              trailing: Switch(
                value: true, // TODO: 从设置中读取
                onChanged: (value) {
                  // TODO: 保存设置
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建沉浸模式设置区域
  Widget _buildImmersiveModeSection() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.center_focus_strong),
                const SizedBox(width: 8),
                const Text(
                  '沉浸模式',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: 实现启用/禁用功能
                  },
                ),
              ],
            ),
            const Divider(),
            ListTile(
              title: const Text('环境设置'),
              subtitle: const Text('亮度、声音、通知等'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showEnvironmentSettings(),
            ),
            ListTile(
              title: const Text('心流状态监测'),
              subtitle: const Text('自动检测和优化专注状态'),
              trailing: Switch(
                value: _immersiveMode.flowSettings.enableNotifications,
                onChanged: (value) {
                  final settings = _immersiveMode.flowSettings;
                  _immersiveMode.updateFlowSettings(
                    FlowStateSettings(
                      checkInterval: settings.checkInterval,
                      minTypingSpeed: settings.minTypingSpeed,
                      minStability: settings.minStability,
                      enableNotifications: value,
                      minFlowDuration: settings.minFlowDuration,
                    ),
                  );
                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text('自动优化'),
              subtitle: const Text('进入心流时自动调整环境'),
              trailing: Switch(
                value: _immersiveMode.environment.autoOptimize,
                onChanged: (value) {
                  final env = _immersiveMode.environment;
                  _immersiveMode.updateEnvironment(
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
      ),
    );
  }

  /// 构建分析设置区域
  Widget _buildAnalyticsSection() {
    final stats = _interactionAnalyzer.getStatistics();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics),
                const SizedBox(width: 8),
                const Text(
                  '使用分析',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: stats['isRecording'] as bool,
                  onChanged: (value) {
                    // TODO: 实现启用/禁用功能
                  },
                ),
              ],
            ),
            const Divider(),
            ListTile(
              title: const Text('交互记录'),
              subtitle: Text('已记录 ${stats['totalInteractions']} 个交互事件'),
            ),
            ListTile(
              title: const Text('识别模式'),
              subtitle: Text('发现 ${stats['identifiedPatterns']} 种使用模式'),
            ),
            ListTile(
              title: const Text('数据管理'),
              subtitle: const Text('清除或导出使用数据'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showDataManagementDialog(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建高级设置区域
  Widget _buildAdvancedSection() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_suggest),
                const SizedBox(width: 8),
                const Text(
                  '高级选项',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            ListTile(
              title: const Text('重置所有UX设置'),
              subtitle: const Text('恢复到默认配置'),
              leading: const Icon(Icons.restore),
              onTap: () => _showResetDialog(),
            ),
            ListTile(
              title: const Text('实验性功能'),
              subtitle: const Text('尝试新的用户体验功能'),
              leading: const Icon(Icons.science),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('即将推出')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示布局密度对话框
  void _showLayoutDensityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择布局密度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            '紧凑',
            '舒适',
            '宽松',
          ].map((density) => RadioListTile<String>(
            title: Text(_getLayoutDensityName(density)),
            value: density,
            groupValue: _uiManager.getUserPreferences()['preferredLayoutDensity'],
            onChanged: (value) {
              if (value != null) {
                _uiManager.trackUserBehavior('layout_density_changed', {'density': value});
                Navigator.pop(context);
                setState(() {});
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  /// 显示字体大小对话框
  void _showFontSizeDialog() {
    double fontSize = _uiManager.getUserPreferences()['preferredFontSize'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('调整字体大小'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('示例文本', style: TextStyle(fontSize: fontSize)),
                Slider(
                  value: fontSize,
                  min: 12,
                  max: 24,
                  divisions: 12,
                  label: '${fontSize.round()}px',
                  onChanged: (value) {
                    setDialogState(() {
                      fontSize = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _uiManager.trackUserBehavior('font_size_changed', {'size': fontSize});
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示环境设置对话框
  void _showEnvironmentSettings() {
    final env = _immersiveMode.environment;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('环境设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('通知级别'),
              subtitle: Text(_getNotificationLevelName(env.notificationLevel)),
              onTap: () => _showNotificationLevelDialog(),
            ),
            ListTile(
              title: const Text('界面亮度'),
              subtitle: Text(env.brightness == Brightness.dark ? '暗色' : '亮色'),
              onTap: () => _showBrightnessDialog(),
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

  /// 显示通知级别对话框
  void _showNotificationLevelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择通知级别'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: NotificationLevel.values.map((level) => RadioListTile<NotificationLevel>(
            title: Text(_getNotificationLevelName(level)),
            value: level,
            groupValue: _immersiveMode.environment.notificationLevel,
            onChanged: (value) {
              if (value != null) {
                final env = _immersiveMode.environment;
                _immersiveMode.updateEnvironment(
                  ImmersiveEnvironment(
                    notificationLevel: value,
                    brightness: env.brightness,
                    soundProfile: env.soundProfile,
                    autoOptimize: env.autoOptimize,
                    hideUI: env.hideUI,
                    reduceMotion: env.reduceMotion,
                  ),
                );
                Navigator.pop(context);
                setState(() {});
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  /// 显示亮度设置对话框
  void _showBrightnessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择界面亮度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Brightness.values.map((brightness) => RadioListTile<Brightness>(
            title: Text(brightness == Brightness.dark ? '暗色' : '亮色'),
            value: brightness,
            groupValue: _immersiveMode.environment.brightness,
            onChanged: (value) {
              if (value != null) {
                final env = _immersiveMode.environment;
                _immersiveMode.updateEnvironment(
                  ImmersiveEnvironment(
                    notificationLevel: env.notificationLevel,
                    brightness: value,
                    soundProfile: env.soundProfile,
                    autoOptimize: env.autoOptimize,
                    hideUI: env.hideUI,
                    reduceMotion: env.reduceMotion,
                  ),
                );
                Navigator.pop(context);
                setState(() {});
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  /// 显示数据管理对话框
  void _showDataManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据管理'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('清除所有数据'),
              leading: const Icon(Icons.delete_forever),
              onTap: () => _confirmClearData(),
            ),
            ListTile(
              title: const Text('导出使用数据'),
              leading: const Icon(Icons.download),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('功能开发中')),
                );
              },
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

  /// 确认清除数据
  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('这将删除所有使用习惯和交互历史数据，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await _uiManager.resetHabits();
              await _interactionAnalyzer.clearAllData();
              Navigator.pop(context);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据已清除')),
              );
            },
            child: const Text('确认清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 显示重置对话框
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要将所有UX设置恢复到默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await _uiManager.resetHabits();
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置已重置')),
              );
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  /// 获取布局密度名称
  String _getLayoutDensityName(String density) {
    switch (density) {
      case 'compact':
        return '紧凑';
      case 'comfortable':
        return '舒适';
      case 'spacious':
        return '宽松';
      default:
        return '舒适';
    }
  }

  /// 获取通知级别名称
  String _getNotificationLevelName(NotificationLevel level) {
    switch (level) {
      case NotificationLevel.all:
        return '全部通知';
      case NotificationLevel.standard:
        return '标准';
      case NotificationLevel.minimal:
        return '最少';
      case NotificationLevel.none:
        return '不显示';
    }
  }
}
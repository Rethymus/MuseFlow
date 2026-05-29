import '../utils/logger.dart';
import '../config/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../services/storage_service.dart';

/// 设置页面
/// 管理应用的各种设置和配置
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  final Map<String, String> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = context.read<AppState>();
      // 这里可以加载各种设置项
      // 目前只是示例结构
    } catch (e) {
      Logger.debug('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, String value) async {
    try {
      final appState = context.read<AppState>();
      await appState.setSetting(key, value);
      setState(() {
        _settings[key] = value;
      });
    } catch (e) {
      Logger.debug('Error updating setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 标题
                  Text(
                    '设置',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 通用设置
                  _buildSettingsSection(
                    theme,
                    title: '通用设置',
                    children: [
                      _buildThemeSetting(theme),
                      _buildLanguageSetting(theme),
                      _buildFontSizeSetting(theme),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 编辑器设置
                  _buildSettingsSection(
                    theme,
                    title: '编辑器设置',
                    children: [
                      _buildAutoSaveSetting(theme),
                      _buildSpellCheckSetting(theme),
                      _buildWordCountSetting(theme),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // AI设置
                  _buildSettingsSection(
                    theme,
                    title: 'AI设置',
                    children: [
                      _buildAIModelSetting(theme),
                      _buildAICreativitySetting(theme),
                      _buildIntentConfirmationSetting(theme),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 存储设置
                  _buildSettingsSection(
                    theme,
                    title: '存储设置',
                    children: [
                      _buildStorageLocationSetting(theme),
                      _buildBackupSetting(theme),
                      _buildCacheManagementSetting(theme),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 关于
                  _buildSettingsSection(
                    theme,
                    title: '关于',
                    children: [
                      _buildVersionInfo(theme),
                      _buildLicenseInfo(theme),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSettingsSection(
    ThemeData theme, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSetting(ThemeData theme) {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('主题'),
      subtitle: const Text('选择应用主题'),
      trailing: DropdownButton<ThemeMode>(
        value: Theme.of(context).brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        items: const [
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Text('浅色'),
          ),
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Text('深色'),
          ),
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Text('跟随系统'),
          ),
        ],
        onChanged: (value) {
          // TODO: 实现主题切换
          if (value != null) {
            _updateSetting('theme_mode', value.toString());
          }
        },
      ),
    );
  }

  Widget _buildLanguageSetting(ThemeData theme) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('语言'),
      subtitle: const Text('选择界面语言'),
      trailing: const DropdownButton<String>(
        value: '中文',
        items: [
          DropdownMenuItem(
            value: '中文',
            child: Text('中文'),
          ),
          DropdownMenuItem(
            value: 'English',
            child: Text('English'),
          ),
        ],
        onChanged: null,
      ),
    );
  }

  Widget _buildFontSizeSetting(ThemeData theme) {
    return ListTile(
      leading: const Icon(Icons.format_size),
      title: const Text('字体大小'),
      subtitle: const Text('调整编辑器字体大小'),
      trailing: DropdownButton<int>(
        value: 16,
        items: const [
          DropdownMenuItem(value: 14, child: Text('小')),
          DropdownMenuItem(value: 16, child: Text('中')),
          DropdownMenuItem(value: 18, child: Text('大')),
          DropdownMenuItem(value: 20, child: Text('特大')),
        ],
        onChanged: (value) {
          if (value != null) {
            _updateSetting('font_size', value.toString());
          }
        },
      ),
    );
  }

  Widget _buildAutoSaveSetting(ThemeData theme) {
    return SwitchListTile(
      secondary: const Icon(Icons.save),
      title: const Text('自动保存'),
      subtitle: const Text('编辑时自动保存笔记'),
      value: true,
      onChanged: (value) {
        _updateSetting('auto_save', value.toString());
      },
    );
  }

  Widget _buildSpellCheckSetting(ThemeData theme) {
    return SwitchListTile(
      secondary: const Icon(Icons.spellcheck),
      title: const Text('拼写检查'),
      subtitle: const Text('启用拼写检查功能'),
      value: false,
      onChanged: (value) {
        _updateSetting('spell_check', value.toString());
      },
    );
  }

  Widget _buildWordCountSetting(ThemeData theme) {
    return SwitchListTile(
      secondary: const Icon(Icons.countertops),
      title: const Text('字数统计'),
      subtitle: const Text('显示实时字数统计'),
      value: true,
      onChanged: (value) {
        _updateSetting('word_count', value.toString());
      },
    );
  }

  Widget _buildAIModelSetting(ThemeData theme) {
    return ListTile(
      leading: const Icon(Icons.psychology),
      title: const Text('AI模型'),
      subtitle: const Text('选择AI处理模型'),
      trailing: const DropdownButton<String>(
        value: 'Claude 3.5',
        items: [
          DropdownMenuItem(value: 'Claude 3.5', child: Text('Claude 3.5')),
          DropdownMenuItem(value: 'GPT-4', child: Text('GPT-4')),
          DropdownMenuItem(value: '本地模型', child: Text('本地模型')),
        ],
        onChanged: null,
      ),
    );
  }

  Widget _buildAICreativitySetting(ThemeData theme) {
    return ListTile(
      leading: const Icon(Icons.tune),
      title: const Text('AI创造力'),
      subtitle: const Text('调整AI的创造力水平'),
      trailing: DropdownButton<double>(
        value: 0.7,
        items: const [
          DropdownMenuItem(value: 0.3, child: Text('保守')),
          DropdownMenuItem(value: 0.7, child: Text('平衡')),
          DropdownMenuItem(value: 1.0, child: Text('创新')),
        ],
        onChanged: (value) {
          if (value != null) {
            _updateSetting('ai_creativity', value.toString());
          }
        },
      ),
    );
  }

  Widget _buildIntentConfirmationSetting(ThemeData theme) {
    return SwitchListTile(
      secondary: const Icon(Icons.verified_user),
      title: const Text('意图确认'),
      subtitle: const Text('AI操作前显示确认对话框'),
      value: true,
      onChanged: (value) {
        _updateSetting('intent_confirmation', value.toString());
      },
    );
  }

  Widget _buildStorageLocationSetting(ThemeData theme) {
    return ListTile(
      leading: const Icon(Icons.folder),
      title: const Text('存储位置'),
      subtitle: const Text('设置数据存储目录'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: 实现存储位置选择
        _showStorageLocationDialog();
      },
    );
  }

  Widget _buildBackupSetting(ThemeData theme) {
    return ListTile(
      leading: const Icon(Icons.backup),
      title: const Text('数据备份'),
      subtitle: const Text('管理数据备份'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showBackupDialog();
      },
    );
  }

  Widget _buildCacheManagementSetting(ThemeData theme) {
    return ListTile(
      leading: const Icon(Icons.cleaning_services),
      title: const Text('缓存管理'),
      subtitle: const Text('清除应用缓存'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showCacheDialog();
      },
    );
  }

  Widget _buildVersionInfo(ThemeData theme) {
    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('版本信息'),
      subtitle: const Text('MuseFlow v1.0.0'),
      onTap: () {
        _showVersionDialog();
      },
    );
  }

  Widget _buildLicenseInfo(ThemeData theme) {
    return ListTile(
      leading: const Icon(Icons.description),
      title: const Text('许可证'),
      subtitle: const Text('查看开源许可证'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showLicenseDialog();
      },
    );
  }

  void _showStorageLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('存储位置'),
        content: const Text('当前存储位置将在未来版本中支持自定义配置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据备份'),
        content: const Text('备份功能将在未来版本中实现。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('缓存管理'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('缓存大小: 2.5 MB'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('清除缓存'),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('缓存已清除')),
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

  void _showVersionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('版本信息'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MuseFlow v1.0.0'),
            SizedBox(height: 8),
            Text('一个集AI辅助写作、知识管理和创意工具于一体的应用。'),
            SizedBox(height: 16),
            Text('功能特性:'),
            SizedBox(height: 8),
            Text('• AI辅助写作和润色'),
            Text('• 思维碎片管理'),
            Text('• 上下文锚点'),
            Text('• 角色卡和世界观管理'),
            Text('• 全局搜索'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开源许可证'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MuseFlow 使用以下开源库:'),
              SizedBox(height: 16),
              Text('• Flutter - BSD 3-Clause License'),
              Text('• Provider - MIT License'),
              Text('• UUID - BSD 3-Clause License'),
              Text('• Window Manager - MIT License'),
              SizedBox(height: 16),
              Text('MuseFlow 本身采用 MIT 许可证发布。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

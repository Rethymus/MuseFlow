import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/shared/constants/app_constants.dart';

/// Settings page with section headers for storage and about.
///
/// Provides navigation to AI provider management sub-page.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            '设置',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 32),
          // AI Model section
          Text(
            'AI',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('AI 模型'),
            subtitle: const Text('配置和管理 AI 模型提供商'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppConstants.aiProviders),
          ),
          const Divider(),
          const SizedBox(height: 16),
          // Storage section
          Text(
            '存储',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('本地数据'),
            subtitle: Text('所有数据存储在本地设备'),
          ),
          const Divider(),
          const SizedBox(height: 16),
          // About section
          Text(
            '关于',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('MuseFlow 灵韵'),
            subtitle: Text('版本 0.1.0'),
          ),
          const ListTile(
            leading: Icon(Icons.code_outlined),
            title: Text('许可证'),
            subtitle: Text('开源许可信息'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/creativity_level.dart';
import 'package:museflow/shared/constants/app_constants.dart';

/// Settings page with section headers for storage and about.
///
/// Provides navigation to AI provider management sub-page.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, this.debugClearStats});

  final Future<void> Function()? debugClearStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text('设置', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 32),
          // AI Model section
          Text('AI', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('AI 模型'),
            subtitle: const Text('配置和管理 AI 模型提供商'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppConstants.aiProviders),
          ),
          ListTile(
            leading: const Icon(Icons.filter_alt_outlined),
            title: const Text('AI 用语过滤'),
            subtitle: const Text('自定义需要过滤的 AI 味词组'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppConstants.bannedPhrases),
          ),
          // D-CP-01: opt-in post-operation consistency check. OFF by default
          // because it fires an extra LLM call (raises token cost).
          SwitchListTile(
            secondary: const Icon(Icons.fact_check_outlined),
            title: const Text('AI 操作后自动一致性检查'),
            subtitle: const Text('每次 AI 操作后自动校验设定一致性（额外消耗 token，默认关闭）'),
            value: ref.watch(autoDeviationCheckProvider),
            onChanged: (value) =>
                ref.read(autoDeviationCheckProvider.notifier).set(value),
          ),
          // AA-03: user-facing creativity level that governs generation
          // temperature (TempParaphraser, EMNLP 2025 — higher sampling
          // diversity reduces AI-text detection footprint).
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('创意度'),
            subtitle: const Text('影响 AI 生成的多样性，灵动档可降低机器味'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: SegmentedButton<CreativityLevel>(
              segments: const [
                ButtonSegment(
                  value: CreativityLevel.conservative,
                  label: Text('保守'),
                ),
                ButtonSegment(
                  value: CreativityLevel.balanced,
                  label: Text('平衡'),
                ),
                ButtonSegment(
                  value: CreativityLevel.expressive,
                  label: Text('灵动'),
                ),
              ],
              selected: {ref.watch(creativityLevelProvider)},
              onSelectionChanged: (selection) => ref
                  .read(creativityLevelProvider.notifier)
                  .set(selection.first),
            ),
          ),
          const Divider(),
          const SizedBox(height: 16),
          // Storage section
          Text('存储', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('本地数据'),
            subtitle: Text('所有数据存储在本地设备'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('清除写作统计'),
            subtitle: const Text('清除字数、趋势和成就徽章，不影响正文和知识库'),
            onTap: () => _confirmClearStats(context, ref),
          ),
          const Divider(),
          const SizedBox(height: 16),
          // About section
          Text('关于', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('MuseFlow 灵韵'),
            subtitle: Text('版本 0.1.1'),
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

  Future<void> _confirmClearStats(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除写作统计？'),
        content: const Text('此操作只会删除本地统计数据，不会删除作品正文。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final debugClearStats = this.debugClearStats;
    if (debugClearStats != null) {
      await debugClearStats();
    } else {
      final repository = await ref.read(writingStatsRepositoryProvider.future);
      await repository.clearAll();
      ref.invalidate(writingStatsNotifierProvider);
      ref.invalidate(achievementNotifierProvider);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('写作统计已清除')));
  }
}

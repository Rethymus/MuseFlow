import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/creativity_level.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/features/settings/presentation/web_workspace_settings_section.dart';
import 'package:museflow/shared/widgets/app_controls.dart';
import 'package:museflow/shared/widgets/app_dialogs.dart';
import 'package:museflow/shared/widgets/app_list_section.dart';

/// Settings page — the iOS Settings showcase.
///
/// Inset grouped lists on the gray background: colored squircle icon
/// badges, value/chevron rows, in-row switches and segmented controls.
/// Provider wiring is unchanged from the pre-redesign page.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, this.debugClearStats});

  final Future<void> Function()? debugClearStats;

  static const _themeModeLabels = ['跟随系统', '浅色', '深色'];
  static const _themeModes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text('设置', style: textTheme.displayMedium)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Appearance section: day/night writing is a standard ergonomics
          // feature for long-session writing tools (HF-7).
          AppListSection(
            header: '外观',
            children: [
              AppListTile(
                icon: CupertinoIcons.paintbrush,
                iconColor: AppColors.of(context).accent,
                title: '主题模式',
                subtitle: '日间写作用浅色，夜间护眼用深色',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppSegmentedControl<int>(
                    segments: const {0, 1, 2},
                    selected: _themeModes.indexOf(themeMode),
                    onSelectionChanged: (index) => ref
                        .read(themeModeProvider.notifier)
                        .set(_themeModes[index]),
                    labelOf: (index) => _themeModeLabels[index],
                  ),
                ),
              ),
            ],
          ),
          if (kIsWeb) const WebWorkspaceSettingsSection(),
          AppListSection(
            header: 'AI',
            children: [
              AppListTile(
                icon: CupertinoIcons.sparkles,
                iconColor: AppColors.of(context).systemPurple,
                title: 'AI 模型',
                subtitle: '配置和管理 AI 模型提供商',
                showChevron: true,
                onTap: () => context.go(AppConstants.aiProviders),
              ),
              AppListTile(
                icon: CupertinoIcons.line_horizontal_3_decrease,
                iconColor: AppColors.of(context).systemOrange,
                title: 'AI 用语过滤',
                subtitle: '自定义需要过滤的 AI 味词组',
                showChevron: true,
                onTap: () => context.go(AppConstants.bannedPhrases),
              ),
              // D-CP-01: opt-in post-operation consistency check. OFF by
              // default because it fires an extra LLM call (token cost).
              AppListTile(
                icon: CupertinoIcons.shield,
                iconColor: AppColors.of(context).systemTeal,
                title: 'AI 操作后自动一致性检查',
                subtitle: '每次 AI 操作后自动校验设定一致性（额外消耗 token，默认关闭）',
                trailing: AppSwitch(
                  value: ref.watch(autoDeviationCheckProvider),
                  onChanged: (value) =>
                      ref.read(autoDeviationCheckProvider.notifier).set(value),
                ),
              ),
              // AA-03: user-facing creativity level that governs generation
              // temperature (TempParaphraser, EMNLP 2025 — higher sampling
              // diversity reduces AI-text detection footprint).
              AppListTile(
                icon: CupertinoIcons.bolt,
                iconColor: AppColors.of(context).systemPink,
                title: '创意度',
                subtitle: '影响 AI 生成的多样性，灵动档可降低机器味',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppSegmentedControl<int>(
                    segments: const {0, 1, 2},
                    selected: CreativityLevel.values.indexOf(
                      ref.watch(creativityLevelProvider),
                    ),
                    onSelectionChanged: (index) => ref
                        .read(creativityLevelProvider.notifier)
                        .set(CreativityLevel.values[index]),
                    labelOf: (index) => const ['保守', '平衡', '灵动'][index],
                  ),
                ),
              ),
            ],
          ),
          AppListSection(
            header: '存储',
            children: [
              AppListTile(
                icon: CupertinoIcons.archivebox,
                iconColor: AppColors.of(context).gray,
                title: '本地数据',
                subtitle: '所有数据存储在本地设备',
              ),
              AppListTile(
                icon: CupertinoIcons.trash,
                iconColor: AppColors.of(context).systemRed,
                title: '清除写作统计',
                subtitle: '清除字数、趋势和成就徽章，不影响正文和知识库',
                onTap: () => _confirmClearStats(context, ref),
              ),
            ],
          ),
          AppListSection(
            header: '关于',
            children: [
              AppListTile(
                icon: CupertinoIcons.book,
                iconColor: AppColors.of(context).accent,
                title: 'MuseFlow 灵韵',
                value: '版本 ${AppConstants.appVersion}',
              ),
              const AppListTile(
                icon: CupertinoIcons.doc_text,
                title: '许可证',
                subtitle: '开源许可信息',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearStats(BuildContext context, WidgetRef ref) async {
    // The dialog closes itself; the destructive action carries the logic.
    await showAppDialog(
      context,
      title: '清除写作统计？',
      message: '此操作只会删除本地统计数据，不会删除作品正文。',
      actions: [
        const AppDialogAction('取消', isDefault: true),
        AppDialogAction(
          '清除',
          isDestructive: true,
          onPressed: () => _clearStats(context, ref),
        ),
      ],
    );
  }

  Future<void> _clearStats(BuildContext context, WidgetRef ref) async {
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

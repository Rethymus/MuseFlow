import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/widgets/app_card.dart';

/// A card widget displaying a preset AI provider option.
///
/// Per D-02: Shows provider name, icon placeholder, and brief description.
/// On tap, invokes the callback with the preset AIProvider template.
class ProviderCard extends StatelessWidget {
  final AIProvider provider;
  final VoidCallback onTap;

  const ProviderCard({super.key, required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppColors.of(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          _buildIcon(p),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: p.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_right, size: 14, color: p.tertiaryLabel),
        ],
      ),
    );
  }

  Widget _buildIcon(AppPalette p) {
    final tint = _iconTint(p);
    final icon = switch (provider.type) {
      AiProviderType.openai => CupertinoIcons.bolt,
      AiProviderType.deepseek => CupertinoIcons.textformat,
      AiProviderType.ollama => CupertinoIcons.desktopcomputer,
      AiProviderType.claude => CupertinoIcons.sparkles,
      AiProviderType.custom => CupertinoIcons.slider_horizontal_3,
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 19, color: tint),
    );
  }

  Color _iconTint(AppPalette p) {
    return switch (provider.type) {
      AiProviderType.openai => p.systemGreen,
      AiProviderType.deepseek => p.systemBlue,
      AiProviderType.ollama => p.systemTeal,
      AiProviderType.claude => p.systemPurple,
      AiProviderType.custom => p.systemOrange,
    };
  }

  String get _description => switch (provider.type) {
    AiProviderType.openai => 'GPT-4o Mini, ${provider.baseUrl}',
    AiProviderType.deepseek => 'DeepSeek Chat, ${provider.baseUrl}',
    AiProviderType.ollama => '本地模型, 无需 API Key',
    AiProviderType.claude => 'Claude Sonnet 4, ${provider.baseUrl}',
    AiProviderType.custom => '自定义模型配置',
  };
}

import 'package:flutter/material.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';

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
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildIcon(context),
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
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final icon = switch (provider.type) {
      AiProviderType.openai => Icons.smart_toy_outlined,
      AiProviderType.deepseek => Icons.psychology_outlined,
      AiProviderType.ollama => Icons.computer_outlined,
      AiProviderType.claude => Icons.auto_awesome_outlined,
      AiProviderType.custom => Icons.tune,
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: colorScheme.onPrimaryContainer),
    );
  }

  String get _description => switch (provider.type) {
    AiProviderType.openai => 'GPT-4o Mini, ${provider.baseUrl}',
    AiProviderType.deepseek => 'DeepSeek Chat, ${provider.baseUrl}',
    AiProviderType.ollama => '本地模型, 无需 API Key',
    AiProviderType.claude => 'Claude Sonnet 4, ${provider.baseUrl}',
    AiProviderType.custom => '自定义模型配置',
  };
}

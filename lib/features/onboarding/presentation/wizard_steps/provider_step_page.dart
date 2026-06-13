/// Onboarding wizard step for AI provider configuration.
///
/// Allows new users to set up an AI provider during onboarding so they
/// can immediately use AI-assisted features after completing the wizard.
/// This step is skippable — users can configure providers later in Settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/preset_providers.dart';

/// Callback type for provider setup completion.
typedef ProviderSetupCallback = void Function(bool configured);

/// Wizard step page for configuring an AI provider during onboarding.
///
/// Shows preset provider cards (OpenAI, Claude, DeepSeek, Ollama) and
/// a manual configuration form. Includes a test connection button.
class ProviderStepPage extends ConsumerStatefulWidget {
  final ProviderSetupCallback onSetupComplete;

  const ProviderStepPage({super.key, required this.onSetupComplete});

  @override
  ConsumerState<ProviderStepPage> createState() => _ProviderStepPageState();
}

class _ProviderStepPageState extends ConsumerState<ProviderStepPage> {
  AiProviderType _selectedType = AiProviderType.openai;
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _isTesting = false;
  String? _testResult; // 'success' or error message
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _applyPreset(AiProviderType.openai);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _applyPreset(AiProviderType type) {
    final preset = PresetProviders.all.where((p) => p.type == type).firstOrNull;
    if (preset == null) return;

    setState(() {
      _selectedType = type;
      _nameController.text = preset.name;
      _baseUrlController.text = preset.baseUrl;
      _modelController.text = preset.model;
      _testResult = null;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final service = await ref.read(providerServiceProvider.future);
      final apiKey = PresetProviders.requiresApiKey(_selectedType)
          ? _apiKeyController.text.trim()
          : 'ollama-no-key';

      await service.testConnection(
        apiKey: apiKey,
        baseUrl: _baseUrlController.text.trim(),
        model: _modelController.text.trim(),
        type: _selectedType,
      );

      if (mounted) {
        setState(() => _testResult = 'success');
      }
    } on AIAuthException {
      if (mounted) setState(() => _testResult = 'API Key 无效');
    } on AIRateLimitException {
      if (mounted) setState(() => _testResult = '连接正常，但请求频率受限');
    } on AINetworkException {
      if (mounted) setState(() => _testResult = '网络连接失败');
    } catch (e) {
      if (mounted) setState(() => _testResult = '测试失败: $e');
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _saveAndContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final service = await ref.read(providerServiceProvider.future);
      final apiKey = PresetProviders.requiresApiKey(_selectedType)
          ? _apiKeyController.text.trim()
          : 'ollama-no-key';

      final provider = await service.createProvider(
        name: name,
        baseUrl: _baseUrlController.text.trim(),
        type: _selectedType,
        model: _modelController.text.trim(),
        apiKey: apiKey,
      );

      await service.setActiveProvider(provider.id);

      if (mounted) {
        widget.onSetupComplete(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preset provider cards
          Text('选择 AI 服务商', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          _buildPresetCards(theme),
          const SizedBox(height: 24),

          // Configuration form
          Text('配置详情', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          _buildForm(theme),
          const SizedBox(height: 16),

          // Test connection button
          _buildTestButton(theme),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _saveAndContinue,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存并继续'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => widget.onSetupComplete(false),
              child: Text(
                '跳过，稍后在设置中配置',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetCards(ThemeData theme) {
    final types = [
      AiProviderType.openai,
      AiProviderType.claude,
      AiProviderType.deepseek,
      AiProviderType.ollama,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _selectedType == type;
        final label = switch (type) {
          AiProviderType.openai => 'OpenAI',
          AiProviderType.claude => 'Claude',
          AiProviderType.deepseek => 'DeepSeek',
          AiProviderType.ollama => 'Ollama (本地)',
          _ => '自定义',
        };

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => _applyPreset(type),
        );
      }).toList(),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '名称',
            hintText: '如：我的AI助手',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _baseUrlController,
          decoration: const InputDecoration(
            labelText: 'API 地址',
            hintText: 'https://api.openai.com/v1',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _modelController,
          decoration: const InputDecoration(
            labelText: '模型',
            hintText: 'gpt-4o-mini',
            border: OutlineInputBorder(),
          ),
        ),
        if (PresetProviders.requiresApiKey(_selectedType)) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.visibility_off_outlined),
                tooltip: '显示/隐藏',
                onPressed: () {
                  // Toggle visibility is handled by the text field itself
                  // in a full implementation; for onboarding simplicity
                  // we keep the key obscured
                },
              ),
            ),
            obscureText: true,
          ),
        ],
      ],
    );
  }

  Widget _buildTestButton(ThemeData theme) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _isTesting ? null : _testConnection,
          icon: _isTesting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_find, size: 18),
          label: Text(_isTesting ? '测试中...' : '测试连接'),
        ),
        if (_testResult != null) ...[
          const SizedBox(width: 12),
          Icon(
            _testResult == 'success' ? Icons.check_circle : Icons.error_outline,
            color: _testResult == 'success'
                ? Colors.green
                : theme.colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            _testResult == 'success' ? '连接成功' : _testResult!,
            style: TextStyle(
              color: _testResult == 'success'
                  ? Colors.green
                  : theme.colorScheme.error,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

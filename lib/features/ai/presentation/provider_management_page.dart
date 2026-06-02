import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/preset_providers.dart';
import 'package:museflow/features/ai/presentation/provider_card.dart';
import 'package:museflow/features/ai/presentation/provider_management_notifier.dart';

/// AI Provider management settings page.
///
/// Per D-01: Left panel shows saved provider list, right panel shows
/// configuration form. Per D-02: Preset providers shown as clickable cards.
/// Per D-03: API Key obscured with eye toggle, test connection button.
/// Per D-04: Radio selection for active provider.
class ProviderManagementPage extends ConsumerStatefulWidget {
  const ProviderManagementPage({super.key});

  @override
  ConsumerState<ProviderManagementPage> createState() =>
      _ProviderManagementPageState();
}

class _ProviderManagementPageState
    extends ConsumerState<ProviderManagementPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;

  AiProviderType _selectedType = AiProviderType.custom;
  bool _obscureApiKey = true;
  bool _isEditing = false;
  String? _editingProviderId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _baseUrlController = TextEditingController();
    _apiKeyController = TextEditingController();
    _modelController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _baseUrlController.clear();
    _apiKeyController.clear();
    _modelController.clear();
    setState(() {
      _selectedType = AiProviderType.custom;
      _isEditing = false;
      _editingProviderId = null;
      _obscureApiKey = true;
    });
    ref.read(providerManagementProvider.notifier).clearSelection();
  }

  void _fillFromPreset(AIProvider preset) {
    _nameController.text = preset.name;
    _baseUrlController.text = preset.baseUrl;
    _modelController.text = preset.model;
    _apiKeyController.clear();
    setState(() {
      _selectedType = preset.type;
      _isEditing = false;
      _editingProviderId = null;
    });
    ref.read(providerManagementProvider.notifier).startFromPreset(preset);
  }

  Future<void> _fillForEdit(AIProvider provider) async {
    _nameController.text = provider.name;
    _baseUrlController.text = provider.baseUrl;
    _modelController.text = provider.model;
    setState(() {
      _selectedType = provider.type;
      _isEditing = true;
      _editingProviderId = provider.id;
    });
    // Load API key from secure storage
    final service = ref.read(providerServiceProvider).asData?.value;
    if (service != null) {
      final key = await service.getApiKey(provider.id);
      if (mounted) {
        _apiKeyController.text = key ?? '';
      }
    }
    ref.read(providerManagementProvider.notifier).selectProvider(provider);
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) return false;
    if (_baseUrlController.text.trim().isEmpty) return false;
    if (_modelController.text.trim().isEmpty) return false;
    // API key required for non-Ollama providers
    if (PresetProviders.requiresApiKey(_selectedType) &&
        _apiKeyController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _handleSave() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写所有必填字段')),
      );
      return;
    }

    final notifier = ref.read(providerManagementProvider.notifier);

    if (_isEditing && _editingProviderId != null) {
      // Update existing
      final mgmtState = ref.read(providerManagementProvider);
      final existing = mgmtState.providers.firstWhere(
        (p) => p.id == _editingProviderId,
      );
      final updated = existing.copyWith(
        name: _nameController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
        type: _selectedType,
        model: _modelController.text.trim(),
      );
      await notifier.updateProvider(updated);
      // Update API key if changed
      final service = ref.read(providerServiceProvider).asData?.value;
      if (service != null) {
        final oldKey = await service.getApiKey(_editingProviderId!);
        if (oldKey != _apiKeyController.text.trim()) {
          await service.updateApiKey(
            _editingProviderId!,
            _apiKeyController.text.trim(),
          );
        }
      }
    } else {
      // Create new
      final apiKey = PresetProviders.requiresApiKey(_selectedType)
          ? _apiKeyController.text.trim()
          : 'ollama-no-key';
      await notifier.createProvider(
        name: _nameController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
        type: _selectedType,
        model: _modelController.text.trim(),
        apiKey: apiKey,
      );
    }
  }

  Future<void> _handleTestConnection() async {
    final notifier = ref.read(providerManagementProvider.notifier);
    final apiKey = PresetProviders.requiresApiKey(_selectedType)
        ? _apiKeyController.text.trim()
        : 'ollama-no-key';
    await notifier.testConnection(
      apiKey: apiKey,
      baseUrl: _baseUrlController.text.trim(),
    );
  }

  Future<void> _handleDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此模型配置吗？API Key 将同时移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(providerManagementProvider.notifier).deleteProvider(id);
      _clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mgmtState = ref.watch(providerManagementProvider);
    final presets = ref.watch(presetProvidersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 模型管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: mgmtState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left panel: Provider list
                SizedBox(
                  width: 300,
                  child: _buildLeftPanel(context, mgmtState, presets),
                ),
                const VerticalDivider(width: 1),
                // Right panel: Configuration form
                Expanded(
                  child: _buildRightPanel(context, mgmtState),
                ),
              ],
            ),
    );
  }

  Widget _buildLeftPanel(
    BuildContext context,
    ProviderManagementState mgmtState,
    List<AIProvider> presets,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '预设模型',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...presets.map((preset) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ProviderCard(
                provider: preset,
                onTap: () => _fillFromPreset(preset),
              ),
            )),
        // Custom provider option
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ProviderCard(
            provider: AIProvider(
              id: 'preset-custom',
              name: '自定义',
              baseUrl: '',
              type: AiProviderType.custom,
              model: '',
              createdAt: DateTime.now(),
            ),
            onTap: () {
              _clearForm();
              setState(() => _selectedType = AiProviderType.custom);
            },
          ),
        ),
        const Divider(height: 24),

        // Saved providers section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            '已配置',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: mgmtState.providers.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '尚未配置模型\n点击上方预设开始',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RadioGroup<String>(
                  groupValue: mgmtState.activeProvider?.id,
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(providerManagementProvider.notifier)
                          .setActiveProvider(value);
                    }
                  },
                  child: ListView.builder(
                    itemCount: mgmtState.providers.length,
                    itemBuilder: (context, index) {
                      final provider = mgmtState.providers[index];
                      final isActive =
                          mgmtState.activeProvider?.id == provider.id;
                      final isSelected =
                          mgmtState.selectedProvider?.id == provider.id;

                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor:
                            colorScheme.primaryContainer.withAlpha(50),
                        leading: Radio<String>(
                          value: provider.id,
                        ),
                        title: Text(provider.name),
                        subtitle: Text(
                          provider.model,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: isActive
                            ? Icon(Icons.check_circle,
                                size: 16, color: colorScheme.primary)
                            : null,
                        onTap: () => _fillForEdit(provider),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(
    BuildContext context,
    ProviderManagementState mgmtState,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? '编辑模型' : '配置新模型',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Provider type selector
          Text('模型类型', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<AiProviderType>(
            segments: const [
              ButtonSegment(value: AiProviderType.openai, label: Text('OpenAI')),
              ButtonSegment(value: AiProviderType.deepseek, label: Text('DeepSeek')),
              ButtonSegment(value: AiProviderType.ollama, label: Text('Ollama')),
              ButtonSegment(value: AiProviderType.custom, label: Text('自定义')),
            ],
            selected: {_selectedType},
            onSelectionChanged: (types) {
              setState(() => _selectedType = types.first);
            },
          ),
          const SizedBox(height: 20),

          // Name field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '名称',
              hintText: '例如：我的 OpenAI',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Base URL field
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'https://api.openai.com/v1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Model field
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: '模型',
              hintText: 'gpt-4o-mini',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // API Key field (hidden for Ollama)
          if (PresetProviders.requiresApiKey(_selectedType)) ...[
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureApiKey = !_obscureApiKey);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Test Connection button with inline feedback
          if (PresetProviders.requiresApiKey(_selectedType)) ...[
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: mgmtState.isTestingConnection
                      ? null
                      : _handleTestConnection,
                  child: mgmtState.isTestingConnection
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('测试连接'),
                ),
                if (mgmtState.connectionTestResult != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    mgmtState.connectionTestResult == 'success'
                        ? Icons.check_circle
                        : Icons.error_outline,
                    size: 18,
                    color: mgmtState.connectionTestResult == 'success'
                        ? Colors.green
                        : colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mgmtState.connectionTestResult == 'success'
                        ? '连接成功'
                        : mgmtState.connectionTestResult!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mgmtState.connectionTestResult == 'success'
                          ? Colors.green
                          : colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Action buttons
          Row(
            children: [
              FilledButton(
                onPressed: _handleSave,
                child: Text(_isEditing ? '更新' : '保存'),
              ),
              const SizedBox(width: 12),
              if (_isEditing) ...[
                OutlinedButton(
                  onPressed: () => _handleDelete(_editingProviderId!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  child: const Text('删除'),
                ),
                const SizedBox(width: 12),
              ],
              OutlinedButton(
                onPressed: _clearForm,
                child: const Text('清空'),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Advanced mode toggle (disabled placeholder per D-04)
          Text(
            '高阶模式',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '为不同场景指定不同模型',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SwitchListTile(
            value: false,
            onChanged: null,
            title: const Text('场景化模型分配'),
            subtitle: const Text('即将推出'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

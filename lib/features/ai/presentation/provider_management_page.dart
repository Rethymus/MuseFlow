/// AI Provider management settings page.
///
/// Split across 1 part file (provider_management_page_layout.dart) to
/// satisfy the 03-flutter-standards.md file-size cap. All symbols live
/// in the same library — consumers import this file unchanged.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/preset_providers.dart';
import 'package:museflow/features/ai/presentation/parameter_validation.dart';
import 'package:museflow/features/ai/presentation/provider_card.dart';
import 'package:museflow/features/ai/presentation/provider_management_notifier.dart';
import 'package:museflow/shared/constants/app_constants.dart';

part 'provider_management_page_layout.dart';

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
  late final TextEditingController _temperatureController;
  late final TextEditingController _topPController;
  late final TextEditingController _maxTokensController;

  AiProviderType _selectedType = AiProviderType.custom;
  bool _obscureApiKey = true;
  bool _isEditing = false;
  bool _showList = true;
  String? _editingProviderId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _baseUrlController = TextEditingController();
    _apiKeyController = TextEditingController();
    _modelController = TextEditingController();
    _temperatureController = TextEditingController();
    _topPController = TextEditingController();
    _maxTokensController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  void _clearForm({bool showListOnNarrow = false}) {
    _nameController.clear();
    _baseUrlController.clear();
    _apiKeyController.clear();
    _modelController.clear();
    _temperatureController.clear();
    _topPController.clear();
    _maxTokensController.clear();
    setState(() {
      _selectedType = AiProviderType.custom;
      _isEditing = false;
      _editingProviderId = null;
      _obscureApiKey = true;
      _showList = showListOnNarrow;
    });
    ref.read(providerManagementProvider.notifier).clearSelection();
  }

  void _fillFromPreset(AIProvider preset) {
    _nameController.text = preset.name;
    _baseUrlController.text = preset.baseUrl;
    _modelController.text = preset.model;
    _apiKeyController.clear();
    // Presets have null params, so leave parameter fields empty
    _temperatureController.clear();
    _topPController.clear();
    _maxTokensController.clear();
    setState(() {
      _selectedType = preset.type;
      _isEditing = false;
      _editingProviderId = null;
      _showList = false;
    });
    ref.read(providerManagementProvider.notifier).startFromPreset(preset);
  }

  Future<void> _fillForEdit(AIProvider provider) async {
    _nameController.text = provider.name;
    _baseUrlController.text = provider.baseUrl;
    _modelController.text = provider.model;
    // Convert nullable params to text: null -> empty, non-null -> string
    _temperatureController.text = provider.temperature?.toString() ?? '';
    _topPController.text = provider.topP?.toString() ?? '';
    _maxTokensController.text = provider.maxTokens?.toString() ?? '';
    setState(() {
      _selectedType = provider.type;
      _isEditing = true;
      _editingProviderId = provider.id;
      _showList = false;
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

  // --- State mutation helpers (called from layout extension) ---
  // These wrap setState so the layout extension in
  // provider_management_page_layout.dart does not invoke the protected
  // setState directly (lint: invalid_use_of_protected_member).

  void _showListOnNarrow() {
    setState(() => _showList = true);
  }

  void _selectCustomProviderType() {
    setState(() {
      _selectedType = AiProviderType.custom;
      _showList = false;
    });
  }

  void _selectProviderType(AiProviderType type) {
    setState(() => _selectedType = type);
  }

  void _toggleApiKeyVisibility() {
    setState(() => _obscureApiKey = !_obscureApiKey);
  }

  Future<void> _handleSave() async {
    if (kIsWeb && !_hasValidWebBaseUrl()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web 版服务地址必须是有效的 HTTPS URL')),
      );
      return;
    }
    if (!_validateForm()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写所有必填字段')));
      return;
    }

    final notifier = ref.read(providerManagementProvider.notifier);
    // Parse nullable parameters from text fields
    final temperature = parseTemperature(_temperatureController.text.trim());
    final topP = parseTopP(_topPController.text.trim());
    final maxTokens = parseMaxTokens(_maxTokensController.text.trim());

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
        temperature: temperature,
        topP: topP,
        maxTokens: maxTokens,
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
        temperature: temperature,
        topP: topP,
        maxTokens: maxTokens,
      );
    }
  }

  bool _hasValidWebBaseUrl() {
    final uri = Uri.tryParse(_baseUrlController.text.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  Future<void> _handleTestConnection() async {
    final notifier = ref.read(providerManagementProvider.notifier);
    final apiKey = PresetProviders.requiresApiKey(_selectedType)
        ? _apiKeyController.text.trim()
        : 'ollama-no-key';
    await notifier.testConnection(
      apiKey: apiKey,
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
      type: _selectedType,
    );
  }

  Future<void> _handleFetchModels() async {
    final notifier = ref.read(providerManagementProvider.notifier);
    final apiKey = PresetProviders.requiresApiKey(_selectedType)
        ? _apiKeyController.text.trim()
        : 'ollama-no-key';
    await notifier.fetchModels(
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
      _clearForm(showListOnNarrow: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mgmtState = ref.watch(providerManagementProvider);
    final allPresets = ref.watch(presetProvidersProvider);
    final presets = kIsWeb
        ? allPresets
              .where((provider) => provider.type != AiProviderType.ollama)
              .toList()
        : allPresets;

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
          : LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow =
                    constraints.maxWidth <
                    AppConstants.sidebarCollapsedBreakpoint;

                if (isNarrow) {
                  return Column(
                    children: [
                      _buildMobileSwitcher(context, mgmtState),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _showList
                              ? _buildLeftPanel(context, mgmtState, presets)
                              : _buildRightPanel(context, mgmtState),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    SizedBox(
                      width: 300,
                      child: _buildLeftPanel(context, mgmtState, presets),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: _buildRightPanel(context, mgmtState)),
                  ],
                );
              },
            ),
    );
  }
}

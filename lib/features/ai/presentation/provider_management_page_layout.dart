part of 'provider_management_page.dart';

/// Layout helpers for [_ProviderManagementPageState].
///
/// Extracted from provider_management_page.dart to satisfy the
/// 03-flutter-standards.md file-size cap. Dart does not allow splitting a
/// single State class body across files, so the mobile-switcher /
/// left-panel / right-panel builders live in this private extension. The
/// state's [build] method invokes them via bare names — Dart resolves
/// same-library extension-on-this members transparently, so call sites are
/// unchanged.
extension _ProviderManagementPageStateLayout on _ProviderManagementPageState {
  Widget _buildMobileSwitcher(
    BuildContext context,
    ProviderManagementState mgmtState,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _showListOnNarrow,
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回列表'),
            ),
            const Spacer(),
            if (_showList)
              FilledButton.tonalIcon(
                onPressed: () => _clearForm(),
                icon: const Icon(Icons.add),
                label: const Text('新建'),
              )
            else
              Text(
                mgmtState.selectedProvider?.name ?? '模型配置',
                style: theme.textTheme.labelLarge,
              ),
          ],
        ),
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
        // Preset cards scroll to prevent vertical overflow as more presets are
        // added (the panel hosts multiple preset providers + a custom option).
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...presets.map(
                  (preset) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ProviderCard(
                      provider: preset,
                      onTap: () => _fillFromPreset(preset),
                    ),
                  ),
                ),
                // Custom provider option
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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
                      _selectCustomProviderType();
                    },
                  ),
                ),
              ],
            ),
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
                        selectedTileColor: colorScheme.primaryContainer
                            .withAlpha(50),
                        leading: Radio<String>(value: provider.id),
                        title: Text(provider.name),
                        subtitle: Text(
                          provider.model,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: isActive
                            ? Icon(
                                Icons.check_circle,
                                size: 16,
                                color: colorScheme.primary,
                              )
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<AiProviderType>(
              segments: const [
                ButtonSegment(
                  value: AiProviderType.openai,
                  label: Text('OpenAI'),
                ),
                ButtonSegment(
                  value: AiProviderType.deepseek,
                  label: Text('DeepSeek'),
                ),
                ButtonSegment(
                  value: AiProviderType.claude,
                  label: Text('Claude'),
                ),
                ButtonSegment(
                  value: AiProviderType.ollama,
                  label: Text('Ollama'),
                ),
                ButtonSegment(value: AiProviderType.custom, label: Text('自定义')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (types) {
                _selectProviderType(types.first);
              },
            ),
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

          // Model field with fetch button (combo input per D-07)
          TextField(
            controller: _modelController,
            decoration: InputDecoration(
              labelText: '模型',
              hintText: 'gpt-4o-mini',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: mgmtState.isFetchingModels
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: '获取模型列表',
                onPressed: mgmtState.isFetchingModels
                    ? null
                    : _handleFetchModels,
              ),
            ),
          ),
          // Model list dropdown per D-07/D-08
          if (mgmtState.availableModels.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: mgmtState.availableModels.length,
                itemBuilder: (context, index) {
                  final modelId = mgmtState.availableModels[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      modelId,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _modelController.text = modelId;
                    },
                  );
                },
              ),
            ),
          ],
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
                    _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: _toggleApiKeyVisibility,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Parameter input rows per D-05
          Text('模型参数', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            '留空使用模型默认值',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // Temperature field
          TextField(
            controller: _temperatureController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Temperature',
              hintText: '0.0 - 2.0，留空使用默认值',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Top-P field
          TextField(
            controller: _topPController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Top-P',
              hintText: '0.0 - 1.0，留空使用默认值',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Max Tokens field
          TextField(
            controller: _maxTokensController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '最大 Token 数',
              hintText: '1 - 128000，留空使用默认值',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

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
              OutlinedButton(onPressed: _clearForm, child: const Text('清空')),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Advanced mode toggle (disabled placeholder per D-04)
          Text('高阶模式', style: theme.textTheme.titleSmall),
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

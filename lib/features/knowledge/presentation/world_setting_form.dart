import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';

/// Form for creating or editing a [WorldSetting].
///
/// Provide [settingId] for edit mode (looks up from notifier state),
/// or omit it for create mode.
class WorldSettingForm extends ConsumerStatefulWidget {
  final String? settingId;

  const WorldSettingForm({super.key, this.settingId});

  @override
  ConsumerState<WorldSettingForm> createState() => _WorldSettingFormState();
}

class _WorldSettingFormState extends ConsumerState<WorldSettingForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _rulesController;
  late final TextEditingController _factionsController;
  late final TextEditingController _geographyController;
  late final TextEditingController _techLevelController;
  late final TextEditingController _aliasesController;
  bool _isSaving = false;

  bool get _isEditing => widget.settingId != null;

  WorldSetting? _findSetting(List<WorldSetting> settings) {
    if (widget.settingId == null) return null;
    try {
      return settings.firstWhere((s) => s.id == widget.settingId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _rulesController = TextEditingController();
    _factionsController = TextEditingController();
    _geographyController = TextEditingController();
    _techLevelController = TextEditingController();
    _aliasesController = TextEditingController();

    // Seed controllers from notifier state if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedFromExisting();
    });
  }

  void _seedFromExisting() {
    final settings = ref.read(worldSettingNotifierProvider).asData?.value ?? [];
    final setting = _findSetting(settings);
    if (setting != null) {
      _nameController.text = setting.name;
      _descriptionController.text = setting.description;
      _rulesController.text = setting.rules;
      _factionsController.text = setting.factions;
      _geographyController.text = setting.geography;
      _techLevelController.text = setting.techLevel;
      _aliasesController.text = setting.aliases.join(', ');
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _factionsController.dispose();
    _geographyController.dispose();
    _techLevelController.dispose();
    _aliasesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑世界观' : '新建世界观')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称 *',
                hintText: '世界观名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入世界观名称';
                }
                if (value.trim().length > 100) {
                  return '名称不能超过100个字符';
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述',
                hintText: '世界观的简要描述',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 5000,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rulesController,
              decoration: const InputDecoration(
                labelText: '规则',
                hintText: '天地法则、因果循环等',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 5000,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _factionsController,
              decoration: const InputDecoration(
                labelText: '势力',
                hintText: '正道联盟、魔道、散修等',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 5000,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _geographyController,
              decoration: const InputDecoration(
                labelText: '地理',
                hintText: '东洲、西荒、南疆、北冥等',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 5000,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _techLevelController,
              decoration: const InputDecoration(
                labelText: '科技等级',
                hintText: '古代仙侠、中世纪、现代等',
                border: OutlineInputBorder(),
              ),
              maxLength: 5000,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aliasesController,
              decoration: const InputDecoration(
                labelText: '别名',
                hintText: '用逗号分隔，如：仙界, 九天',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? '保存修改' : '创建世界观'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _parseAliases(String text) {
    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final aliases = _parseAliases(_aliasesController.text);
      final notifier = ref.read(worldSettingNotifierProvider.notifier);

      if (_isEditing) {
        final settings =
            ref.read(worldSettingNotifierProvider).asData?.value ?? [];
        final existing = _findSetting(settings);
        if (existing == null) {
          throw StateError('World setting not found');
        }
        final updated = existing.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          rules: _rulesController.text.trim(),
          factions: _factionsController.text.trim(),
          geography: _geographyController.text.trim(),
          techLevel: _techLevelController.text.trim(),
          aliases: aliases,
        );
        await notifier.save(updated);
      } else {
        final setting = WorldSetting(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          rules: _rulesController.text.trim(),
          factions: _factionsController.text.trim(),
          geography: _geographyController.text.trim(),
          techLevel: _techLevelController.text.trim(),
          aliases: aliases,
          createdAt: DateTime.now(),
        );
        await notifier.add(setting);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? '世界观已更新' : '世界观已创建')),
        );
        context.go('/knowledge');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

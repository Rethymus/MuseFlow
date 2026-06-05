import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/templates/application/template_draft.dart';
import 'package:museflow/features/templates/domain/world_template.dart';
import 'package:museflow/shared/constants/app_constants.dart';

class TemplateDraftPage extends ConsumerStatefulWidget {
  const TemplateDraftPage({
    super.key,
    required this.templateId,
    this.initialConcept = '',
  });

  final String? templateId;
  final String initialConcept;

  @override
  ConsumerState<TemplateDraftPage> createState() => _TemplateDraftPageState();
}

class _TemplateDraftPageState extends ConsumerState<TemplateDraftPage> {
  late Future<_DraftLoadResult?> _draftFuture;
  TemplateDraft? _draft;
  TemplateCreationResult? _result;
  bool _isCompleting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _draftFuture = _loadDraft();
  }

  Future<_DraftLoadResult?> _loadDraft() async {
    final id = widget.templateId;
    if (id == null) return null;
    final template = await ref
        .read(worldTemplateRepositoryProvider)
        .getById(id);
    if (template == null) return null;
    final service = await ref.read(templateInstantiationServiceProvider.future);
    final draft = service.createDraft(
      template,
      storyConcept: widget.initialConcept,
    );
    _draft = draft;
    return _DraftLoadResult(template: template, draft: draft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('确认模板草稿')),
      body: FutureBuilder<_DraftLoadResult?>(
        future: _draftFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null || _draft == null) {
            return const Center(child: Text('未找到模板'));
          }
          if (_result != null) return _ResultSummary(result: _result!);

          final template = snapshot.data!.template;
          final draft = _draft!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                template.displayTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: draft.storyConcept),
                decoration: InputDecoration(
                  labelText: '故事概念',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                minLines: 2,
                maxLines: 4,
                onChanged: (value) =>
                    _updateDraft(draft.copyWith(storyConcept: value)),
              ),
              const SizedBox(height: 16),
              _WorldDraftPanel(draft: draft.world, onChanged: _updateWorld),
              for (final character in draft.characters)
                _CharacterDraftPanel(
                  draft: character,
                  onChanged: (updated) => _updateCharacter(updated),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isCompleting ? null : _completeBlankFields,
                icon: _isCompleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('AI补全空白字段'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveDraft,
                icon: const Icon(Icons.save_alt),
                label: const Text('保存到知识库'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateDraft(TemplateDraft draft) {
    setState(() => _draft = draft);
  }

  void _updateWorld(WorldSettingDraft world) {
    _updateDraft(_draft!.copyWith(world: world));
  }

  void _updateCharacter(CharacterCardDraft character) {
    final characters = [
      for (final existing in _draft!.characters)
        if (existing.draftId == character.draftId) character else existing,
    ];
    _updateDraft(_draft!.copyWith(characters: characters));
  }

  Future<void> _completeBlankFields() async {
    setState(() => _isCompleting = true);
    try {
      final service = await ref.read(templateCompletionServiceProvider.future);
      final result = await service.completeBlankFields(_draft!);
      if (!mounted) return;
      setState(() => _draft = result.draft);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.succeeded ? 'AI补全完成' : 'AI补全失败，可继续手动保存')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI补全失败，可继续手动保存')));
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    try {
      final service = await ref.read(
        templateInstantiationServiceProvider.future,
      );
      final result = await service.saveDraft(_draft!);
      if (!mounted) return;
      setState(() => _result = result);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _WorldDraftPanel extends StatelessWidget {
  const _WorldDraftPanel({required this.draft, required this.onChanged});

  final WorldSettingDraft draft;
  final ValueChanged<WorldSettingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: false,
      leading: Checkbox(
        value: draft.selected,
        onChanged: (value) =>
            onChanged(draft.copyWith(selected: value ?? true)),
      ),
      title: Text('世界观：${draft.name.value}'),
      children: [
        _DraftTextField(
          label: '名称',
          field: draft.name,
          onChanged: (field) => onChanged(draft.copyWith(name: field)),
        ),
        _DraftTextField(
          label: '描述',
          field: draft.description,
          onChanged: (field) => onChanged(draft.copyWith(description: field)),
        ),
        _DraftTextField(
          label: '规则',
          field: draft.rules,
          onChanged: (field) => onChanged(draft.copyWith(rules: field)),
        ),
        _DraftTextField(
          label: '势力',
          field: draft.factions,
          onChanged: (field) => onChanged(draft.copyWith(factions: field)),
        ),
        _DraftTextField(
          label: '地理',
          field: draft.geography,
          onChanged: (field) => onChanged(draft.copyWith(geography: field)),
        ),
        _DraftTextField(
          label: '技术/时代',
          field: draft.techLevel,
          onChanged: (field) => onChanged(draft.copyWith(techLevel: field)),
        ),
        _DraftTextField(
          label: '别名',
          field: draft.aliases,
          onChanged: (field) => onChanged(draft.copyWith(aliases: field)),
        ),
      ],
    );
  }
}

class _CharacterDraftPanel extends StatelessWidget {
  const _CharacterDraftPanel({required this.draft, required this.onChanged});

  final CharacterCardDraft draft;
  final ValueChanged<CharacterCardDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: false,
      leading: Checkbox(
        value: draft.selected,
        onChanged: (value) =>
            onChanged(draft.copyWith(selected: value ?? true)),
      ),
      title: Text('角色：${draft.name.value}'),
      children: [
        _DraftTextField(
          label: '名称',
          field: draft.name,
          onChanged: (field) => onChanged(draft.copyWith(name: field)),
        ),
        _DraftTextField(
          label: '性格',
          field: draft.personality,
          onChanged: (field) => onChanged(draft.copyWith(personality: field)),
        ),
        _DraftTextField(
          label: '外貌',
          field: draft.appearance,
          onChanged: (field) => onChanged(draft.copyWith(appearance: field)),
        ),
        _DraftTextField(
          label: '背景',
          field: draft.backstory,
          onChanged: (field) => onChanged(draft.copyWith(backstory: field)),
        ),
        _DraftTextField(
          label: '别名',
          field: draft.aliases,
          onChanged: (field) => onChanged(draft.copyWith(aliases: field)),
        ),
      ],
    );
  }
}

class _DraftTextField extends StatelessWidget {
  const _DraftTextField({
    required this.label,
    required this.field,
    required this.onChanged,
  });

  final String label;
  final DraftTextField field;
  final ValueChanged<DraftTextField> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: TextFormField(
        initialValue: field.value,
        minLines: 1,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: label,
          helperText: _sourceLabel(field.source),
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => onChanged(field.edit(value)),
      ),
    );
  }

  String _sourceLabel(TemplateFieldSource source) {
    return switch (source) {
      TemplateFieldSource.templateDefault => '模板默认',
      TemplateFieldSource.aiCompleted => 'AI补全',
      TemplateFieldSource.userEdited => '你已编辑',
    };
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.result});

  final TemplateCreationResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('创建完成', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (result.worldSetting != null)
            Text('世界观：${result.worldSetting!.name}'),
          for (final card in result.characterCards) Text('角色：${card.name}'),
          const Spacer(),
          FilledButton(
            onPressed: () => context.go(AppConstants.knowledge),
            child: const Text('返回知识库'),
          ),
        ],
      ),
    );
  }
}

class _DraftLoadResult {
  const _DraftLoadResult({required this.template, required this.draft});

  final WorldTemplate template;
  final TemplateDraft draft;
}

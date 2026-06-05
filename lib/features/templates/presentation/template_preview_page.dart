import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/templates/domain/world_template.dart';
import 'package:museflow/shared/constants/app_constants.dart';

class TemplatePreviewPage extends ConsumerStatefulWidget {
  const TemplatePreviewPage({super.key, required this.templateId});

  final String? templateId;

  @override
  ConsumerState<TemplatePreviewPage> createState() =>
      _TemplatePreviewPageState();
}

class _TemplatePreviewPageState extends ConsumerState<TemplatePreviewPage> {
  final _conceptController = TextEditingController();
  late Future<WorldTemplate?> _templateFuture;

  @override
  void initState() {
    super.initState();
    _templateFuture = widget.templateId == null
        ? Future.value(null)
        : ref.read(worldTemplateRepositoryProvider).getById(widget.templateId!);
  }

  @override
  void dispose() {
    _conceptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模板预览')),
      body: FutureBuilder<WorldTemplate?>(
        future: _templateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final template = snapshot.data;
          if (template == null) {
            return const Center(child: Text('未找到模板'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                template.displayTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(template.description),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  const _PreviewTag(label: '内置已审核'),
                  for (final tag in template.tags) _PreviewTag(label: tag),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _conceptController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '你的故事概念（可选）',
                  hintText: '例如：一个不想修仙的医女被迫卷入宗门秘案',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _WorldSection(template: template),
              _CharactersSection(template: template),
              _ForeshadowingSection(template: template),
              _OpeningSamplesSection(template: template),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _useTemplate(template),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('使用模板'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _useTemplate(WorldTemplate template) {
    final concept = Uri.encodeQueryComponent(_conceptController.text.trim());
    context.go(
      '${AppConstants.knowledgeTemplates}/${template.id}/draft?concept=$concept',
    );
  }
}

class _WorldSection extends StatelessWidget {
  const _WorldSection({required this.template});

  final WorldTemplate template;

  @override
  Widget build(BuildContext context) {
    final world = template.world;
    return ExpansionTile(
      title: const Text('世界设定骨架'),
      children: [
        _FieldText(label: '名称', value: world.name),
        _FieldText(label: '描述', value: world.description),
        _FieldText(label: '规则', value: world.rules),
        _FieldText(label: '势力', value: world.factions),
        _FieldText(label: '地理', value: world.geography),
        _FieldText(label: '技术/时代', value: world.techLevel),
      ],
    );
  }
}

class _CharactersSection extends StatelessWidget {
  const _CharactersSection({required this.template});

  final WorldTemplate template;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('角色原型'),
      children: [
        for (final character in template.characters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _FieldText(label: '性格', value: character.personality),
                _FieldText(label: '外貌', value: character.appearance),
                _FieldText(label: '背景', value: character.backstory),
              ],
            ),
          ),
      ],
    );
  }
}

class _ForeshadowingSection extends StatelessWidget {
  const _ForeshadowingSection({required this.template});

  final WorldTemplate template;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('伏笔模式'),
      children: [
        for (final arc in template.foreshadowingArcs)
          ListTile(
            dense: true,
            leading: const Icon(Icons.timeline),
            title: Text(arc.displayText),
          ),
      ],
    );
  }
}

class _OpeningSamplesSection extends StatelessWidget {
  const _OpeningSamplesSection({required this.template});

  final WorldTemplate template;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('开篇示例'),
      children: [
        for (final sample in template.openingSamples)
          _FieldText(label: _styleLabel(sample.style), value: sample.text),
      ],
    );
  }

  String _styleLabel(OpeningSampleStyle style) {
    return switch (style) {
      OpeningSampleStyle.scene => '场景切入',
      OpeningSampleStyle.character => '人物切入',
      OpeningSampleStyle.suspense => '悬念切入',
    };
  }
}

class _FieldText extends StatelessWidget {
  const _FieldText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('$label：$value'),
      ),
    );
  }
}

class _PreviewTag extends StatelessWidget {
  const _PreviewTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}

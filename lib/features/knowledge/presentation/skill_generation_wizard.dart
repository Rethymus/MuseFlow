import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';

class SkillGenerationWizard extends ConsumerStatefulWidget {
  const SkillGenerationWizard({super.key});

  @override
  ConsumerState<SkillGenerationWizard> createState() => _SkillGenerationWizardState();
}

class _SkillGenerationWizardState extends ConsumerState<SkillGenerationWizard> {
  final _nameController = TextEditingController();
  final _conceptController = TextEditingController();
  int _step = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generation = ref.watch(skillGenerationNotifierProvider);
    final generated = generation.asData?.value.document;

    return Scaffold(
      appBar: AppBar(title: const Text('创建世界观模板')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () => _continue(generated != null),
        onStepCancel: _step == 0 ? null : () => setState(() => _step--),
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              FilledButton(onPressed: details.onStepContinue, child: Text(_step == 2 ? '完成' : '下一步')),
              const SizedBox(width: 8),
              if (details.onStepCancel != null)
                TextButton(onPressed: details.onStepCancel, child: const Text('上一步')),
            ],
          ),
        ),
        steps: [
          Step(
            title: const Text('描述概念'),
            isActive: _step == 0,
            content: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '模板名称'),
                ),
                TextField(
                  controller: _conceptController,
                  decoration: const InputDecoration(labelText: '世界观概念'),
                  minLines: 4,
                  maxLines: 8,
                ),
              ],
            ),
          ),
          Step(
            title: const Text('AI 生成'),
            isActive: _step == 1,
            content: generation.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('生成失败: $error'),
              data: (state) => SelectableText(
                state.progressText.isEmpty ? '点击下一步开始生成。' : state.progressText,
              ),
            ),
          ),
          Step(
            title: const Text('保存'),
            isActive: _step == 2,
            content: generated == null
                ? const Text('尚未生成模板。')
                : SelectableText(generated.toContextString),
          ),
        ],
      ),
    );
  }

  void _continue(bool hasGenerated) {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty || _conceptController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写名称和概念')));
        return;
      }
      setState(() => _step = 1);
      ref.read(skillGenerationNotifierProvider.notifier).generateSkill(
            _conceptController.text.trim(),
            _nameController.text.trim(),
          );
      return;
    }
    if (_step == 1) {
      if (!hasGenerated) return;
      setState(() => _step = 2);
      return;
    }
    context.go('/knowledge/skills');
  }
}

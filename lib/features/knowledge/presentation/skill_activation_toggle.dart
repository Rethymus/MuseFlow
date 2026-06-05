import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';

class SkillActivationToggle extends ConsumerWidget {
  const SkillActivationToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillListNotifierProvider);
    return skillsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('技能加载失败: $error'),
      data: (skills) {
        final activeCount = skills.where((skill) => skill.isActive).length;
        if (skills.isEmpty) return const Text('暂无世界观模板');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$activeCount 个技能已激活'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in skills)
                  FilterChip(
                    label: Text(skill.name),
                    selected: skill.isActive,
                    onSelected: (_) => ref
                        .read(skillListNotifierProvider.notifier)
                        .toggleActive(skill.id),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

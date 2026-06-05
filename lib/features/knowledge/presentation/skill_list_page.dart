import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';

class SkillListPage extends ConsumerWidget {
  const SkillListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillListNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('世界观模板')),
      body: skillsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
        data: (skills) {
          if (skills.isEmpty) {
            return const Center(child: Text('暂无模板\n点击 + 创建'));
          }
          return ListView.builder(
            itemCount: skills.length,
            itemBuilder: (context, index) => _SkillTile(skill: skills[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/knowledge/skills/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SkillTile extends ConsumerWidget {
  final SkillDocument skill;

  const _SkillTile({required this.skill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(
          skill.isActive ? Icons.auto_stories : Icons.auto_stories_outlined,
        ),
        title: Text(skill.name),
        subtitle: Text(
          skill.description.isNotEmpty ? skill.description : skill.sections.nonNullSections.join('、'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            Switch(
              value: skill.isActive,
              onChanged: (_) => ref
                  .read(skillListNotifierProvider.notifier)
                  .toggleActive(skill.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref.read(skillListNotifierProvider.notifier).delete(skill.id),
            ),
          ],
        ),
      ),
    );
  }
}

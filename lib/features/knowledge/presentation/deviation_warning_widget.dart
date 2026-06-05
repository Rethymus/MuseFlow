import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';

class DeviationWarningWidget extends ConsumerWidget {
  const DeviationWarningWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warnings = ref.watch(deviationNotifierProvider).asData?.value.warnings ?? const [];
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded),
                const SizedBox(width: 8),
                Expanded(child: Text('检测到 ${warnings.length} 条设定偏离提醒')),
                TextButton(
                  onPressed: () => ref.read(deviationNotifierProvider.notifier).clearAll(),
                  child: const Text('全部忽略'),
                ),
              ],
            ),
            for (var i = 0; i < warnings.length; i++)
              _WarningTile(index: i, warning: warnings[i]),
          ],
        ),
      ),
    );
  }
}

class _WarningTile extends ConsumerWidget {
  final int index;
  final DeviationWarning warning;

  const _WarningTile({required this.index, required this.warning});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = warning.severity == DeviationSeverity.clear
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.tertiary;

    return Card(
      child: ListTile(
        leading: Icon(Icons.report_problem_outlined, color: color),
        title: Text('${warning.skillName}: ${warning.description}'),
        subtitle: warning.suggestedFix == null || warning.suggestedFix!.isEmpty
            ? null
            : Text('建议修复：${warning.suggestedFix}'),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => ref.read(deviationNotifierProvider.notifier).dismissWarning(index),
        ),
      ),
    );
  }
}

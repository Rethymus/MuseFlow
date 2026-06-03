import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/application/guardian_notifier.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';

/// Side panel for manual guardian checks and finding display.
///
/// Shows check state (idle/checking/error/results), finding cards with
/// severity/kind/reason/suggested fix, and supports dismiss/retry actions.
///
/// Guardian suggestions never auto-apply. Suggested rewrites are copyable
/// or can be routed to explicit review.
class GuardianPanel extends ConsumerStatefulWidget {
  final String? selectedText;

  const GuardianPanel({super.key, this.selectedText});

  @override
  ConsumerState<GuardianPanel> createState() => _GuardianPanelState();
}

class _GuardianPanelState extends ConsumerState<GuardianPanel> {
  @override
  Widget build(BuildContext context) {
    final guardianAsync = ref.watch(guardianNotifierProvider);

    return guardianAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(error.toString()),
      data: (result) => _buildContent(result),
    );
  }

  Widget _buildContent(GuardianCheckResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                '角色守护',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Check button area
        Padding(
          padding: const EdgeInsets.all(12),
          child: _buildCheckButton(result),
        ),

        // Results area
        Expanded(child: _buildResults(result)),
      ],
    );
  }

  Widget _buildCheckButton(GuardianCheckResult result) {
    if (result.state == GuardianCheckState.checking) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('正在检查...'),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: _runCheck,
        child: const Text('运行守护检查'),
      ),
    );
  }

  Widget _buildResults(GuardianCheckResult result) {
    switch (result.state) {
      case GuardianCheckState.idle:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 48),
                SizedBox(height: 16),
                Text(
                  '暂无守护提示',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  '手动检查当前章节或选中文本，AI 会提示可能的人设、时间线或世界规则冲突。提示只供参考。',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      case GuardianCheckState.checking:
        return const Center(child: CircularProgressIndicator());

      case GuardianCheckState.error:
        return _buildError(result.errorMessage ?? '检查失败');

      case GuardianCheckState.results:
        if (result.annotations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 48),
                  SizedBox(height: 16),
                  Text(
                    '未发现明显冲突',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '你仍然是最终判断者。',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: result.annotations.length,
          itemBuilder: (context, index) {
            return _FindingCard(
              annotation: result.annotations[index],
              onDismiss: () => _dismiss(result.annotations[index].id),
            );
          },
        );
    }
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              '检查失败',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: _runCheck,
                  child: const Text('重试'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => ref
                      .read(guardianNotifierProvider.notifier)
                      .resetToIdle(),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runCheck() async {
    final notifier = ref.read(guardianNotifierProvider.notifier);
    notifier.setChecking();

    try {
      final service = await ref.read(guardianCheckServiceProvider.future);
      final text = widget.selectedText ?? '';
      if (text.isEmpty) {
        notifier.setError('没有选中的文本可供检查');
        return;
      }

      final annotations =
          await service.checkCharacterConsistency(text: text);
      await notifier.setResults(annotations);
    } catch (e) {
      notifier.setError(e.toString());
    }
  }

  Future<void> _dismiss(String id) async {
    await ref.read(guardianNotifierProvider.notifier).dismiss(id);
  }
}

/// Card displaying a single guardian finding.
///
/// Uses amber/violet advisory colors distinct from Phase 3 red/green diff
/// and blue provenance. Suggested rewrites are copyable, not auto-applied.
class _FindingCard extends StatelessWidget {
  final GuardianAnnotation annotation;
  final VoidCallback onDismiss;

  const _FindingCard({
    required this.annotation,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: _severityColor(annotation.severity, colorScheme),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: severity + kind + dismiss
            Row(
              children: [
                _SeverityChip(severity: annotation.severity),
                const SizedBox(width: 4),
                _KindChip(kind: annotation.kind),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: '忽略',
                  onPressed: onDismiss,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Message
            Text(
              annotation.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            // Reason
            Text(
              annotation.reason,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // Source text
            if (annotation.sourceText != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${annotation.sourceText}"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
            // Location info
            if (!annotation.hasExactLocation) ...[
              const SizedBox(height: 4),
              Text(
                '未能精确定位',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ],
            // Suggested fix (copyable, never auto-applied)
            if (annotation.suggestedFix != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '建议修改：',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            annotation.suggestedFix!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      tooltip: '复制建议',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: annotation.suggestedFix!),
                        );
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _severityColor(GuardianSeverity severity, ColorScheme cs) {
    return switch (severity) {
      GuardianSeverity.low => cs.surfaceContainerLow,
      GuardianSeverity.medium => cs.surfaceContainerHigh,
      GuardianSeverity.high => cs.surfaceContainerHighest,
    };
  }
}

/// Chip showing the finding severity.
class _SeverityChip extends StatelessWidget {
  final GuardianSeverity severity;

  const _SeverityChip({required this.severity});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (label, color) = switch (severity) {
      GuardianSeverity.low => ('低', colorScheme.outline),
      GuardianSeverity.medium => ('中', const Color(0xFFF59E0B)), // Amber
      GuardianSeverity.high => ('高', const Color(0xFF8B5CF6)), // Violet
    };

    return Chip(
      label: Text(label),
      avatar: Icon(Icons.warning_amber, size: 14, color: color),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Chip showing the finding kind.
class _KindChip extends StatelessWidget {
  final GuardianFindingKind kind;

  const _KindChip({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_kindLabel(kind)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _kindLabel(GuardianFindingKind k) {
    return switch (k) {
      GuardianFindingKind.characterConsistency => '角色一致',
      GuardianFindingKind.timelineContradiction => '时间线',
      GuardianFindingKind.worldRuleConflict => '世界规则',
      GuardianFindingKind.skillRuleConflict => '技能规则',
      GuardianFindingKind.unresolvedForeshadowing => '伏笔风险',
    };
  }
}

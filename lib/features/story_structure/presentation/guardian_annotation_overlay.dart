import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/application/guardian_notifier.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';

/// Editor-side overlay for guardian annotation display.
///
/// Provides a compact panel that can be toggled from the editor.
/// Shows guardian findings with amber/violet advisory styling distinct
/// from Phase 3 red/green diff and blue provenance highlights.
///
/// If exact offsets are unavailable, findings show '未能精确定位'
/// rather than pretending precision per UI-SPEC.
class GuardianAnnotationOverlay extends ConsumerStatefulWidget {
  const GuardianAnnotationOverlay({super.key});

  @override
  ConsumerState<GuardianAnnotationOverlay> createState() =>
      _GuardianAnnotationOverlayState();
}

class _GuardianAnnotationOverlayState
    extends ConsumerState<GuardianAnnotationOverlay> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final guardianAsync = ref.watch(guardianNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return guardianAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (result) {
        final activeAnnotations = result.annotations
            .where((a) => !a.isDismissed)
            .toList();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isExpanded ? 280 : 48,
          height: _isExpanded ? null : 48,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: _isExpanded
              ? _buildExpandedPanel(result, activeAnnotations)
              : _buildCollapsedBadge(activeAnnotations.length),
        );
      },
    );
  }

  Widget _buildCollapsedBadge(int count) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => setState(() => _isExpanded = true),
      borderRadius: BorderRadius.circular(12),
      child: Center(
        child: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: Icon(
            Icons.shield_outlined,
            color: count > 0
                ? const Color(0xFFF59E0B) // Amber for active findings
                : colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPanel(
    GuardianCheckResult result,
    List<GuardianAnnotation> annotations,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, size: 16),
              const SizedBox(width: 4),
              Text(
                '守护 (${annotations.length})',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(() => _isExpanded = false),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Quick check button
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.tonal(
            onPressed: annotations.isEmpty ? null : null, // Placeholder
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            child: const Text('运行检查'),
          ),
        ),
        // Findings list
        if (annotations.isNotEmpty)
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: annotations.length,
              itemBuilder: (context, index) {
                final annotation = annotations[index];
                return _CompactFindingTile(
                  annotation: annotation,
                  onDismiss: () => ref
                      .read(guardianNotifierProvider.notifier)
                      .dismiss(annotation.id),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Compact finding tile for the overlay panel.
class _CompactFindingTile extends StatelessWidget {
  final GuardianAnnotation annotation;
  final VoidCallback onDismiss;

  const _CompactFindingTile({
    required this.annotation,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      leading: Icon(
        _severityIcon(annotation.severity),
        size: 16,
        color: _severityColor(annotation.severity),
      ),
      title: Text(
        annotation.message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      subtitle: annotation.hasExactLocation
          ? null
          : Text(
              '未能精确定位',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
            ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 14),
        onPressed: onDismiss,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  IconData _severityIcon(GuardianSeverity s) {
    return switch (s) {
      GuardianSeverity.low => Icons.info_outline,
      GuardianSeverity.medium => Icons.warning_amber,
      GuardianSeverity.high => Icons.error_outline,
    };
  }

  Color _severityColor(GuardianSeverity s) {
    return switch (s) {
      GuardianSeverity.low => const Color(0xFF9CA3AF),
      GuardianSeverity.medium => const Color(0xFFF59E0B),
      GuardianSeverity.high => const Color(0xFF8B5CF6),
    };
  }
}

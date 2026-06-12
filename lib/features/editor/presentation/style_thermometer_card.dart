/// Inline card showing the AI-scent thermometer score after AI operations.
///
/// Displays a compact score badge with color coding and a tap-to-expand
/// full [StyleThermometerDashboard] in a dialog. Designed to sit below the
/// [DeviationWarningWidget] in the editor area without taking much space.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/editor/application/style_deviation_detector.dart';
import 'package:museflow/features/editor/application/style_deviation_notifier.dart';
import 'package:museflow/features/editor/presentation/style_thermometer_dashboard.dart';

/// Compact inline card that shows AI-scent score with optional expansion.
///
/// When no deviation result is available, renders nothing (SizedBox.shrink).
/// Otherwise shows a compact row with score badge and summary text.
class StyleThermometerCard extends ConsumerWidget {
  const StyleThermometerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviationState = ref.watch(styleDeviationNotifierProvider);
    final result = deviationState.result;

    // Don't render when there's no result
    if (result == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final color = _scoreColor(result.aiScentScore);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _showDashboardDialog(context, result),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${result.aiScentScore}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Summary text
                Expanded(
                  child: Text(
                    result.summary,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Expand hint
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDashboardDialog(BuildContext context, StyleDeviationResult result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('AI痕迹分析'),
        content: SingleChildScrollView(
          child: StyleThermometerDashboard(result: result),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

/// Returns the color for a given AI-scent score.
Color _scoreColor(int score) {
  if (score < 25) return const Color(0xFF4CAF50); // green
  if (score < 50) return const Color(0xFFFFC107); // amber
  if (score < 75) return const Color(0xFFFF9800); // orange
  return const Color(0xFFF44336); // red
}

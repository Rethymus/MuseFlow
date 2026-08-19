/// Status bar showing pending AI modification count and manuscript progress.
///
/// Per D-11: Displays "当前文档有 N 处AI修改待确认" when N > 0.
/// Per D-25: Displays "总字数: {current}/{target} 字" when manuscript
/// context is available.
/// Hidden when no pending modifications exist and no manuscript context.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/theme/app_dimens.dart';

/// Status bar widget that shows manuscript word count progress and
/// pending AI modification count.
///
/// When [currentWordCount] and [targetWordCount] are provided, displays
/// manuscript progress. When there are pending AI diffs, shows the count.
/// Hidden when neither condition is met.
class StatusBar extends ConsumerWidget {
  const StatusBar({super.key, this.currentWordCount, this.targetWordCount});

  /// Total word count across all chapters in the current manuscript.
  /// When null, manuscript progress is not displayed.
  final int? currentWordCount;

  /// Target word count for the current manuscript.
  /// When null, manuscript progress is not displayed.
  final int? targetWordCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(editorAINotifierProvider);
    final diffResult = aiState.diffResult;
    final hasPendingDiffs = diffResult != null && !diffResult.allResolved;
    final reviewSignals = aiState.reviewSignals;
    final hasReviewSignals = reviewSignals.isNotEmpty;
    final hasManuscriptContext =
        currentWordCount != null && targetWordCount != null;

    // Hide when no diff and no manuscript context
    if (!hasPendingDiffs && !hasManuscriptContext && !hasReviewSignals) {
      return const SizedBox.shrink();
    }

    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.tertiaryGroupedBackground,
        border: Border(
          top: BorderSide(color: p.separator, width: AppRadius.hairline),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          if (hasManuscriptContext) ...[
            Text(
              '总字数: ${_formatNumber(currentWordCount!)}/${_formatNumber(targetWordCount!)} 字',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: p.secondaryLabel,
              ),
            ),
            if (hasPendingDiffs)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '|',
                  style: textTheme.labelMedium?.copyWith(
                    color: p.tertiaryLabel,
                  ),
                ),
              ),
            if (hasPendingDiffs)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '${diffResult.pendingCount} 处AI修改待确认',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: p.secondaryLabel,
                  ),
                ),
              ),
          ] else if (hasPendingDiffs) ...[
            Text(
              '当前文档有 ${diffResult.pendingCount} 处AI修改待确认',
              style: textTheme.bodySmall?.copyWith(color: p.secondaryLabel),
            ),
          ],
          if ((hasManuscriptContext || hasPendingDiffs) &&
              hasReviewSignals) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                '|',
                style: textTheme.labelMedium?.copyWith(color: p.tertiaryLabel),
              ),
            ),
          ],
          if (hasReviewSignals)
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(
                  left: hasManuscriptContext || hasPendingDiffs ? 16 : 0,
                ),
                child: _ReviewSignalSummary(signals: reviewSignals),
              ),
            ),
        ],
      ),
    );
  }

  /// Formats a number with comma separators for readability.
  String _formatNumber(int n) {
    if (n < 1000) return '$n';
    final parts = <String>[];
    var remaining = n;
    while (remaining > 0) {
      final chunk = remaining % 1000;
      remaining ~/= 1000;
      if (remaining > 0) {
        parts.add(chunk.toString().padLeft(3, '0'));
      } else {
        parts.add(chunk.toString());
      }
    }
    return parts.reversed.join(',');
  }
}

class _ReviewSignalSummary extends StatelessWidget {
  const _ReviewSignalSummary({required this.signals});

  final List<ReviewSignal> signals;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final primarySignal = _highestSeveritySignal(signals);
    final color = switch (primarySignal.severity) {
      ReviewSignalSeverity.high => p.systemRed,
      ReviewSignalSeverity.medium => p.systemOrange,
      ReviewSignalSeverity.low => p.secondaryLabel,
    };

    return Tooltip(
      message: '${primarySignal.description}（${primarySignal.evidence}）',
      child: Text(
        '${signals.length} 条AI修改复查：${primarySignal.title}',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  ReviewSignal _highestSeveritySignal(List<ReviewSignal> signals) {
    final sorted = [...signals]
      ..sort(
        (a, b) =>
            _severityRank(b.severity).compareTo(_severityRank(a.severity)),
      );
    return sorted.first;
  }

  int _severityRank(ReviewSignalSeverity severity) {
    return switch (severity) {
      ReviewSignalSeverity.high => 3,
      ReviewSignalSeverity.medium => 2,
      ReviewSignalSeverity.low => 1,
    };
  }
}

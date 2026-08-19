/// Slide-out synthesis panel for AI-assisted fragment-to-paragraph flow.
///
/// Per D-05: Slides out from the right side of the capture page as an
/// overlay panel (not a page navigation). Layout:
/// 1. Header: title + close button
/// 2. Excluded fragments notice (yellow banner per D-13)
/// 3. Streaming/editable text area
/// 4. Inline error messages with retry per D-14
/// 5. Bottom action bar: regenerate + confirm insert
library;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/features/ai/presentation/synthesis_notifier.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/theme/app_dimens.dart';

/// Width of the synthesis panel on desktop.
const double _panelWidth = 400.0;

/// Duration for panel slide animation.
const Duration _animDuration = Duration(milliseconds: 250);

/// Slide-out synthesis panel overlaying the right side of the capture page.
///
/// State is driven entirely by [SynthesisNotifier] via ref.watch(synthesisProvider).
/// Per CAPT-04: After stream completes, text is editable before insertion.
/// Per D-06: "Regenerate" button with optional additional instruction field.
/// Per D-07: "Confirm insert" places text in editor at cursor.
class SynthesisPanel extends ConsumerStatefulWidget {
  const SynthesisPanel({super.key});

  @override
  ConsumerState<SynthesisPanel> createState() => _SynthesisPanelState();
}

class _SynthesisPanelState extends ConsumerState<SynthesisPanel> {
  late final TextEditingController _editController;
  late final FocusNode _editFocusNode;
  final _additionalInstructionController = TextEditingController();
  bool _isTextDirty = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
    _editFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocusNode.dispose();
    _additionalInstructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final synthesisState = ref.watch(synthesisProvider);
    final theme = Theme.of(context);
    final p = AppColors.of(context);

    // Sync text controller when streaming completes or regenerates
    if (!synthesisState.isStreaming && !_isTextDirty) {
      if (_editController.text != synthesisState.accumulatedText) {
        _editController.text = synthesisState.accumulatedText;
      }
    }

    return AnimatedContainer(
      duration: _animDuration,
      curve: Curves.easeOutCubic,
      width: _panelWidth,
      decoration: BoxDecoration(
        color: p.cardBackground,
        border: Border(
          left: BorderSide(color: p.separator, width: AppRadius.hairline),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(context, p),

          // Excluded fragments notice per D-13
          if (synthesisState.excludedFragmentsNotice != null)
            _buildExcludedNotice(
              context,
              synthesisState.excludedFragmentsNotice!,
              p,
            ),

          // Main content area
          Expanded(child: _buildContentArea(context, synthesisState, p, theme)),

          // Error display per D-14
          if (synthesisState.error != null)
            _buildErrorBanner(context, synthesisState.error!, p),

          // Bottom action bar
          _buildActionBar(context, synthesisState, p),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: p.separator, width: AppRadius.hairline),
        ),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.sparkles, size: 20, color: p.accent),
          const SizedBox(width: 8),
          Text(
            'AI 整理',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(CupertinoIcons.xmark, size: 18),
            onPressed: _closePanel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  Widget _buildExcludedNotice(
    BuildContext context,
    String notice,
    AppPalette p,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: p.systemOrange.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(CupertinoIcons.info_circle, size: 16, color: p.systemOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notice,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: p.systemOrange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(
    BuildContext context,
    SynthesisState state,
    AppPalette p,
    ThemeData theme,
  ) {
    if (state.isStreaming && state.accumulatedText.isEmpty) {
      // Loading state before first token
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
            ),
            const SizedBox(height: 12),
            Text(
              'AI 正在思考...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: p.secondaryLabel,
              ),
            ),
          ],
        ),
      );
    }

    if (state.isStreaming) {
      // Streaming display with typewriter effect per D-15
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: _buildStreamingText(state.accumulatedText, theme, p),
        ),
      );
    }

    if (state.isEditing || state.accumulatedText.isNotEmpty) {
      // Editable text area per CAPT-04, with an optional anti-AI-scent
      // review summary above it (SY-01, mirrors the editor flow's status bar).
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.reviewSignals.isNotEmpty) ...[
              _SynthesisReviewSummary(signals: state.reviewSignals),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: TextField(
                controller: _editController,
                focusNode: _editFocusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'AI 生成的文本将显示在这里...',
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: (text) {
                  _isTextDirty = true;
                  ref.read(synthesisProvider.notifier).updateText(text);
                },
              ),
            ),
          ],
        ),
      );
    }

    // Idle state
    return Center(
      child: Text(
        '选择碎片后点击 "AI 整理" 开始',
        style: theme.textTheme.bodyMedium?.copyWith(color: p.secondaryLabel),
      ),
    );
  }

  Widget _buildStreamingText(String text, ThemeData theme, AppPalette p) {
    // Simple streaming display with blinking cursor effect
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: theme.textTheme.bodyLarge?.copyWith(color: p.label),
          ),
          // Blinking cursor during streaming
          WidgetSpan(child: _BlinkingCursor(accent: p.accent)),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error, AppPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: p.systemRed.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 16,
            color: p.systemRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: p.systemRed),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(synthesisProvider.notifier).regenerate(null);
              _isTextDirty = false;
            },
            style: TextButton.styleFrom(
              foregroundColor: p.systemRed,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    SynthesisState state,
    AppPalette p,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: p.separator, width: AppRadius.hairline),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Additional instruction field per D-06
          TextField(
            controller: _additionalInstructionController,
            decoration: const InputDecoration(
              hintText: '追加指令（可选）',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Regenerate button per D-06
              OutlinedButton.icon(
                onPressed: state.isStreaming
                    ? null
                    : () {
                        final instruction = _additionalInstructionController
                            .text
                            .trim();
                        ref
                            .read(synthesisProvider.notifier)
                            .regenerate(
                              instruction.isEmpty ? null : instruction,
                            );
                        _isTextDirty = false;
                      },
                icon: const Icon(CupertinoIcons.arrow_clockwise, size: 16),
                label: const Text('重新生成'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const Spacer(),
              // Confirm insert button per D-07
              FilledButton.icon(
                onPressed:
                    (!state.isEditing && state.isStreaming) ||
                        state.accumulatedText.isEmpty
                    ? null
                    : () {
                        ref.read(synthesisProvider.notifier).confirmAndInsert();
                        _isTextDirty = false;
                        _additionalInstructionController.clear();
                        // Navigate to editor page per D-07
                        if (context.mounted) {
                          context.go(AppConstants.editor);
                        }
                      },
                icon: const Icon(CupertinoIcons.checkmark, size: 16),
                label: const Text('确认插入'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _closePanel() {
    ref.read(synthesisProvider.notifier).reset();
    _isTextDirty = false;
    _additionalInstructionController.clear();
  }
}

/// Anti-AI-scent review summary for the synthesis panel (SY-01).
///
/// Mirrors the editor status bar's review-signal rendering: shows the count
/// of signals and leads with the highest-severity one, colored by severity.
/// Rendered only when [SynthesisState.reviewSignals] is non-empty, so clean
/// synthesized text produces no noise.
class _SynthesisReviewSummary extends StatelessWidget {
  const _SynthesisReviewSummary({required this.signals});

  final List<ReviewSignal> signals;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final primary = _highestSeverity(signals);
    final color = switch (primary.severity) {
      ReviewSignalSeverity.high => p.systemRed,
      ReviewSignalSeverity.medium => p.systemOrange,
      ReviewSignalSeverity.low => p.gray,
    };

    return Tooltip(
      message: '${primary.description}（${primary.evidence}）',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.rSmall,
        ),
        child: Text(
          '${signals.length} 条AI修改复查：${primary.title}',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  ReviewSignal _highestSeverity(List<ReviewSignal> signals) {
    final sorted = [...signals]
      ..sort((a, b) => _rank(b.severity).compareTo(_rank(a.severity)));
    return sorted.first;
  }

  int _rank(ReviewSignalSeverity severity) => switch (severity) {
    ReviewSignalSeverity.high => 3,
    ReviewSignalSeverity.medium => 2,
    ReviewSignalSeverity.low => 1,
  };
}

/// Blinking cursor widget for streaming text display.
class _BlinkingCursor extends StatefulWidget {
  final Color accent;

  const _BlinkingCursor({required this.accent});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(
        '|',
        style: TextStyle(color: widget.accent, fontWeight: FontWeight.bold),
      ),
    );
  }
}

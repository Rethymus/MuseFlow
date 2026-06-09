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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/features/ai/presentation/synthesis_notifier.dart';
import 'package:museflow/shared/constants/app_constants.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

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
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant, width: 1),
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
          _buildHeader(context, colorScheme),

          // Excluded fragments notice per D-13
          if (synthesisState.excludedFragmentsNotice != null)
            _buildExcludedNotice(
              context,
              synthesisState.excludedFragmentsNotice!,
              colorScheme,
            ),

          // Main content area
          Expanded(
            child: _buildContentArea(
              context,
              synthesisState,
              colorScheme,
              theme,
            ),
          ),

          // Error display per D-14
          if (synthesisState.error != null)
            _buildErrorBanner(context, synthesisState.error!, colorScheme),

          // Bottom action bar
          _buildActionBar(context, synthesisState, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'AI 整理',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
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
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.tertiaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notice,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(
    BuildContext context,
    SynthesisState state,
    ColorScheme colorScheme,
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI 正在思考...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
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
          child: _buildStreamingText(state.accumulatedText, theme, colorScheme),
        ),
      );
    }

    if (state.isEditing || state.accumulatedText.isNotEmpty) {
      // Editable text area per CAPT-04
      return Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _editController,
          focusNode: _editFocusNode,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'AI 生成的文本将显示在这里...',
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (text) {
            _isTextDirty = true;
            ref.read(synthesisProvider.notifier).updateText(text);
          },
        ),
      );
    }

    // Idle state
    return Center(
      child: Text(
        '选择碎片后点击 "AI 整理" 开始',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildStreamingText(
    String text,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Simple streaming display with blinking cursor effect
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          // Blinking cursor during streaming
          WidgetSpan(child: _BlinkingCursor(colorScheme: colorScheme)),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
    BuildContext context,
    String error,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(synthesisProvider.notifier).regenerate(null);
              _isTextDirty = false;
            },
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
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
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Additional instruction field per D-06
          TextField(
            controller: _additionalInstructionController,
            decoration: InputDecoration(
              hintText: '追加指令（可选）',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: const TextStyle(fontSize: 13),
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
                icon: const Icon(Icons.refresh, size: 16),
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
                icon: const Icon(Icons.check, size: 16),
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

/// Blinking cursor widget for streaming text display.
class _BlinkingCursor extends StatefulWidget {
  final ColorScheme colorScheme;

  const _BlinkingCursor({required this.colorScheme});

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
        style: TextStyle(
          color: widget.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

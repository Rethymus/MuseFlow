import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/domain/fragment_tag.dart';
import 'package:museflow/features/ai/presentation/synthesis_notifier.dart';
import 'package:museflow/features/ai/presentation/synthesis_panel.dart';
import 'package:museflow/features/capture/presentation/capture_provider.dart';
import 'package:museflow/features/capture/presentation/fragment_card.dart';

/// Capture page for fragment bullet-note workspace.
///
/// Per UI-SPEC Capture Page Layout:
/// - Top: always-visible input field (per D-09: zero clicks to start)
/// - Filter chips: 全部/故事/章节/场景
/// - Fragment list: ListView.builder with FragmentCard items
/// - Empty state when no fragments
/// - All UI copy in Chinese per UI-SPEC copywriting contract
class CapturePage extends ConsumerStatefulWidget {
  const CapturePage({super.key});

  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    // Sync provider → controller (one-way: provider is source of truth)
    ref.listenManual(captureInputProvider, (previous, next) {
      if (_textController.text != next) {
        _textController.text = next;
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSubmit(String text) {
    if (text.trim().isNotEmpty) {
      ref.read(captureProvider.notifier).addFragment(text.trim());
      ref.read(captureInputProvider.notifier).clear();
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureProvider);
    final synthesisState = ref.watch(synthesisProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Panel is visible when synthesis is active
    final showPanel =
        synthesisState.isStreaming ||
        synthesisState.isEditing ||
        synthesisState.error != null;

    return Stack(
      children: [
        // Base layer: capture page content
        Column(
          children: [
            // Error banner
            if (captureState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: colorScheme.errorContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        captureState.error!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: colorScheme.onErrorContainer,
                      ),
                      onPressed: () =>
                          ref.read(captureProvider.notifier).clearError(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Input field (per D-09: always visible, zero clicks to start)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: '输入灵感碎片，按回车添加...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
                onSubmitted: _handleSubmit,
                onChanged: (text) {
                  ref.read(captureInputProvider.notifier).update(text);
                },
              ),
            ),

            // Filter chips row + AI synthesis button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip(
                          context: context,
                          label: '全部',
                          isActive: captureState.activeFilter == '全部',
                        ),
                        ...FragmentTags.defaults.map(
                          (tag) => _buildFilterChip(
                            context: context,
                            label: tag,
                            isActive: captureState.activeFilter == tag,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // AI synthesis trigger button -- visible when >= 1 fragment selected
                  if (captureState.selectedIds.isNotEmpty && !showPanel)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          ref.read(synthesisProvider.notifier).startSynthesis();
                        },
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('AI 整理'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Fragment list or empty state
            Expanded(child: _buildFragmentList(context, captureState)),
          ],
        ),

        // Overlay layer: synthesis panel slides out from right
        if (showPanel)
          Positioned(top: 0, right: 0, bottom: 0, child: SynthesisPanel()),
      ],
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isActive,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) {
        ref.read(captureProvider.notifier).setFilter(label);
      },
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
    );
  }

  Widget _buildFragmentList(BuildContext context, CaptureState captureState) {
    if (captureState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (captureState.fragments.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: captureState.fragments.length,
      itemBuilder: (context, index) {
        final fragment = captureState.fragments[index];
        final isSelected = captureState.selectedIds.contains(fragment.id);

        return FragmentCard(
          fragment: fragment,
          isSelected: isSelected,
          onToggleSelect: () {
            ref.read(captureProvider.notifier).toggleSelect(fragment.id);
          },
        );
      },
    );
  }

  /// Empty state per UI-SPEC copywriting contract.
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_outline,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有灵感碎片',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在上方输入框中写下你的第一个灵感，按回车即可保存。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

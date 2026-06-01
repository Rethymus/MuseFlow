import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/domain/fragment_tag.dart';
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
class CapturePage extends ConsumerWidget {
  const CapturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureState = ref.watch(captureProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Input field (per D-09: always visible, zero clicks to start)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
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
            onSubmitted: (text) {
              if (text.trim().isNotEmpty) {
                ref.read(captureProvider.notifier).addFragment(text.trim());
                ref.read(captureInputProvider.notifier).clear();
              }
            },
            onChanged: (text) {
              ref.read(captureInputProvider.notifier).update(text);
            },
          ),
        ),

        // Filter chips row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                context: context,
                ref: ref,
                label: '全部',
                isActive: captureState.activeFilter == '全部',
              ),
              ...FragmentTags.defaults.map((tag) => _buildFilterChip(
                    context: context,
                    ref: ref,
                    label: tag,
                    isActive: captureState.activeFilter == tag,
                  )),
            ],
          ),
        ),

        const Divider(height: 1),

        // Fragment list or empty state
        Expanded(
          child: _buildFragmentList(context, ref, captureState),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required WidgetRef ref,
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

  Widget _buildFragmentList(
    BuildContext context,
    WidgetRef ref,
    CaptureState captureState,
  ) {
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

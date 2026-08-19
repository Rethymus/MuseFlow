/// Banned phrase settings page per D-09.
///
/// Shows the user's editable banned phrase list for anti-AI-scent processing.
/// Users can add and remove phrases. On first access, the list is seeded
/// from [AntiAIScentProcessor]'s built-in synonym map keys.
library;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/theme/app_dimens.dart';

/// Provider exposing the user's banned phrase list from settings.
///
/// On first access, initializes with the seed list from AntiAIScentProcessor.
/// The list is stored under the 'banned_phrases' key in SettingsRepository.
final bannedPhrasesProvider =
    NotifierProvider<BannedPhrasesNotifier, AsyncValue<List<String>>>(
      BannedPhrasesNotifier.new,
    );

/// Notifier managing the banned phrase list lifecycle.
class BannedPhrasesNotifier extends Notifier<AsyncValue<List<String>>> {
  @override
  AsyncValue<List<String>> build() {
    _loadPhrases();
    return const AsyncValue.loading();
  }

  Future<void> _loadPhrases() async {
    state = const AsyncValue.loading();
    try {
      final settingsAsync = ref.read(settingsRepositoryProvider);
      final settings = settingsAsync.value;
      if (settings == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final stored = settings.getBannedPhrases();
      if (stored != null) {
        state = AsyncValue.data(List.unmodifiable(stored));
      } else {
        // First access -- seed with built-in synonym map keys
        final seed = AntiAIScentProcessor.synonymKeys;
        await settings.saveBannedPhrases(seed);
        state = AsyncValue.data(List.unmodifiable(seed));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Adds a new banned phrase. Does nothing if already present or empty.
  Future<void> addPhrase(String phrase) async {
    final trimmed = phrase.trim();
    if (trimmed.isEmpty) return;

    final current = state.asData?.value ?? [];
    if (current.contains(trimmed)) return;

    final updated = [...current, trimmed];
    await _saveToStorage(updated);
    state = AsyncValue.data(List.unmodifiable(updated));
  }

  /// Removes a banned phrase at the given index.
  Future<void> removePhrase(int index) async {
    final current = state.asData?.value ?? [];
    if (index < 0 || index >= current.length) return;

    final updated = [...current]..removeAt(index);
    await _saveToStorage(updated);
    state = AsyncValue.data(List.unmodifiable(updated));
  }

  Future<void> _saveToStorage(List<String> phrases) async {
    final settingsAsync = ref.read(settingsRepositoryProvider);
    final settings = settingsAsync.asData?.value;
    if (settings != null) {
      await settings.saveBannedPhrases(phrases);
    }
  }
}

/// Settings page for editing the banned phrase list.
///
/// Per D-09: Users can add and remove phrases that trigger auto-replacement
/// during anti-AI-scent post-processing.
class BannedPhraseSettingsPage extends ConsumerWidget {
  const BannedPhraseSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phrasesAsync = ref.watch(bannedPhrasesProvider);
    final theme = Theme.of(context);
    final p = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('AI 用语过滤', style: theme.textTheme.displayMedium),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: phrasesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('加载失败: $err', style: TextStyle(color: p.systemRed)),
        ),
        data: (phrases) => _buildPhraseList(context, ref, phrases, theme, p),
      ),
    );
  }

  Widget _buildPhraseList(
    BuildContext context,
    WidgetRef ref,
    List<String> phrases,
    ThemeData theme,
    AppPalette p,
  ) {
    return Column(
      children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: p.tertiaryGroupedBackground,
          child: Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                size: 18,
                color: p.secondaryLabel,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '这些词组在 AI 生成文本后会自动被替换或删除，以减少 AI 痕迹。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: p.secondaryLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Phrase list: inset grouped card with hairline separators
        Expanded(
          child: phrases.isEmpty
              ? Center(
                  child: Text(
                    '暂无过滤词组',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: p.secondaryLabel,
                    ),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.groupMargin,
                  ),
                  decoration: BoxDecoration(
                    color: p.cardBackground,
                    borderRadius: AppRadius.rMedium,
                  ),
                  child: ListView.separated(
                    itemCount: phrases.length,
                    separatorBuilder: (_, _) => Divider(
                      height: AppRadius.hairline,
                      thickness: AppRadius.hairline,
                      indent: 16,
                      color: p.separator,
                    ),
                    itemBuilder: (context, index) {
                      final phrase = phrases[index];
                      return ListTile(
                        dense: true,
                        title: Text(phrase),
                        trailing: IconButton(
                          icon: Icon(
                            CupertinoIcons.trash,
                            size: 20,
                            color: p.systemRed,
                          ),
                          tooltip: '删除',
                          onPressed: () {
                            ref
                                .read(bannedPhrasesProvider.notifier)
                                .removePhrase(index);
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
        // Add phrase section
        Divider(height: 1, color: p.separator),
        _AddPhraseSection(),
      ],
    );
  }
}

/// Section at the bottom for adding a new banned phrase.
class _AddPhraseSection extends ConsumerStatefulWidget {
  const _AddPhraseSection();

  @override
  ConsumerState<_AddPhraseSection> createState() => _AddPhraseSectionState();
}

class _AddPhraseSectionState extends ConsumerState<_AddPhraseSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '输入要过滤的词组',
                isDense: true,
              ),
              onSubmitted: _addPhrase,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => _addPhrase(_controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _addPhrase(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    ref.read(bannedPhrasesProvider.notifier).addPhrase(trimmed);
    _controller.clear();
  }
}

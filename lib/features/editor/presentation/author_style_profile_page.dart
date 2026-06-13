/// Author style profile page — displays 5-dimension style analysis results.
///
/// Shows the author's quantified writing style across:
/// - Sentence length distribution (句式特征)
/// - Rhythm/burstiness (节奏模式)
/// - Vocabulary richness (词汇特征)
/// - Rhetoric habits (修辞习惯)
/// - Emotional tone (情感基调)
///
/// Also displays extracted style samples and provides controls to trigger
/// re-analysis.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/editor/application/style_profile_notifier.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/editor/domain/style_dimension.dart';
import 'package:museflow/features/editor/domain/style_sample.dart';
import 'package:museflow/shared/constants/app_constants.dart';

/// Page displaying the author's style profile analysis.
class AuthorStyleProfilePage extends ConsumerStatefulWidget {
  const AuthorStyleProfilePage({super.key, required this.manuscriptId});

  final String manuscriptId;

  @override
  ConsumerState<AuthorStyleProfilePage> createState() =>
      _AuthorStyleProfilePageState();
}

class _AuthorStyleProfilePageState
    extends ConsumerState<AuthorStyleProfilePage> {
  @override
  void initState() {
    super.initState();
    // Auto-load saved profile when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(styleProfileNotifierProvider.notifier)
          .loadProfile(widget.manuscriptId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(styleProfileNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('作者风格档案'),
        leading: IconButton(
          tooltip: '返回',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(
            AppConstants.manuscriptEditor.replaceFirst(
              ':id',
              widget.manuscriptId,
            ),
          ),
        ),
        actions: [
          if (state.profile != null && state.profile!.hasData)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重新分析',
              onPressed: () => _triggerAnalysis,
            ),
        ],
      ),
      body: _buildBody(context, state, theme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    StyleProfileState state,
    ThemeData theme,
  ) {
    if (state.isAnalyzing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在分析写作风格…'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _triggerAnalysis,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.profile == null || !state.profile!.hasData) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('尚未分析写作风格', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '需要至少2章、500字以上的内容才能分析',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _triggerAnalysis,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('开始分析'),
            ),
          ],
        ),
      );
    }

    final profile = state.profile!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overview card
        _OverviewCard(profile: profile),
        const SizedBox(height: 16),

        // Dimension cards
        ...StyleDimension.values.map(
          (dim) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DimensionCard(dimension: dim, profile: profile),
          ),
        ),
        const SizedBox(height: 16),

        // Style samples
        if (profile.sampleParagraphs.isNotEmpty) ...[
          Text('风格范例', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...profile.sampleParagraphs.map(
            (sample) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SampleCard(sample: sample),
            ),
          ),
        ],
      ],
    );
  }

  void _triggerAnalysis() {
    // Get chapters for the current manuscript and trigger analysis
    final chaptersAsync = ref.read(
      chapterNotifierProvider,
    ); // chapters may already be loaded
    final chapters = chaptersAsync.asData?.value ?? [];
    if (chapters.isEmpty) {
      // Try loading chapters first
      ref
          .read(chapterNotifierProvider.notifier)
          .loadChapters(widget.manuscriptId);
      // Retry after a short delay to allow loading
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final loaded = ref.read(chapterNotifierProvider).asData?.value ?? [];
        if (loaded.isNotEmpty) {
          ref
              .read(styleProfileNotifierProvider.notifier)
              .analyzeManuscript(
                manuscriptId: widget.manuscriptId,
                chapters: loaded,
              );
        }
      });
      return;
    }
    ref
        .read(styleProfileNotifierProvider.notifier)
        .analyzeManuscript(
          manuscriptId: widget.manuscriptId,
          chapters: chapters,
        );
  }
}

/// Overview card showing analysis metadata and emotional tone summary.
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.profile});

  final AuthorStyleProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('分析概览', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.description,
              label: '已分析章节',
              value: '${profile.analyzedChapterCount} 章',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.text_fields,
              label: '分析字数',
              value: '${profile.analyzedCharCount} 字',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.schedule,
              label: '最后更新',
              value: _formatDate(profile.lastAnalyzedAt),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.palette, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '情感基调：${profile.emotionalTone.overall}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}-${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Row displaying an info item with icon.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Card showing a single style dimension with a progress bar.
class _DimensionCard extends StatelessWidget {
  const _DimensionCard({required this.dimension, required this.profile});

  final StyleDimension dimension;
  final AuthorStyleProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = _getDimensionScore(profile, dimension);
    final interpretation = dimension.interpret(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(dimension.label, style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${(score * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(_scoreColor(score, theme)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              interpretation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_hasExtraDetail(dimension)) ...[
              const SizedBox(height: 4),
              Text(
                _getExtraDetail(profile, dimension),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _getDimensionScore(AuthorStyleProfile profile, StyleDimension dim) {
    return switch (dim) {
      StyleDimension.sentenceLength => _normalizeSentenceLength(profile),
      StyleDimension.rhythm => profile.rhythmScore,
      StyleDimension.vocabulary => profile.vocabularyRichness,
      StyleDimension.rhetoric => _normalizeRhetoric(profile),
      StyleDimension.emotionalTone => profile.emotionalTone.intensity,
    };
  }

  double _normalizeSentenceLength(AuthorStyleProfile profile) {
    final avg = profile.sentenceLengthStats.avg;
    if (avg == 0) return 0.5;
    // Normalize: avg 10 → 0.8 (short), avg 25 → 0.5 (medium), avg 40+ → 0.2 (long)
    return ((40 - avg) / 30).clamp(0.0, 1.0);
  }

  double _normalizeRhetoric(AuthorStyleProfile profile) {
    final h = profile.rhetoricHabits;
    // Diversity score: how balanced are the four ratios
    final ratios = [
      h.dialogueRatio,
      h.descriptionRatio,
      h.actionRatio,
      h.metaphorFrequency,
    ];
    final maxRatio = ratios.reduce((a, b) => a > b ? a : b);
    final sum = ratios.reduce((a, b) => a + b);
    return sum > 0 ? (maxRatio * 3).clamp(0.0, 1.0) : 0.3;
  }

  Color _scoreColor(double score, ThemeData theme) {
    if (score < 0.3) return theme.colorScheme.error;
    if (score < 0.6) return theme.colorScheme.primary;
    return theme.colorScheme.tertiary;
  }

  bool _hasExtraDetail(StyleDimension dim) {
    return dim == StyleDimension.sentenceLength ||
        dim == StyleDimension.rhetoric;
  }

  String _getExtraDetail(AuthorStyleProfile profile, StyleDimension dim) {
    if (dim == StyleDimension.sentenceLength) {
      final s = profile.sentenceLengthStats;
      if (s.avg == 0) return '';
      return '平均句长 ${s.avg.toStringAsFixed(1)} 字 · '
          '标准差 ${s.stdDev.toStringAsFixed(1)} · '
          '短句 ${((s.shortRatio) * 100).toStringAsFixed(0)}% · '
          '长句 ${((s.longRatio) * 100).toStringAsFixed(0)}%';
    }
    if (dim == StyleDimension.rhetoric) {
      final h = profile.rhetoricHabits;
      return '对话 ${(h.dialogueRatio * 100).toStringAsFixed(0)}% · '
          '描写 ${(h.descriptionRatio * 100).toStringAsFixed(0)}% · '
          '动作 ${(h.actionRatio * 100).toStringAsFixed(0)}% · '
          '比喻 ${(h.metaphorFrequency * 100).toStringAsFixed(0)}%';
    }
    return '';
  }
}

/// Card displaying a style sample paragraph.
class _SampleCard extends StatelessWidget {
  const _SampleCard({required this.sample});

  final StyleSample sample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_quote,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '质量评分 ${(sample.qualityScore * 100).toStringAsFixed(0)}',
                  style: theme.textTheme.labelSmall,
                ),
                const Spacer(),
                if (sample.dimensionScores.isNotEmpty)
                  ...sample.dimensionScores.entries
                      .where((e) => e.value > 0.6)
                      .take(2)
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Chip(
                            label: Text(e.key.label),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              sample.text,
              style: theme.textTheme.bodySmall,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Editorial review panel page — 4-dimension advisory critique (情节/人物/文笔/
/// 节奏). Advisory only: never rewrites prose.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/reports/domain/editorial_review.dart';
import 'package:museflow/features/reports/providers.dart';

class EditorialReviewPage extends ConsumerStatefulWidget {
  const EditorialReviewPage({super.key});

  @override
  ConsumerState<EditorialReviewPage> createState() =>
      _EditorialReviewPageState();
}

class _EditorialReviewPageState extends ConsumerState<EditorialReviewPage> {
  List<Chapter>? _chapters;
  Chapter? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    try {
      final repo = await ref.read(chapterRepositoryProvider.future);
      final chapters = repo.getAll()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _selected = chapters.isNotEmpty ? chapters.first : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _runReview() async {
    final chapter = _selected;
    if (chapter == null) return;
    await ref
        .read(editorialReviewProvider.notifier)
        .review(
          chapter.documentContent,
          manuscriptId: chapter.manuscriptId,
          chapterId: chapter.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviewAsync = ref.watch(editorialReviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('编辑评审团')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_chapters == null || _chapters!.isEmpty)
          ? _empty(theme)
          : Column(
              children: [
                _selector(),
                const Divider(height: 1),
                Expanded(
                  child: reviewAsync.when(
                    data: (review) => review == null
                        ? _hint(theme)
                        : _ReviewBody(review: review),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('评审失败：$e')),
                  ),
                ),
              ],
            ),
      floatingActionButton: (_selected != null && !_loading)
          ? FloatingActionButton.extended(
              onPressed: reviewAsync.isLoading ? null : _runReview,
              icon: const Icon(Icons.rate_review),
              label: const Text('开始评审'),
            )
          : null,
    );
  }

  Widget _empty(ThemeData theme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        '暂无章节。先创建一部作品和章节，再来获取编辑评审。',
        style: theme.textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _hint(ThemeData theme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            '选择一个章节，点击「开始评审」。\nAI 将从情节、人物、文笔、节奏四个维度给出建议（不重写正文）。',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _selector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: DropdownMenu<Chapter>(
        initialSelection: _selected,
        label: const Text('选择章节'),
        onSelected: (v) => setState(() {
          _selected = v;
          ref.read(editorialReviewProvider.notifier).reset();
        }),
        dropdownMenuEntries: _chapters!
            .map(
              (c) => DropdownMenuEntry<Chapter>(
                value: c,
                label: '${c.title}（${c.wordCount}字）',
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.review});
  final EditorialReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (review.isDegraded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            review.degradedReason ?? '评审不可用',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.insights),
            title: const Text('综合评分'),
            trailing: _ScoreChip(score: review.overallScore, large: true),
          ),
        ),
        const SizedBox(height: 8),
        ...review.dimensions.map((d) => _DimensionCard(review: d)),
        const SizedBox(height: 72),
      ],
    );
  }
}

class _DimensionCard extends StatelessWidget {
  const _DimensionCard({required this.review});
  final DimensionReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  review.dimension.label,
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                _ScoreChip(score: review.score),
              ],
            ),
            const SizedBox(height: 8),
            _line(
              Icons.check_circle_outline,
              '优点',
              review.strengths,
              Colors.green,
            ),
            _line(Icons.error_outline, '不足', review.weaknesses, Colors.orange),
            _line(
              Icons.lightbulb_outline,
              '建议',
              review.suggestions,
              theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String label, String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text('$label：$text')),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score, this.large = false});
  final int score;
  final bool large;

  Color _color() {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightBlue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: large ? 20 : 14,
        ),
      ),
    );
  }
}

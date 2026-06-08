import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/reports/application/report_export_service.dart';
import 'package:museflow/features/reports/domain/blind_read_result.dart';
import 'package:museflow/features/reports/providers.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';

class BlindReadPage extends ConsumerWidget {
  const BlindReadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blindReadProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('反AI味评估'),
        actions: [
          if (state.result != null)
            IconButton(
              tooltip: '导出结果',
              icon: const Icon(Icons.download_outlined),
              onPressed: () => _exportResult(context, state.result!),
            ),
        ],
      ),
      body: state.isComplete
          ? _ResultView(result: state.result!)
          : state.hasStarted
              ? _EvaluationView(state: state)
              : const _InitialView(),
    );
  }

  Future<void> _exportResult(BuildContext context, BlindReadResult result) async {
    final markdown = const ReportExportService().buildBlindReadMarkdown(result);
    const path = 'anti-ai-scent-report.md';
    await ExportService.dartFileWriter(path, markdown);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('报告已导出至: anti-ai-scent-report.md')),
    );
  }
}

class _InitialView extends ConsumerWidget {
  const _InitialView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('需要先完成章节创作才能进行盲读测试。'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(blindReadProvider.notifier).startEvaluation(),
                child: const Text('开始盲读'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvaluationView extends ConsumerWidget {
  const _EvaluationView({required this.state});

  final BlindReadState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final excerpt = state.currentExcerpt;
    if (excerpt == null) return const Center(child: Text('需要先完成章节创作才能进行盲读测试。'));
    final progress = state.excerpts.isEmpty ? 0.0 : state.currentIndex / state.excerpts.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('下方段落来自你的100章创作。请逐段判断：这是 AI 生成的，还是人写的？'),
        ),
        LinearProgressIndicator(value: progress),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Text(
            '第 ${state.currentIndex + 1} / ${state.excerpts.length} 段',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('第${excerpt.chapterIndex}章', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        excerpt.text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () => ref.read(blindReadProvider.notifier).judgeExcerpt(true),
                child: const Text('AI 生成'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => ref.read(blindReadProvider.notifier).judgeExcerpt(false),
                child: const Text('人写的'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => ref.read(blindReadProvider.notifier).skipExcerpt(),
                child: const Text('跳过'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.result});

  final BlindReadResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = result.score;
    final interpretation = score < 0.4
        ? 'AI 内容自然度高，难以分辨。'
        : score <= 0.7
            ? 'AI 内容有一定可辨识性。'
            : 'AI 内容特征明显，需要加强反AI味处理。';
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('盲读辨识率：${(score * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text('你判断了 ${result.totalJudged} 段，其中 ${result.correctCount} 段判断正确。'),
              const SizedBox(height: 8),
              Text(interpretation),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.read(blindReadProvider.notifier).reset(),
                child: const Text('重新开始'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

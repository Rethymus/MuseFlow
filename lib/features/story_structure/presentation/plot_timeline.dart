import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/presentation/plot_node_form.dart';

/// Timeline-first list of plot nodes grouped by chapter.
///
/// Shows nodes sorted by chapter then manualOrder. Each card displays
/// title, chapter, structural role, writing status, involved characters,
/// and linked foreshadowing count.
class PlotTimeline extends ConsumerWidget {
  const PlotTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(plotNodeNotifierProvider);

    return nodesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败: $error'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(plotNodeNotifierProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (nodes) {
        if (nodes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_tree_outlined, size: 48),
                  SizedBox(height: 16),
                  Text(
                    '时间线还空着',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '先放下几个关键节点：铺垫、转折、高潮、收束。关系图以后再说，先让故事走起来。',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return _GroupedTimeline(nodes: nodes);
      },
    );
  }
}

/// Timeline grouped by chapter with node cards.
class _GroupedTimeline extends ConsumerWidget {
  final List<PlotNode> nodes;

  const _GroupedTimeline({required this.nodes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group nodes by chapter
    final chapters = <int, List<PlotNode>>{};
    for (final node in nodes) {
      chapters.putIfAbsent(node.chapter, () => []).add(node);
    }

    final sortedChapters = chapters.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedChapters.length,
      itemBuilder: (context, index) {
        final chapter = sortedChapters[index];
        final chapterNodes = chapters[chapter]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '第$chapter章',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${chapterNodes.length} 个节点',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Node cards
            ...chapterNodes.map((node) => _PlotNodeCard(node: node)),
          ],
        );
      },
    );
  }
}

/// Card for a single plot node in the timeline.
class _PlotNodeCard extends ConsumerWidget {
  final PlotNode node;

  const _PlotNodeCard({required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showEditForm(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with chips
              Row(
                children: [
                  Expanded(
                    child: Text(
                      node.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _RoleChip(role: node.structuralRole),
                  const SizedBox(width: 4),
                  _StatusChip(status: node.writingStatus),
                ],
              ),
              if (node.summary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  node.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              // Metadata chips
              if (node.involvedCharacterNames.isNotEmpty ||
                  node.linkedForeshadowingIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    ...node.involvedCharacterNames.map(
                      (name) => Chip(
                        label: Text(name),
                        avatar: const Icon(Icons.person_outline, size: 14),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    if (node.linkedForeshadowingIds.isNotEmpty)
                      Chip(
                        label: Text(
                          '${node.linkedForeshadowingIds.length} 条伏笔',
                        ),
                        avatar: const Icon(Icons.lightbulb_outline, size: 14),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: '删除',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditForm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => PlotNodeForm(node: node),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除情节点"${node.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(plotNodeNotifierProvider.notifier).delete(node.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// Chip showing the structural role of a plot node.
class _RoleChip extends StatelessWidget {
  final PlotNodeStructuralRole role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      label: Text(_roleLabel(role)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: colorScheme.surfaceContainerHighest,
    );
  }

  String _roleLabel(PlotNodeStructuralRole r) {
    return switch (r) {
      PlotNodeStructuralRole.setup => '铺垫',
      PlotNodeStructuralRole.development => '发展',
      PlotNodeStructuralRole.turn => '转折',
      PlotNodeStructuralRole.climax => '高潮',
      PlotNodeStructuralRole.resolution => '收束',
    };
  }
}

/// Chip showing the writing status of a plot node.
class _StatusChip extends StatelessWidget {
  final PlotNodeWritingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_statusLabel(status)),
      avatar: Icon(_statusIcon(status), size: 14),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _statusLabel(PlotNodeWritingStatus s) {
    return switch (s) {
      PlotNodeWritingStatus.notStarted => '未写',
      PlotNodeWritingStatus.drafting => '草稿',
      PlotNodeWritingStatus.complete => '完成',
      PlotNodeWritingStatus.needsRevision => '待改',
    };
  }

  IconData _statusIcon(PlotNodeWritingStatus s) {
    return switch (s) {
      PlotNodeWritingStatus.notStarted => Icons.circle_outlined,
      PlotNodeWritingStatus.drafting => Icons.edit_outlined,
      PlotNodeWritingStatus.complete => Icons.check_circle_outline,
      PlotNodeWritingStatus.needsRevision => Icons.refresh,
    };
  }
}

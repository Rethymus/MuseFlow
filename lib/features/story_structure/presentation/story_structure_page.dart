import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_reminder_service.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/presentation/foreshadowing_form.dart';
import 'package:museflow/features/story_structure/presentation/guardian_panel.dart';
import 'package:museflow/features/story_structure/presentation/plot_node_form.dart';
import 'package:museflow/features/story_structure/presentation/plot_timeline.dart';

/// Story structure page with section navigation.
///
/// Provides four sections: Foreshadowing, Plot Timeline, Guardian,
/// and Finish & Export. Only Foreshadowing is fully functional in this plan;
/// other sections show placeholder content pointing to later plans.
class StoryStructurePage extends ConsumerStatefulWidget {
  const StoryStructurePage({super.key});

  @override
  ConsumerState<StoryStructurePage> createState() => _StoryStructurePageState();
}

class _StoryStructurePageState extends ConsumerState<StoryStructurePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('故事结构'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '伏笔'),
            Tab(text: '剧情线'),
            Tab(text: '守护'),
            Tab(text: '整理与导出'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ForeshadowingSection(),
          PlotTimeline(),
          GuardianPanel(),
          _PlaceholderSection(
            title: '整理成可交付的稿件',
            body: '先预览清理结果，再确认应用。导出只保存到你选择的本地文件。',
            actionLabel: '计划中',
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  void _showForeshadowingForm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const ForeshadowingForm(),
    );
  }

  void _showPlotNodeForm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const PlotNodeForm(),
    );
  }

  Widget? _buildFAB() {
    return switch (_tabController.index) {
      0 => FloatingActionButton(
          onPressed: () => _showForeshadowingForm(context),
          tooltip: '新建伏笔',
          child: const Icon(Icons.add),
        ),
      1 => FloatingActionButton(
          onPressed: () => _showPlotNodeForm(context),
          tooltip: '新建情节点',
          child: const Icon(Icons.add),
        ),
      _ => null,
    };
  }
}

/// Foreshadowing section showing all foreshadowing entries with reminders.
class _ForeshadowingSection extends ConsumerWidget {
  const _ForeshadowingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(foreshadowingNotifierProvider);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败: $error'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(foreshadowingNotifierProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline, size: 48),
                  SizedBox(height: 16),
                  Text(
                    '还没有伏笔',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '选中文稿中的一句话创建伏笔，或先手动写下计划埋设的线索。',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            _ReminderBadges(entries: entries),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _ForeshadowingTile(entry: entry);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Non-blocking reminder badges shown at the top of the foreshadowing section.
class _ReminderBadges extends ConsumerWidget {
  final List<ForeshadowingEntry> entries;

  const _ReminderBadges({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final notifier = ref.read(foreshadowingNotifierProvider.notifier);
    final reminders = notifier.remindersForChapter(
      currentChapter: 5, // Default current chapter for display
      defaultThreshold: 3, // Default threshold
    );

    if (reminders.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: reminders.map((reminder) {
          return Chip(
            avatar: Icon(
              _reminderIcon(reminder.kind),
              size: 16,
            ),
            label: Text(reminder.message),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }

  IconData _reminderIcon(ForeshadowingReminderKind kind) {
    switch (kind) {
      case ForeshadowingReminderKind.unresolvedCount:
        return Icons.info_outline;
      case ForeshadowingReminderKind.thresholdOverdue:
        return Icons.schedule;
      case ForeshadowingReminderKind.targetOverdue:
        return Icons.flag;
    }
  }
}

/// Tile for a single foreshadowing entry.
class _ForeshadowingTile extends ConsumerWidget {
  final ForeshadowingEntry entry;

  const _ForeshadowingTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: _StatusIcon(status: entry.status),
      title: Text(entry.title),
      subtitle: Text(
        _buildSubtitle(entry),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.isOpen)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, size: 20),
              tooltip: '标记已解决',
              onPressed: () => _markResolved(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: '删除',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      onTap: () => _showEditForm(context),
    );
  }

  String _buildSubtitle(ForeshadowingEntry e) {
    final parts = <String>[];
    parts.add('第${e.plantedChapter}章埋设');
    if (e.targetResolutionChapter != null) {
      parts.add('计划第${e.targetResolutionChapter}章解决');
    }
    if (e.sourceExcerpt.isNotEmpty) {
      parts.add(e.sourceExcerpt);
    }
    return parts.join(' · ');
  }

  void _showEditForm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => ForeshadowingForm(entry: entry),
    );
  }

  void _markResolved(BuildContext context, WidgetRef ref) {
    ref
        .read(foreshadowingNotifierProvider.notifier)
        .markResolved(entry.id, resolvedChapter: entry.plantedChapter + 1);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除伏笔"${entry.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(foreshadowingNotifierProvider.notifier)
                  .delete(entry.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// Status icon for a foreshadowing entry.
class _StatusIcon extends StatelessWidget {
  final ForeshadowingStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Icon(
      _statusIcon(status),
      color: _statusColor(status, colorScheme),
      size: 20,
    );
  }

  IconData _statusIcon(ForeshadowingStatus s) {
    switch (s) {
      case ForeshadowingStatus.planted:
        return Icons.circle_outlined;
      case ForeshadowingStatus.developing:
        return Icons.trending_flat;
      case ForeshadowingStatus.resolved:
        return Icons.check_circle;
      case ForeshadowingStatus.abandoned:
        return Icons.remove_circle_outline;
    }
  }

  Color _statusColor(ForeshadowingStatus s, ColorScheme cs) {
    switch (s) {
      case ForeshadowingStatus.planted:
        return cs.outline;
      case ForeshadowingStatus.developing:
        return cs.primary;
      case ForeshadowingStatus.resolved:
        return cs.tertiary;
      case ForeshadowingStatus.abandoned:
        return cs.error;
    }
  }
}

/// Placeholder section for future features.
class _PlaceholderSection extends StatelessWidget {
  final String title;
  final String body;
  final String actionLabel;

  const _PlaceholderSection({
    required this.title,
    required this.body,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Chip(label: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/application/kb_staleness_checker.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/shared/constants/app_constants.dart';

/// Knowledge base page with tabs for character cards and world settings.
///
/// Displays two tabs: "角色卡" (Character Cards) and "世界观" (World Settings).
/// Each tab shows a searchable list with FAB for creating new entries.
class KnowledgeBasePage extends ConsumerStatefulWidget {
  const KnowledgeBasePage({super.key});

  @override
  ConsumerState<KnowledgeBasePage> createState() => _KnowledgeBasePageState();
}

class _KnowledgeBasePageState extends ConsumerState<KnowledgeBasePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '角色卡'),
            Tab(text: '世界观'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go(AppConstants.knowledgeTemplates),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('模板库'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索名称或别名...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CharacterCardList(searchQuery: _searchQuery),
                _WorldSettingList(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(),
        tooltip: '新建',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreate() {
    final tabIndex = _tabController.index;
    if (tabIndex == 0) {
      context.go(AppConstants.knowledgeCharacterNew);
    } else {
      context.go(AppConstants.knowledgeSettingNew);
    }
  }
}

/// Character card list with search filtering.
class _CharacterCardList extends ConsumerWidget {
  final String searchQuery;

  const _CharacterCardList({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(characterCardNotifierProvider);

    return cardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败: $error'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(characterCardNotifierProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (cards) {
        final filtered = searchQuery.isEmpty
            ? cards
            : ref
                  .read(characterCardNotifierProvider.notifier)
                  .searchByName(searchQuery);

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isEmpty ? '暂无角色卡\n点击 + 创建' : '未找到匹配的角色卡',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final card = filtered[index];
            return _CharacterCardTile(card: card);
          },
        );
      },
    );
  }
}

/// Tile for a single character card entry.
class _CharacterCardTile extends ConsumerWidget {
  final CharacterCard card;

  const _CharacterCardTile({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterCount = ref.watch(
      chapterNotifierProvider.select(
        (async) => async.asData?.value.length ?? 0,
      ),
    );
    final staleness = const KbStalenessChecker().check(
      card.lastVerifiedChapter,
      chapterCount,
    );

    return ListTile(
      title: Text(card.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            card.personality.isNotEmpty ? card.personality : '无性格描述',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (staleness.level != KbStalenessLevel.fresh) ...[
            const SizedBox(height: 4),
            _StalenessBadge(staleness: staleness),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: '操作',
        onSelected: (value) {
          if (value == 'verify') {
            _confirmVerify(context, ref, chapterCount);
          } else if (value == 'delete') {
            _confirmDelete(context, ref);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'verify',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified),
              title: const Text('标记为已验证'),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '删除',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      ),
      onTap: () => context.go('/knowledge/character/${card.id}'),
    );
  }

  void _confirmVerify(BuildContext context, WidgetRef ref, int chapterCount) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('标记为已验证'),
        content: Text(
          '确认将"${card.name}"标记为截至第 $chapterCount 章已验证？'
          '验证后该条目将不再提示陈旧。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(characterCardNotifierProvider.notifier)
                  .save(card.copyWith(lastVerifiedChapter: chapterCount));
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除角色卡"${card.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(characterCardNotifierProvider.notifier).delete(card.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// World setting list with search filtering.
class _WorldSettingList extends ConsumerWidget {
  final String searchQuery;

  const _WorldSettingList({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(worldSettingNotifierProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败: $error'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(worldSettingNotifierProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (settings) {
        final filtered = searchQuery.isEmpty
            ? settings
            : ref
                  .read(worldSettingNotifierProvider.notifier)
                  .searchByName(searchQuery);

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isEmpty ? '暂无世界观\n点击 + 创建' : '未找到匹配的世界观',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final setting = filtered[index];
            return _WorldSettingTile(setting: setting);
          },
        );
      },
    );
  }
}

/// Tile for a single world setting entry.
class _WorldSettingTile extends ConsumerWidget {
  final WorldSetting setting;

  const _WorldSettingTile({required this.setting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterCount = ref.watch(
      chapterNotifierProvider.select(
        (async) => async.asData?.value.length ?? 0,
      ),
    );
    final staleness = const KbStalenessChecker().check(
      setting.lastVerifiedChapter,
      chapterCount,
    );

    return ListTile(
      title: Text(setting.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            setting.description.isNotEmpty ? setting.description : '无描述',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (staleness.level != KbStalenessLevel.fresh) ...[
            const SizedBox(height: 4),
            _StalenessBadge(staleness: staleness),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: '操作',
        onSelected: (value) {
          if (value == 'verify') {
            _confirmVerify(context, ref, chapterCount);
          } else if (value == 'delete') {
            _confirmDelete(context, ref);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'verify',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified),
              title: const Text('标记为已验证'),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '删除',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      ),
      onTap: () => context.go('/knowledge/setting/${setting.id}'),
    );
  }

  void _confirmVerify(BuildContext context, WidgetRef ref, int chapterCount) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('标记为已验证'),
        content: Text(
          '确认将"${setting.name}"标记为截至第 $chapterCount 章已验证？'
          '验证后该条目将不再提示陈旧。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(worldSettingNotifierProvider.notifier)
                  .save(setting.copyWith(lastVerifiedChapter: chapterCount));
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除世界观"${setting.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(worldSettingNotifierProvider.notifier)
                  .delete(setting.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// Renders a knowledge-base staleness badge for [staleness].
///
/// Returns an empty [SizedBox] when [staleness.level] is fresh (the UI must
/// not nag legacy entries — see [KbStalenessChecker]). For stale/veryStale the
/// badge uses the project color scheme: amber warning vs. theme error.
class _StalenessBadge extends StatelessWidget {
  final KbStalenessResult staleness;

  const _StalenessBadge({required this.staleness});

  @override
  Widget build(BuildContext context) {
    if (staleness.level == KbStalenessLevel.fresh) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isVeryStale = staleness.level == KbStalenessLevel.veryStale;
    final iconColor = isVeryStale ? theme.colorScheme.error : Colors.amber[700];
    final icon = Icon(
      isVeryStale ? Icons.error_outline : Icons.warning_amber_rounded,
      size: 14,
      color: iconColor,
    );
    final background = isVeryStale
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
        : Colors.amber.withValues(alpha: 0.12);
    final textColor = isVeryStale
        ? theme.colorScheme.onErrorContainer
        : iconColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                staleness.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

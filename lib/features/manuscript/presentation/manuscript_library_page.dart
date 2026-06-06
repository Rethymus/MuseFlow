import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/application/manuscript_notifier.dart';
import 'package:museflow/features/manuscript/application/manuscript_sort.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_card.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_create_dialog.dart';

/// Manuscript library homepage -- the app's new default screen.
///
/// Renders a responsive card grid for existing manuscripts or an empty state
/// with a welcoming message. Supports sorting, quick-create, and context
/// menus for edit/delete operations.
class ManuscriptLibraryPage extends ConsumerStatefulWidget {
  const ManuscriptLibraryPage({super.key});

  @override
  ConsumerState<ManuscriptLibraryPage> createState() =>
      _ManuscriptLibraryPageState();
}

class _ManuscriptLibraryPageState extends ConsumerState<ManuscriptLibraryPage> {
  ManuscriptSortMode _sortMode = ManuscriptSortMode.recentEdit;

  @override
  Widget build(BuildContext context) {
    final manuscriptsAsync = ref.watch(manuscriptNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '文稿库',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
        ),
        actions: [
          manuscriptsAsync.asData?.value.isNotEmpty == true
              ? _SortDropdown(
                  sortMode: _sortMode,
                  onChanged: (mode) =>
                      setState(() => _sortMode = mode),
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: manuscriptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error.toString(),
          onRetry: () => ref.invalidate(manuscriptNotifierProvider),
        ),
        data: (manuscripts) {
          if (manuscripts.isEmpty) {
            return const _EmptyState();
          }

          final sorted = manuscripts.toList()
            ..sort(
              (a, b) => compareManuscripts(a, b, _sortMode),
            );

          return _ManuscriptGrid(manuscripts: sorted);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('创建文稿'),
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => const ManuscriptCreateDialog(),
    );
  }
}

/// Empty state widget shown when no manuscripts exist.
///
/// Displays an icon, heading, description, and a "创建文稿" CTA button.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '创建你的第一部作品',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '从灵感开始，写下属于你的故事',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const ManuscriptCreateDialog(),
                );
              },
              child: const Text('创建文稿'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive card grid for manuscripts.
///
/// 3 columns for width >= 1000px, 2 for >= 600px, 1 for mobile.
class _ManuscriptGrid extends StatelessWidget {
  const _ManuscriptGrid({required this.manuscripts});

  final List<Manuscript> manuscripts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _columnCount(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: manuscripts.length,
          itemBuilder: (context, index) {
            final manuscript = manuscripts[index];
            return _ManuscriptCardWrapper(manuscript: manuscript);
          },
        );
      },
    );
  }

  int _columnCount(double width) {
    if (width >= 1000) return 3;
    if (width >= 600) return 2;
    return 1;
  }
}

/// Wrapper around [ManuscriptCard] that handles tap and long-press actions.
class _ManuscriptCardWrapper extends ConsumerWidget {
  const _ManuscriptCardWrapper({required this.manuscript});

  final Manuscript manuscript;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context, ref),
      child: ManuscriptCard(
        manuscript: manuscript,
        onTap: () => context.go('/manuscript/${manuscript.id}/editor'),
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑信息'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/manuscript/${manuscript.id}/settings');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '删除',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          "确定要删除文稿'${manuscript.title}'吗？文稿将在30天后永久删除，期间可恢复。",
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
                  .read(manuscriptNotifierProvider.notifier)
                  .softDelete(manuscript.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// Sort mode dropdown button in the AppBar.
class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.sortMode,
    required this.onChanged,
  });

  final ManuscriptSortMode sortMode;
  final ValueChanged<ManuscriptSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ManuscriptSortMode>(
      icon: const Icon(Icons.sort),
      initialValue: sortMode,
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: ManuscriptSortMode.recentEdit,
          child: Text('最近编辑'),
        ),
        const PopupMenuItem(
          value: ManuscriptSortMode.creationDate,
          child: Text('创建时间'),
        ),
        const PopupMenuItem(
          value: ManuscriptSortMode.titleAlphabetical,
          child: Text('标题'),
        ),
      ],
    );
  }
}

/// Error state with retry button.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('加载失败: $error'),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/application/manuscript_sort.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_card.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_create_dialog.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:museflow/shared/theme/app_dimens.dart';
import 'package:museflow/shared/utils/friendly_error.dart';
import 'package:museflow/shared/widgets/app_controls.dart';
import 'package:museflow/shared/widgets/app_dialogs.dart';

/// Manuscript library homepage — the app's default screen.
///
/// Apple layout: a large bold title over a responsive card grid of inset
/// white cards on the grouped gray background. Supports sorting, quick
/// create, and context menus for edit/delete operations.
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
        title: Text('文稿库', style: Theme.of(context).textTheme.displayMedium),
        actions: [
          // On narrow layouts the bottom tab bar collapses to 5 primary
          // destinations and settings moves here (HF-3).
          if (MediaQuery.of(context).size.width <
              AppConstants.sidebarCollapsedBreakpoint)
            IconButton(
              tooltip: '设置',
              icon: const Icon(CupertinoIcons.gear),
              onPressed: () => context.go(AppConstants.settings),
            ),
          manuscriptsAsync.asData?.value.isNotEmpty == true
              ? _SortDropdown(
                  sortMode: _sortMode,
                  onChanged: (mode) => setState(() => _sortMode = mode),
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: manuscriptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: friendlyError(error),
          onRetry: () => ref.invalidate(manuscriptNotifierProvider),
        ),
        data: (manuscripts) {
          if (manuscripts.isEmpty) {
            return const _EmptyState();
          }

          final sorted = manuscripts.toList()
            ..sort((a, b) => compareManuscripts(a, b, _sortMode));

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

/// Empty state shown when no manuscripts exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: CupertinoIcons.book,
      title: '创建你的第一部作品',
      message: '从灵感开始，写下属于你的故事',
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ManuscriptCreateDialog(),
              );
            },
            child: const Text('创建文稿'),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Secondary path: jump-start worldbuilding from the template
          // gallery instead of a blank page.
          TextButton.icon(
            onPressed: () => context.go(AppConstants.knowledgeTemplates),
            icon: const Icon(CupertinoIcons.sparkles, size: 18),
            label: const Text('从模板库开始'),
          ),
        ],
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
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
        onEditInfo: () => context.go('/manuscript/${manuscript.id}/settings'),
        onDelete: () => _confirmDelete(context, ref),
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    showAppActionSheet(
      context,
      title: manuscript.title,
      actions: [
        AppSheetAction(
          '编辑信息',
          onPressed: () {
            context.go('/manuscript/${manuscript.id}/settings');
          },
        ),
        AppSheetAction(
          '删除',
          isDestructive: true,
          onPressed: () {
            _confirmDelete(context, ref);
          },
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showAppDialog(
      context,
      title: '确认删除',
      message: '确定要删除文稿「${manuscript.title}」吗？文稿将在30天后永久删除，期间可恢复。',
      actions: [
        const AppDialogAction('取消'),
        AppDialogAction(
          '删除',
          isDestructive: true,
          onPressed: () => ref
              .read(manuscriptNotifierProvider.notifier)
              .softDelete(manuscript.id),
        ),
      ],
    );
  }
}

/// Sort mode dropdown button in the AppBar.
class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.sortMode, required this.onChanged});

  final ManuscriptSortMode sortMode;
  final ValueChanged<ManuscriptSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ManuscriptSortMode>(
      icon: const Icon(CupertinoIcons.line_horizontal_3_decrease),
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
    return AppEmptyState(
      icon: CupertinoIcons.exclamationmark_triangle,
      title: '加载失败',
      message: friendlyError(error),
      action: FilledButton(onPressed: onRetry, child: const Text('重试')),
    );
  }
}

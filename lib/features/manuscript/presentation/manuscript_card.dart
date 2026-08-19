import 'package:flutter/material.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/domain/manuscript_genre.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/theme/app_dimens.dart';

/// A card widget displaying a manuscript summary in the library grid.
///
/// Book-metaphor layout on an Apple inset-group card: a genre-tinted cover
/// with the cover letter and genre label, then metadata (title, progress,
/// status, timestamp). Hover raises a soft shadow — the only elevation in
/// the card system — and reveals the "more" menu (D-3); long-press and
/// right-click still work via the parent wrapper and the secondary tap.
class ManuscriptCard extends StatefulWidget {
  const ManuscriptCard({
    super.key,
    required this.manuscript,
    this.currentWordCount = 0,
    required this.onTap,
    this.onEditInfo,
    this.onDelete,
  });

  final Manuscript manuscript;

  /// Current total word count across all chapters.
  final int currentWordCount;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Callback for "编辑信息" context menu action.
  final VoidCallback? onEditInfo;

  /// Callback for "删除" context menu action.
  final VoidCallback? onDelete;

  @override
  State<ManuscriptCard> createState() => _ManuscriptCardState();
}

class _ManuscriptCardState extends State<ManuscriptCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppColors.of(context);
    final hasMenu = widget.onEditInfo != null || widget.onDelete != null;

    // D-7: expose the card as a single labelled button for assistive tech —
    // previously the only semantics came from the progress bar inside, so
    // screen readers announced the card as a progressbar.
    return Semantics(
      button: true,
      label:
          '${widget.manuscript.title}，${widget.manuscript.status}，'
          '${_formatNumber(widget.currentWordCount)}字',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: p.cardBackground,
            borderRadius: AppRadius.rMedium,
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.rMedium,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                // Desktop convention (SE-8): right-click opens the same
                // actions as the hover "⋮" menu.
                onSecondaryTapUp: hasMenu
                    ? (details) => _showMenuAt(context, details.globalPosition)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCoverArea(p, hasMenu),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.manuscript.title,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            _buildProgressBar(theme, p),
                            const Spacer(),
                            _buildBottomRow(theme, p),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverArea(AppPalette p, bool hasMenu) {
    final manuscript = widget.manuscript;
    final effectiveLetter = manuscript.coverLetter.isNotEmpty
        ? manuscript.coverLetter
        : manuscript.title.substring(0, manuscript.title.length.clamp(0, 2));
    final genreColor = Color(ManuscriptGenre.genreColor(manuscript.genre));

    return Stack(
      children: [
        Container(
          height: 128,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  Colors.white.withValues(alpha: 0.14),
                  genreColor,
                ),
                Color.alphaBlend(
                  Colors.black.withValues(alpha: 0.22),
                  genreColor,
                ),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                effectiveLetter,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                manuscript.genre,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        if (hasMenu)
          Positioned(
            top: 4,
            right: 4,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _hovering ? 1 : 0,
              child: _CardMenu(
                onEditInfo: widget.onEditInfo,
                onDelete: widget.onDelete,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme, AppPalette p) {
    final progress = widget.manuscript.targetWordCount > 0
        ? (widget.currentWordCount / widget.manuscript.targetWordCount).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    final formattedCurrent = _formatNumber(widget.currentWordCount);
    final formattedTarget = _formatNumber(widget.manuscript.targetWordCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$formattedCurrent / $formattedTarget 字',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        // Decorative: the numeric label above already conveys progress in
        // the semantics tree, so the bar itself is excluded (D-7).
        ExcludeSemantics(
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: p.gray5,
            valueColor: AlwaysStoppedAnimation(p.accent),
            borderRadius: AppRadius.pill,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(ThemeData theme, AppPalette p) {
    return Row(
      children: [
        _StatusBadge(status: widget.manuscript.status),
        const Spacer(),
        Text(
          _relativeTime(widget.manuscript.updatedAt),
          style: theme.textTheme.labelSmall?.copyWith(color: p.secondaryLabel),
        ),
      ],
    );
  }

  /// Right-click entry point: opens the same edit/delete actions as the
  /// hover "⋮" menu at the pointer position.
  Future<void> _showMenuAt(BuildContext context, Offset globalPosition) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      items: buildManuscriptCardMenuItems(context),
    );
    if (!mounted) return;
    if (action == 'edit') widget.onEditInfo?.call();
    if (action == 'delete') widget.onDelete?.call();
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${dateTime.month}月${dateTime.day}日';
  }
}

/// Shared menu items for the card's hover "⋮" button and the right-click
/// context menu, so both entries always offer identical actions.
List<PopupMenuEntry<String>> buildManuscriptCardMenuItems(
  BuildContext context,
) {
  final p = AppColors.of(context);
  return [
    const PopupMenuItem(value: 'edit', child: Text('编辑信息')),
    PopupMenuItem(
      value: 'delete',
      child: Text('删除', style: TextStyle(color: p.systemRed)),
    ),
  ];
}

/// Overflow "⋮" menu revealed on hover (desktop) or via long-press wrapper
/// (touch). Fires the card's edit/delete callbacks.
class _CardMenu extends StatelessWidget {
  const _CardMenu({this.onEditInfo, this.onDelete});

  final VoidCallback? onEditInfo;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 20, color: Colors.white),
      tooltip: '文稿操作',
      color: p.tertiaryGroupedBackground,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rMedium),
      onSelected: (action) {
        if (action == 'edit') onEditInfo?.call();
        if (action == 'delete') onDelete?.call();
      },
      itemBuilder: (context) => buildManuscriptCardMenuItems(context),
    );
  }
}

/// A tinted pill badge showing manuscript status, iOS style: a 14% tinted
/// background with the full-strength tint as text color.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final tint = _statusTint(p);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        status,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: Color.alphaBlend(
            tint.withValues(alpha: 0.85),
            p.cardBackground,
          ),
        ),
      ),
    );
  }

  Color _statusTint(AppPalette p) {
    return switch (status) {
      '写作中' => p.accent,
      '已完成' => p.systemGreen,
      _ => p.gray,
    };
  }
}

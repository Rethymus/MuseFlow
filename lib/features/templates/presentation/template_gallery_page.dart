import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/templates/domain/world_template.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/theme/app_dimens.dart';
import 'package:museflow/shared/widgets/app_card.dart';
import 'package:museflow/shared/widgets/app_controls.dart';

/// World-template gallery: channel segmented control + search + template
/// cards on the grouped background.
class TemplateGalleryPage extends ConsumerStatefulWidget {
  const TemplateGalleryPage({super.key});

  @override
  ConsumerState<TemplateGalleryPage> createState() =>
      _TemplateGalleryPageState();
}

class _TemplateGalleryPageState extends ConsumerState<TemplateGalleryPage> {
  TemplateChannel? _selectedChannel;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  late Future<List<WorldTemplate>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _templatesFuture = ref.read(worldTemplateRepositoryProvider).getAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('世界观模板库', style: Theme.of(context).textTheme.displayMedium),
      ),
      body: FutureBuilder<List<WorldTemplate>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _TemplateErrorState(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {
                _templatesFuture = ref
                    .read(worldTemplateRepositoryProvider)
                    .getAll();
              }),
            );
          }

          final templates = _filterTemplates(snapshot.data ?? const []);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSegmentedControl<TemplateChannel?>(
                      segments: const {
                        null,
                        TemplateChannel.male,
                        TemplateChannel.female,
                      },
                      selected: _selectedChannel,
                      onSelectionChanged: (selected) =>
                          setState(() => _selectedChannel = selected),
                      labelOf: (channel) => switch (channel) {
                        TemplateChannel.male => '男频',
                        TemplateChannel.female => '女频',
                        null => '全部',
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜索类型、简介或热门标签...',
                        prefixIcon: const Icon(CupertinoIcons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        isDense: true,
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: templates.isEmpty
                    ? AppEmptyState(
                        icon: CupertinoIcons.sparkles,
                        title: _searchQuery.isEmpty ? '暂无模板' : '未找到匹配的模板',
                        message: '',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          return _TemplateCard(template: templates[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<WorldTemplate> _filterTemplates(List<WorldTemplate> templates) {
    return templates.where((template) {
      final channelMatches =
          _selectedChannel == null || template.channel == _selectedChannel;
      return channelMatches && template.matchesQuery(_searchQuery);
    }).toList();
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final WorldTemplate template;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: () =>
          context.go('${AppConstants.knowledgeTemplates}/${template.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.accentFill,
              borderRadius: AppRadius.rSmall,
            ),
            child: Icon(_iconFor(template.iconName), size: 22, color: p.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  template.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: p.secondaryLabel),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _PassiveTag(
                      label: template.channel == TemplateChannel.male
                          ? '男频'
                          : '女频',
                      color: template.channel == TemplateChannel.male
                          ? p.systemBlue
                          : p.systemPink,
                    ),
                    _PassiveTag(label: '内置已审核', color: p.systemGreen),
                    for (final tag in template.tags)
                      _PassiveTag(label: tag, color: p.gray),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(CupertinoIcons.chevron_right, size: 15, color: p.tertiaryLabel),
        ],
      ),
    );
  }

  IconData _iconFor(String iconName) {
    return switch (iconName) {
      'filter_vintage' => CupertinoIcons.sparkles,
      'location_city' => CupertinoIcons.building_2_fill,
      'memory' => CupertinoIcons.gear_alt,
      'account_balance' => CupertinoIcons.building_2_fill,
      'sports_esports' => CupertinoIcons.game_controller,
      'travel_explore' => CupertinoIcons.globe,
      'terrain' => CupertinoIcons.map_fill,
      'work_outline' => CupertinoIcons.briefcase_fill,
      'home_filled' => CupertinoIcons.house_fill,
      'flutter_dash' => CupertinoIcons.ant_fill,
      'school' => CupertinoIcons.book_fill,
      'visibility' => CupertinoIcons.eye_fill,
      'yard' => CupertinoIcons.tree,
      _ => CupertinoIcons.sparkles,
    };
  }
}

/// Non-interactive tinted pill label for template metadata.
class _PassiveTag extends StatelessWidget {
  const _PassiveTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppBadge(label: label, color: color, subtle: true);
  }
}

class _TemplateErrorState extends StatelessWidget {
  const _TemplateErrorState({required this.error, required this.onRetry});

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

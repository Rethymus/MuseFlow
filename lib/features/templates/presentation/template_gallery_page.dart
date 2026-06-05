import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/templates/domain/world_template.dart';
import 'package:museflow/shared/constants/app_constants.dart';

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
      appBar: AppBar(title: const Text('世界观模板库')),
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<TemplateChannel?>(
                      segments: const [
                        ButtonSegment(value: null, label: Text('全部')),
                        ButtonSegment(
                          value: TemplateChannel.male,
                          label: Text('男频'),
                        ),
                        ButtonSegment(
                          value: TemplateChannel.female,
                          label: Text('女频'),
                        ),
                      ],
                      selected: {_selectedChannel},
                      onSelectionChanged: (selected) {
                        setState(() => _selectedChannel = selected.single);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜索类型、简介或热门标签...',
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
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
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? '暂无模板' : '未找到匹配的模板',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(_iconFor(template.iconName))),
        title: Text(template.displayTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              template.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _PassiveTag(
                  label: template.channel == TemplateChannel.male ? '男频' : '女频',
                ),
                const _PassiveTag(label: '内置已审核'),
                for (final tag in template.tags) _PassiveTag(label: tag),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
        onTap: () =>
            context.go('${AppConstants.knowledgeTemplates}/${template.id}'),
      ),
    );
  }

  IconData _iconFor(String iconName) {
    return switch (iconName) {
      'filter_vintage' => Icons.filter_vintage,
      'location_city' => Icons.location_city,
      'memory' => Icons.memory,
      'account_balance' => Icons.account_balance,
      'sports_esports' => Icons.sports_esports,
      'travel_explore' => Icons.travel_explore,
      'terrain' => Icons.terrain,
      'work_outline' => Icons.work_outline,
      'home_filled' => Icons.home_filled,
      'flutter_dash' => Icons.flutter_dash,
      'school' => Icons.school,
      'visibility' => Icons.visibility,
      'yard' => Icons.yard,
      _ => Icons.auto_awesome,
    };
  }
}

class _PassiveTag extends StatelessWidget {
  const _PassiveTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
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

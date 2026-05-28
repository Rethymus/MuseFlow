import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/note.dart';
import '../services/global_search_service.dart';
import '../widgets/global_search_widget.dart';

/// 全局搜索页面
/// 支持搜索笔记、角色卡、世界观等内容
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 初始化全局搜索服务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GlobalSearchService>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchResult(GlobalSearchResult result) {
    switch (result.type) {
      case GlobalSearchResultType.note:
        final note = result.data as Note;
        context.read<AppState>().selectNote(note);
        // 导航到主页
        _navigateToHome();
        break;
      case GlobalSearchResultType.character:
      case GlobalSearchResultType.world:
      case GlobalSearchResultType.location:
      case GlobalSearchResultType.organization:
        // TODO: 实现其他类型的结果导航
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已选择: ${result.title}')),
        );
        break;
    }
  }

  void _navigateToHome() {
    // 找到MainNavigationContainer并切换到首页
    final navigationController = context.findAncestorStateOfType<_MainNavigationContainerState>();
    if (navigationController != null) {
      navigationController._onDestinationSelected(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Consumer<GlobalSearchService>(
          builder: (context, searchService, child) {
            return Column(
              children: [
                // 搜索栏
                _buildSearchBar(theme, searchService),

                // 搜索结果
                Expanded(
                  child: _buildResultsContent(theme, searchService),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, GlobalSearchService searchService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '搜索笔记、角色、世界观...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    searchService.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        onChanged: (query) {
          searchService.search(query);
        },
        onSubmitted: (query) {
          searchService.search(query);
        },
      ),
    );
  }

  Widget _buildResultsContent(ThemeData theme, GlobalSearchService searchService) {
    if (searchService.isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (searchService.query.isEmpty) {
      return _buildEmptyState(theme, searchService);
    }

    if (!searchService.hasResults) {
      return _buildNoResultsState(theme);
    }

    return _buildResultsList(theme, searchService);
  }

  Widget _buildEmptyState(ThemeData theme, GlobalSearchService searchService) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (searchService.searchHistory.isNotEmpty) ...[
          _buildSearchHistory(theme, searchService),
          const SizedBox(height: 24),
        ],
        if (searchService.popularSearches.isNotEmpty) ...[
          _buildPopularSearches(theme, searchService),
        ],
        const SizedBox(height: 24),
        _buildSearchSuggestions(theme),
      ],
    );
  }

  Widget _buildSearchHistory(ThemeData theme, GlobalSearchService searchService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '搜索历史',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => searchService.clearHistory(),
              child: const Text('清空'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: searchService.searchHistory.take(8).map((item) {
            return Chip(
              label: Text(item.query),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                final index = searchService.searchHistory.indexOf(item);
                searchService.removeFromHistory(index);
              },
              onPressed: () {
                _searchController.text = item.query;
                searchService.search(item.query);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPopularSearches(ThemeData theme, GlobalSearchService searchService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '热门搜索',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: searchService.popularSearches.map((query) {
            return ActionChip(
              label: Text(query),
              onPressed: () {
                _searchController.text = query;
                searchService.search(query);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchSuggestions(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '开始搜索',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '输入关键词搜索笔记、角色、世界观',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '未找到结果',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试使用不同的关键词',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme, GlobalSearchService searchService) {
    // 按类型分组显示结果
    final groupedResults = searchService.groupedResults;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedResults.keys.length,
      itemBuilder: (context, index) {
        final type = groupedResults.keys.elementAt(index);
        final results = groupedResults[type]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 类型标题
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SearchResultTypeLabel(type: type),
                  const SizedBox(width: 8),
                  Text(
                    '${results.length} 个结果',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // 该类型的结果列表
            ...results.map((result) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlobalSearchResultTile(
                result: result,
                query: searchService.query,
                onTap: () => _handleSearchResult(result),
              ),
            )),
          ],
        );
      },
    );
  }
}

// 为了访问导航容器的私有状态，我们需要一个全局key或公共方法
// 这里我们创建一个简单的解决方案
class _MainNavigationContainerState extends State {
  void _onDestinationSelected(int index) {
    // 这个方法应该从MainNavigationContainer中暴露
  }
}
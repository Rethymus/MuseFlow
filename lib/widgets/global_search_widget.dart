import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/global_search_service.dart';
import '../config/app_constants.dart';

/// 全局搜索对话框
class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();

  /// 显示搜索对话框
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const GlobalSearchDialog(),
    );
  }
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  late GlobalSearchService _searchService;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchService = context.read<GlobalSearchService>();
    _textController.addListener(() {
      _searchService.search(_textController.text);
    });

    // 延迟聚焦，避免键盘弹出问题
    Future.delayed(AppConstants.shortDelay, () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleResultTap(GlobalSearchResult result) {
    Navigator.of(context).pop(result);
  }

  void _handleHistoryTap(String query) {
    _textController.text = query;
    _searchService.search(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
            color: theme.dialogBackgroundColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 搜索栏
              _buildSearchBar(theme),

              // 搜索内容区域
              Expanded(
                child: _buildSearchContent(theme),
              ),

              // 底部操作栏
              _buildBottomBar(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.standardSpacing),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: AppConstants.thinBorderWidth,
          ),
        ),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '搜索笔记、角色、世界观...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ListenableBuilder(
            listenable: _textController,
            builder: (context, child) {
              return _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _textController.clear();
                        _searchService.clear();
                      },
                    )
                  : const SizedBox.shrink();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.mediumBorderRadius),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildSearchContent(ThemeData theme) {
    return ListenableBuilder(
      listenable: _searchService,
      builder: (context, child) {
        if (_searchService.isSearching) {
          return _buildLoadingState();
        }

        if (_searchService.query.isEmpty) {
          return _buildEmptyState(theme);
        }

        if (!_searchService.hasResults) {
          return _buildNoResultsState();
        }

        return _buildResultsList();
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppConstants.mediumSpacing),
          Text('搜索中...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.standardSpacing),
      children: [
        if (_searchService.searchHistory.isNotEmpty) ...[
          _buildSearchHistory(theme),
          const SizedBox(height: AppConstants.largeSpacing),
        ],
        if (_searchService.popularSearches.isNotEmpty) ...[
          _buildPopularSearches(theme),
        ],
      ],
    );
  }

  Widget _buildSearchHistory(ThemeData theme) {
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
              onPressed: () => _searchService.clearHistory(),
              child: const Text('清空'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.smallSpacing),
        Wrap(
          spacing: AppConstants.smallSpacing,
          runSpacing: AppConstants.smallSpacing,
          children: _searchService.searchHistory.take(8).map((item) {
            return _buildHistoryChip(item, theme);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHistoryChip(SearchHistoryItem item, ThemeData theme) {
    return ActionChip(
      label: Text(item.query),
      deleteIcon: const Icon(Icons.close, size: AppConstants.smallIconSize),
      onDeleted: () {
        final index = _searchService.searchHistory.indexOf(item);
        _searchService.removeFromHistory(index);
      },
      onPressed: () => _handleHistoryTap(item.query),
    );
  }

  Widget _buildPopularSearches(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '热门搜索',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallSpacing),
        Wrap(
          spacing: AppConstants.smallSpacing,
          runSpacing: AppConstants.smallSpacing,
          children: _searchService.popularSearches.map((query) {
            return ActionChip(
              label: Text(query),
              onPressed: () => _handleHistoryTap(query),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: AppConstants.massiveIconSize,
            color: Colors.grey[300],
          ),
          const SizedBox(height: AppConstants.standardSpacing),
          Text(
            '未找到相关结果',
            style: TextStyle(
              fontSize: AppConstants.largeFontSize,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppConstants.smallSpacing),
          Text(
            '尝试使用不同的关键词',
            style: TextStyle(
              fontSize: AppConstants.defaultFontSize,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.smallSpacing),
      itemCount: _searchService.results.length,
      itemBuilder: (context, index) {
        final result = _searchService.results[index];
        return GlobalSearchResultTile(
          result: result,
          query: _searchService.query,
          onTap: () => _handleResultTap(result),
        );
      },
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.standardSpacing),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: AppConstants.thinBorderWidth,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '找到 ${_searchService.results.length} 个结果',
            style: theme.textTheme.bodySmall,
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

/// 全局搜索结果项组件
class GlobalSearchResultTile extends StatelessWidget {
  final GlobalSearchResult result;
  final String query;
  final VoidCallback onTap;

  const GlobalSearchResultTile({
    super.key,
    required this.result,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: _buildLeadingIcon(context),
      title: _buildTitle(context),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.subtitle != null && result.subtitle!.isNotEmpty)
            Text(
              result.subtitle!,
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: AppConstants.tinySpacing),
          Text(
            result.getHighlightSnippet(query),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: _buildTrailing(context),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.standardSpacing,
        vertical: AppConstants.smallSpacing,
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (result.type) {
      case GlobalSearchResultType.note:
        icon = Icons.note;
        color = Colors.blue;
        break;
      case GlobalSearchResultType.character:
        icon = Icons.person;
        color = Colors.green;
        break;
      case GlobalSearchResultType.world:
        icon = Icons.public;
        color = Colors.purple;
        break;
      case GlobalSearchResultType.location:
        icon = Icons.place;
        color = Colors.orange;
        break;
      case GlobalSearchResultType.organization:
        icon = Icons.groups;
        color = Colors.red;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: AppConstants.mediumIconSize),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    final titleText = result.title;

    // 简单的高亮显示
    final List<TextSpan> spans = [];
    final lowerQuery = query.toLowerCase();
    final lowerTitle = titleText.toLowerCase();

    int lastIndex = 0;
    int index = lowerTitle.indexOf(lowerQuery);

    while (index != -1) {
      // 添加查询词之前的部分
      if (index > lastIndex) {
        spans.add(TextSpan(text: titleText.substring(lastIndex, index)));
      }

      // 添加高亮的查询词
      spans.add(TextSpan(
        text: titleText.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ));

      lastIndex = index + query.length;
      index = lowerTitle.indexOf(lowerQuery, lastIndex);
    }

    // 添加剩余部分
    if (lastIndex < titleText.length) {
      spans.add(TextSpan(text: titleText.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        children: spans.isEmpty ? [TextSpan(text: titleText)] : spans,
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    if (result.tags != null && result.tags!.isNotEmpty) {
      return Wrap(
        spacing: AppConstants.tinySpacing,
        runSpacing: AppConstants.tinySpacing,
        children: result.tags!.take(2).map((tag) {
          return Chip(
            label: Text(
              tag,
              style: const TextStyle(fontSize: 10),
            ),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      );
    }

    // 显示时间信息
    if (result.updatedAt != null || result.createdAt != null) {
      final time = result.updatedAt ?? result.createdAt;
      final timeDiff = time != null
          ? DateTime.now().difference(time)
          : const Duration(days: 365);

      String timeText;
      if (timeDiff.inDays > 365) {
        timeText = '1年前';
      } else if (timeDiff.inDays > 0) {
        timeText = '${timeDiff.inDays}天前';
      } else if (timeDiff.inHours > 0) {
        timeText = '${timeDiff.inHours}小时前';
      } else if (timeDiff.inMinutes > 0) {
        timeText = '${timeDiff.inMinutes}分钟前';
      } else {
        timeText = '刚刚';
      }

      return Text(
        timeText,
        style: TextStyle(
          fontSize: AppConstants.smallFontSize,
          color: Colors.grey[600],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// 快速搜索栏组件
class GlobalQuickSearch extends StatelessWidget {
  final String? hintText;
  final Function(GlobalSearchResult)? onResultSelected;

  const GlobalQuickSearch({
    super.key,
    this.hintText,
    this.onResultSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: hintText ?? '全局搜索...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.keyboard_arrow_down),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.mediumBorderRadius),
        ),
        filled: true,
      ),
      onTap: () {
        GlobalSearchDialog.show(context);
      },
    );
  }
}

/// 搜索结果类型图标组件
class SearchResultTypeIcon extends StatelessWidget {
  final GlobalSearchResultType type;

  const SearchResultTypeIcon({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case GlobalSearchResultType.note:
        icon = Icons.note;
        color = Colors.blue;
        break;
      case GlobalSearchResultType.character:
        icon = Icons.person;
        color = Colors.green;
        break;
      case GlobalSearchResultType.world:
        icon = Icons.public;
        color = Colors.purple;
        break;
      case GlobalSearchResultType.location:
        icon = Icons.place;
        color = Colors.orange;
        break;
      case GlobalSearchResultType.organization:
        icon = Icons.groups;
        color = Colors.red;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: AppConstants.mediumIconSize),
    );
  }
}

/// 搜索结果类型标签
class SearchResultTypeLabel extends StatelessWidget {
  final GlobalSearchResultType type;

  const SearchResultTypeLabel({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (type) {
      case GlobalSearchResultType.note:
        label = '笔记';
        color = Colors.blue;
        break;
      case GlobalSearchResultType.character:
        label = '角色';
        color = Colors.green;
        break;
      case GlobalSearchResultType.world:
        label = '世界观';
        color = Colors.purple;
        break;
      case GlobalSearchResultType.location:
        label = '地点';
        color = Colors.orange;
        break;
      case GlobalSearchResultType.organization:
        label = '组织';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallSpacing,
        vertical: AppConstants.tinySpacing,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppConstants.smallFontSize,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
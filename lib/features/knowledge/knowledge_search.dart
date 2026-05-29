import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'character_service.dart';
import 'character_model.dart';
import 'world_service.dart';
import 'world_model.dart';
import '../../config/app_constants.dart';

/// 搜索结果类型
enum SearchResultType {
  character,
  world,
  location,
  organization,
}

/// 搜索结果项
class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final dynamic data; // CharacterModel 或 WorldModel

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.data,
  });
}

/// 知识库搜索控制器
class KnowledgeSearchController extends ChangeNotifier {
  final CharacterService characterService;
  final WorldService worldService;

  String _query = '';
  List<SearchResult> _results = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  String get query => _query;
  List<SearchResult> get results => _results;
  bool get isSearching => _isSearching;
  bool get hasResults => _results.isNotEmpty;

  KnowledgeSearchController({
    required this.characterService,
    required this.worldService,
  });

  /// 执行搜索
  void search(String query) {
    _query = query;

    // 防抖处理
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppConstants.mediumDelay, () {
      _performSearch(query);
    });
  }

  /// 实际执行搜索
  void _performSearch(String query) {
    if (query.isEmpty) {
      _results.clear();
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final results = <SearchResult>[];

    // 搜索角色
    final characters = characterService.searchCharacters(query);
    for (final character in characters) {
      results.add(SearchResult(
        id: character.id,
        title: character.name,
        subtitle: _getCharacterSubtitle(character),
        type: SearchResultType.character,
        data: character,
      ));
    }

    // 搜索世界观
    final worlds = worldService.searchWorlds(query);
    for (final world in worlds) {
      results.add(SearchResult(
        id: world.id,
        title: world.name,
        subtitle:
            '${world.worldType}${world.era != null ? ' · ${world.era}' : ''}',
        type: SearchResultType.world,
        data: world,
      ));

      // 搜索世界观中的地点
      for (final location in world.locations) {
        if (location.name.toLowerCase().contains(query.toLowerCase()) ||
            location.description.toLowerCase().contains(query.toLowerCase())) {
          results.add(SearchResult(
            id: '${world.id}_location_${location.id}',
            title: location.name,
            subtitle: '${world.name} · 地点',
            type: SearchResultType.location,
            data: {'world': world, 'location': location},
          ));
        }
      }

      // 搜索世界观中的组织
      for (final org in world.organizations) {
        if (org.name.toLowerCase().contains(query.toLowerCase()) ||
            org.description.toLowerCase().contains(query.toLowerCase())) {
          results.add(SearchResult(
            id: '${world.id}_org_${org.id}',
            title: org.name,
            subtitle: '${world.name} · 组织',
            type: SearchResultType.organization,
            data: {'world': world, 'organization': org},
          ));
        }
      }
    }

    _results = results;
    _isSearching = false;
    notifyListeners();
  }

  /// 获取角色副标题
  String _getCharacterSubtitle(CharacterModel character) {
    final parts = <String>[];
    if (character.tags.isNotEmpty) {
      parts.add(character.tags.take(3).join('、'));
    }
    if (character.age != null) {
      parts.add('${character.age}岁');
    }
    return parts.join(' · ');
  }

  /// 清除搜索
  void clear() {
    _debounceTimer?.cancel();
    _query = '';
    _results.clear();
    _isSearching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// 搜索结果项组件
class SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const SearchResultTile({
    Key? key,
    required this.result,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (result.type) {
      case SearchResultType.character:
        icon = Icons.person;
        color = Colors.blue;
        break;
      case SearchResultType.world:
        icon = Icons.public;
        color = Colors.green;
        break;
      case SearchResultType.location:
        icon = Icons.place;
        color = Colors.orange;
        break;
      case SearchResultType.organization:
        icon = Icons.groups;
        color = Colors.purple;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        result.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: result.subtitle.isNotEmpty
          ? Text(
              result.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: onTap,
    );
  }
}

/// 知识库搜索对话框
class KnowledgeSearchDialog extends StatefulWidget {
  const KnowledgeSearchDialog({Key? key}) : super(key: key);

  @override
  State<KnowledgeSearchDialog> createState() => _KnowledgeSearchDialogState();

  /// 显示搜索对话框
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const KnowledgeSearchDialog(),
    );
  }
}

class _KnowledgeSearchDialogState extends State<KnowledgeSearchDialog> {
  late KnowledgeSearchController _controller;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = KnowledgeSearchController(
      characterService: context.read<CharacterService>(),
      worldService: context.read<WorldService>(),
    );
    _textController.addListener(() {
      _controller.search(_textController.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleResultTap(SearchResult result) {
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 搜索栏
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '搜索角色、世界观、地点、组织...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _textController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _textController.clear();
                            _controller.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // 搜索结果列表
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, child) {
                  if (_controller.isSearching) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (_controller.query.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '输入关键词开始搜索',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '支持搜索角色、世界观、地点和组织',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!_controller.hasResults) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '未找到相关结果',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: _controller.results.length,
                    itemBuilder: (context, index) {
                      final result = _controller.results[index];
                      return SearchResultTile(
                        result: result,
                        onTap: () => _handleResultTap(result),
                      );
                    },
                  );
                },
              ),
            ),

            // 底部操作栏
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 快速搜索栏组件
class KnowledgeQuickSearch extends StatelessWidget {
  final String? hintText;
  final Function(SearchResult)? onResultSelected;

  const KnowledgeQuickSearch({
    Key? key,
    this.hintText,
    this.onResultSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: hintText ?? '搜索知识库...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.keyboard_arrow_down),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onTap: () {
        KnowledgeSearchDialog.show(context);
      },
    );
  }
}

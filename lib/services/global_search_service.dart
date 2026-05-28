import '../utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import '../models/note.dart';
import '../services/secure_storage_service.dart';
import '../features/knowledge/character_service.dart';
import '../features/knowledge/world_service.dart';
import '../features/knowledge/character_model.dart';
import '../features/knowledge/world_model.dart';
import '../config/app_constants.dart';

/// 全局搜索结果类型
enum GlobalSearchResultType {
  note,
  character,
  world,
  location,
  organization,
}

/// 全局搜索结果项
class GlobalSearchResult {
  final String id;
  final String title;
  final String content;
  final String? subtitle;
  final GlobalSearchResultType type;
  final dynamic data;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? tags;

  GlobalSearchResult({
    required this.id,
    required this.title,
    required this.content,
    this.subtitle,
    required this.type,
    required this.data,
    this.createdAt,
    this.updatedAt,
    this.tags,
  });

  /// 获取高亮的内容片段
  String getHighlightSnippet(String query, {int maxLength = 150}) {
    final lowerQuery = query.toLowerCase();
    final lowerContent = content.toLowerCase();

    final index = lowerContent.indexOf(lowerQuery);
    if (index == -1) {
      return content.length > maxLength
          ? '${content.substring(0, maxLength)}...'
          : content;
    }

    final start = index > 20 ? index - 20 : 0;
    final end = (index + query.length + 80) < content.length
        ? index + query.length + 80
        : content.length;

    final prefix = start > 0 ? '...' : '';
    final suffix = end < content.length ? '...' : '';

    return '$prefix${content.substring(start, end)}$suffix';
  }
}

/// 搜索历史记录项
class SearchHistoryItem {
  final String query;
  final DateTime timestamp;
  final int resultCount;

  SearchHistoryItem({
    required this.query,
    required this.timestamp,
    required this.resultCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'result_count': resultCount,
    };
  }

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      resultCount: json['result_count'] as int,
    );
  }
}

/// 全局搜索服务
class GlobalSearchService extends ChangeNotifier {
  final SecureStorageService _storageService;
  final CharacterService _characterService;
  final WorldService _worldService;

  String _query = '';
  List<GlobalSearchResult> _results = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  List<SearchHistoryItem> _searchHistory = [];

  // 性能监控
  int _lastSearchDuration = 0;
  int _totalSearches = 0;
  int _totalResults = 0;
  final Map<GlobalSearchResultType, int> _lastSearchCounts = {};

  // 搜索缓存
  final Map<String, List<GlobalSearchResult>> _searchCache = {};
  static const int _maxCacheSize = 50;
  static const Duration _cacheExpiration = Duration(minutes:5);

  String get query => _query;
  List<GlobalSearchResult> get results => _results;
  bool get isSearching => _isSearching;
  bool get hasResults => _results.isNotEmpty;
  List<SearchHistoryItem> get searchHistory => _searchHistory;

  // 性能指标
  int get lastSearchDuration => _lastSearchDuration;
  int get totalSearches => _totalSearches;
  int get totalResults => _totalResults;
  Map<GlobalSearchResultType, int> get lastSearchCounts => Map.unmodifiable(_lastSearchCounts);

  // 按类型分组的结果
  Map<GlobalSearchResultType, List<GlobalSearchResult>> get groupedResults {
    final grouped = <GlobalSearchResultType, List<GlobalSearchResult>>{};

    for (final result in _results) {
      if (!grouped.containsKey(result.type)) {
        grouped[result.type] = [];
      }
      grouped[result.type]!.add(result);
    }

    return grouped;
  }

  GlobalSearchService({
    required SecureStorageService storageService,
    required CharacterService characterService,
    required WorldService worldService,
  }) : _storageService = storageService,
       _characterService = characterService,
       _worldService = worldService;

  /// 初始化服务
  Future<void> initialize() async {
    await _loadSearchHistory();
  }

  /// 执行搜索
  void search(String query) {
    _query = query;

    // 防抖处理
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppConstants.debounceDelay, () {
      _performSearch(query);
    });
  }

  /// 实际执行搜索（并行优化版本）
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      _results.clear();
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    _totalSearches++;

    try {
      // 检查缓存
      if (_searchCache.containsKey(query)) {
        _results = _searchCache[query]!;
        _lastSearchDuration = stopwatch.elapsedMilliseconds;
        _updateResultCounts();
        notifyListeners();
        Logger.debug('搜索命中缓存，耗时: $_lastSearchDuration ms');
        return;
      }

      // 并行搜索所有数据源
      final searchResults = await Future.wait([
        _searchNotes(query),
        _searchCharacters(query),
        _searchWorlds(query),
      ], eagerError: false).timeout(
        const Duration(seconds: 5),
        onTimeout: () => [],
      );

      // 合并结果
      final results = <GlobalSearchResult>[];
      for (final resultList in searchResults) {
        results.addAll(resultList);
      }

      // 按相关性排序
      _results = _sortByRelevance(results, query);

      // 更新缓存
      _updateCache(query, _results);

      // 添加到搜索历史
      await _addToSearchHistory(query, results.length);

    } catch (e) {
      Logger.debug('搜索过程中发生错误: $e');
      _results.clear();
    } finally {
      stopwatch.stop();
      _lastSearchDuration = stopwatch.elapsedMilliseconds;
      _totalResults += _results.length;
      _updateResultCounts();
      _isSearching = false;
      notifyListeners();
    }
  }

  /// 并行搜索笔记
  Future<List<GlobalSearchResult>> _searchNotes(String query) async {
    try {
      final notes = await _storageService.searchNotes(query);
      return notes.map((note) => GlobalSearchResult(
        id: note.id,
        title: note.title,
        content: note.content,
        subtitle: _getNoteSubtitle(note),
        type: GlobalSearchResultType.note,
        data: note,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
        tags: note.tags,
      )).toList();
    } catch (e) {
      Logger.debug('笔记搜索失败: $e');
      return [];
    }
  }

  /// 并行搜索角色
  Future<List<GlobalSearchResult>> _searchCharacters(String query) async {
    try {
      final characters = _characterService.searchCharacters(query);
      return characters.map((character) => GlobalSearchResult(
        id: character.id,
        title: character.name,
        content: _getCharacterContent(character),
        subtitle: _getCharacterSubtitle(character),
        type: GlobalSearchResultType.character,
        data: character,
        createdAt: character.createdAt,
        updatedAt: character.updatedAt,
        tags: character.tags,
      )).toList();
    } catch (e) {
      Logger.debug('角色搜索失败: $e');
      return [];
    }
  }

  /// 并行搜索世界观
  Future<List<GlobalSearchResult>> _searchWorlds(String query) async {
    try {
      final worlds = _worldService.searchWorlds(query);
      final results = <GlobalSearchResult>[];
      final lowerQuery = query.toLowerCase();

      for (final world in worlds) {
        results.add(GlobalSearchResult(
          id: world.id,
          title: world.name,
          content: _getWorldContent(world),
          subtitle: '${world.worldType}${world.era != null ? ' · ${world.era}' : ''}',
          type: GlobalSearchResultType.world,
          data: world,
          createdAt: world.createdAt,
          updatedAt: world.updatedAt,
          tags: world.tags,
        ));

        // 搜索世界观中的地点
        for (final location in world.locations) {
          if (location.name.toLowerCase().contains(lowerQuery) ||
              location.description.toLowerCase().contains(lowerQuery)) {
            results.add(GlobalSearchResult(
              id: '${world.id}_location_${location.id}',
              title: location.name,
              content: location.description,
              subtitle: '${world.name} · 地点',
              type: GlobalSearchResultType.location,
              data: {'world': world, 'location': location},
              tags: world.tags,
            ));
          }
        }

        // 搜索世界观中的组织
        for (final org in world.organizations) {
          if (org.name.toLowerCase().contains(lowerQuery) ||
              org.description.toLowerCase().contains(lowerQuery)) {
            results.add(GlobalSearchResult(
              id: '${world.id}_org_${org.id}',
              title: org.name,
              content: org.description,
              subtitle: '${world.name} · 组织',
              type: GlobalSearchResultType.organization,
              data: {'world': world, 'organization': org},
              tags: world.tags,
            ));
          }
        }
      }

      return results;
    } catch (e) {
      Logger.debug('世界观搜索失败: $e');
      return [];
    }
  }

  /// 按相关性排序
  List<GlobalSearchResult> _sortByRelevance(List<GlobalSearchResult> results, String query) {
    final lowerQuery = query.toLowerCase();

    return results..sort((a, b) {
      // 优先匹配标题
      final aTitleMatch = a.title.toLowerCase().contains(lowerQuery) ? 1 : 0;
      final bTitleMatch = b.title.toLowerCase().contains(lowerQuery) ? 1 : 0;

      if (aTitleMatch != bTitleMatch) {
        return bTitleMatch - aTitleMatch;
      }

      // 其次匹配内容
      final aContentIndex = a.content.toLowerCase().indexOf(lowerQuery);
      final bContentIndex = b.content.toLowerCase().indexOf(lowerQuery);

      if (aContentIndex != bContentIndex) {
        if (aContentIndex == -1) return 1;
        if (bContentIndex == -1) return -1;
        return aContentIndex.compareTo(bContentIndex);
      }

      // 最后按更新时间排序
      final aTime = a.updatedAt ?? a.createdAt ?? DateTime(0);
      final bTime = b.updatedAt ?? b.createdAt ?? DateTime(0);
      return bTime.compareTo(aTime);
    });
  }

  /// 更新结果数量统计
  void _updateResultCounts() {
    _lastSearchCounts.clear();
    for (final result in _results) {
      _lastSearchCounts[result.type] = (_lastSearchCounts[result.type] ?? 0) + 1;
    }
  }

  /// 更新搜索缓存
  void _updateCache(String query, List<GlobalSearchResult> results) {
    // 限制缓存大小
    if (_searchCache.length >= _maxCacheSize) {
      final firstKey = _searchCache.keys.first;
      _searchCache.remove(firstKey);
    }

    _searchCache[query] = results;

    // 设置缓存过期清理
    Future.delayed(_cacheExpiration, () {
      _searchCache.remove(query);
    });
  }

  /// 清除缓存
  void clearCache() {
    _searchCache.clear();
    Logger.debug('搜索缓存已清除');
  }

  /// 增量搜索（基于当前结果筛选）
  void incrementalSearch(String additionalQuery) {
    if (_query.isEmpty) {
      search(additionalQuery);
      return;
    }

    final combinedQuery = '$_query $additionalQuery';
    final lowerAdditionalQuery = additionalQuery.toLowerCase();

    final filteredResults = _results.where((result) =>
      result.title.toLowerCase().contains(lowerAdditionalQuery) ||
      result.content.toLowerCase().contains(lowerAdditionalQuery)
    ).toList();

    _query = combinedQuery;
    _results = filteredResults;
    notifyListeners();
  }

  /// 获取笔记副标题
  String _getNoteSubtitle(Note note) {
    final parts = <String>[];

    if (note.tags.isNotEmpty) {
      parts.add(note.tags.take(3).join('、'));
    }

    final timeDiff = DateTime.now().difference(note.updatedAt);
    if (timeDiff.inDays > 0) {
      parts.add('${timeDiff.inDays}天前');
    } else if (timeDiff.inHours > 0) {
      parts.add('${timeDiff.inHours}小时前');
    } else if (timeDiff.inMinutes > 0) {
      parts.add('${timeDiff.inMinutes}分钟前');
    }

    return parts.join(' · ');
  }

  /// 获取角色内容摘要
  String _getCharacterContent(CharacterModel character) {
    final parts = <String>[];

    if (character.background != null && character.background!.isNotEmpty) {
      parts.add(character.background!);
    }
    if (character.personality != null && character.personality!.isNotEmpty) {
      parts.add(character.personality!);
    }
    if (character.appearance != null && character.appearance!.isNotEmpty) {
      parts.add(character.appearance!);
    }

    return parts.join('\n');
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

  /// 获取世界观内容摘要
  String _getWorldContent(WorldModel world) {
    final parts = <String>[];

    if (world.history != null && world.history!.isNotEmpty) {
      parts.add(world.history!);
    }
    if (world.geography != null && world.geography!.isNotEmpty) {
      parts.add(world.geography!);
    }
    if (world.magicSystem != null && world.magicSystem!.isNotEmpty) {
      parts.add(world.magicSystem!);
    }

    return parts.join('\n');
  }

  /// 清除搜索
  void clear() {
    _debounceTimer?.cancel();
    _query = '';
    _results.clear();
    _isSearching = false;
    notifyListeners();
  }

  /// 添加到搜索历史
  Future<void> _addToSearchHistory(String query, int resultCount) async {
    // 移除重复项
    _searchHistory.removeWhere((item) => item.query == query);

    // 添加新项
    _searchHistory.insert(0, SearchHistoryItem(
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
    ));

    // 限制历史记录数量
    if (_searchHistory.length > 20) {
      _searchHistory = _searchHistory.take(20).toList();
    }

    await _saveSearchHistory();
    notifyListeners();
  }

  /// 从搜索历史中删除
  Future<void> removeFromHistory(int index) async {
    if (index >= 0 && index < _searchHistory.length) {
      _searchHistory.removeAt(index);
      await _saveSearchHistory();
      notifyListeners();
    }
  }

  /// 清空搜索历史
  Future<void> clearHistory() async {
    _searchHistory.clear();
    await _saveSearchHistory();
    notifyListeners();
  }

  /// 加载搜索历史
  Future<void> _loadSearchHistory() async {
    try {
      final historyJson = await _storageService.getSetting('search_history');
      if (historyJson.isNotEmpty) {
        final List<dynamic> historyList = _decodeJson(historyJson);
        _searchHistory = historyList
            .map((json) => SearchHistoryItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      Logger.debug('加载搜索历史失败: $e');
      _searchHistory.clear();
    }
  }

  /// 保存搜索历史
  Future<void> _saveSearchHistory() async {
    try {
      final historyJson = _encodeJson(_searchHistory.map((item) => item.toJson()).toList());
      await _storageService.setSetting('search_history', historyJson);
    } catch (e) {
      Logger.debug('保存搜索历史失败: $e');
    }
  }

  /// JSON 编码辅助方法
  String _encodeJson(dynamic data) {
    try {
      return json.encode(data);
    } catch (e) {
      Logger.debug('JSON编码失败: $e');
      return '[]';
    }
  }

  /// JSON 解码辅助方法
  dynamic _decodeJson(String jsonString) {
    try {
      return json.decode(jsonString);
    } catch (e) {
      Logger.debug('JSON解码失败: $e');
      return [];
    }
  }

  /// 获取热门搜索词
  List<String> get popularSearches {
    final frequency = <String, int>{};

    for (final item in _searchHistory) {
      frequency[item.query] = (frequency[item.query] ?? 0) + 1;
    }

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(10).map((e) => e.key).toList();
  }

  /// 获取性能统计信息
  Map<String, dynamic> getPerformanceStats() {
    return {
      'total_searches': _totalSearches,
      'total_results': _totalResults,
      'last_search_duration': _lastSearchDuration,
      'last_search_counts': _lastSearchCounts,
      'cache_size': _searchCache.length,
      'average_results_per_search': _totalSearches > 0
          ? (_totalResults / _totalSearches).toStringAsFixed(1)
          : '0.0',
    };
  }

  /// 重置性能统计
  void resetPerformanceStats() {
    _totalSearches = 0;
    _totalResults = 0;
    _lastSearchDuration = 0;
    _lastSearchCounts.clear();
    Logger.debug('性能统计已重置');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCache.clear();
    super.dispose();
  }
}
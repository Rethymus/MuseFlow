# MuseFlow 全局搜索服务 API 文档

## 服务概述

`GlobalSearchService` 是 MuseFlow 的核心搜索服务，提供统一的全局搜索功能，支持跨笔记、角色、世界观、地点和组织等多个数据源的并行搜索。服务采用防抖机制、搜索缓存、相关性排序等优化策略，确保高效的搜索体验。

## 核心 API

### GlobalSearchService

#### 初始化服务

```dart
// 创建服务实例
final searchService = GlobalSearchService(
  storageService: storageService,
  characterService: characterService,
  worldService: worldService,
);

// 初始化服务（加载搜索历史）
await searchService.initialize();
```

#### 执行搜索

```dart
// 基本搜索
searchService.search('魔法');

// 搜索会自动防抖处理，连续调用不会触发多次搜索
searchService.search('魔法体系');
searchService.search('魔法体系 中级');
// 最终只执行最后一次搜索
```

#### 增量搜索

```dart
// 基于当前结果进行增量筛选
searchService.search('角色');
// ...获取结果后...
searchService.incrementalSearch('法师');
// 相当于搜索 "角色 法师"，但在当前结果中筛选
```

#### 清除搜索

```dart
// 清除搜索状态和结果
searchService.clear();
```

#### 清除缓存

```dart
// 清除搜索缓存
searchService.clearCache();
```

## 状态属性

### 实时状态

```dart
// 当前搜索查询
String query = searchService.query;

// 搜索结果列表
List<GlobalSearchResult> results = searchService.results;

// 是否正在搜索
bool isSearching = searchService.isSearching;

// 是否有结果
bool hasResults = searchService.hasResults;
```

### 结果分组

```dart
// 按类型分组的结果
Map<GlobalSearchResultType, List<GlobalSearchResult>> grouped = searchService.groupedResults;

// 访问特定类型的结果
final notes = grouped[GlobalSearchResultType.note] ?? [];
final characters = grouped[GlobalSearchResultType.character] ?? [];
final worlds = grouped[GlobalSearchResultType.world] ?? [];
```

### 性能指标

```dart
// 最后一次搜索耗时（毫秒）
int duration = searchService.lastSearchDuration;

// 总搜索次数
int total = searchService.totalSearches;

// 总结果数量
int results = searchService.totalResults;

// 最后一次搜索各类型结果数量
Map<GlobalSearchResultType, int> counts = searchService.lastSearchCounts;
```

### 搜索历史

```dart
// 获取搜索历史
List<SearchHistoryItem> history = searchService.searchHistory;

// 获取热门搜索词
List<String> popular = searchService.popularSearches;
```

## 搜索历史管理

#### 删除历史记录

```dart
// 删除指定索引的历史记录
await searchService.removeFromHistory(0);

// 删除多个记录
await searchService.removeFromHistory(0);
await searchService.removeFromHistory(1);
```

#### 清空历史

```dart
// 清空所有搜索历史
await searchService.clearHistory();
```

## 性能监控

#### 获取性能统计

```dart
// 获取详细的性能统计信息
Map<String, dynamic> stats = searchService.getPerformanceStats();

// 统计信息包含：
// - total_searches: 总搜索次数
// - total_results: 总结果数量
// - last_search_duration: 最后一次搜索耗时（毫秒）
// - last_search_counts: 最后一次搜索各类型结果数量
// - cache_size: 当前缓存大小
// - average_results_per_search: 平均每次搜索结果数
```

#### 重置性能统计

```dart
// 重置性能统计数据
searchService.resetPerformanceStats();
```

## 数据类型

### GlobalSearchResultType

```dart
enum GlobalSearchResultType {
  note,           // 笔记
  character,      // 角色
  world,          // 世界观
  location,       // 地点
  organization,   // 组织
}
```

### GlobalSearchResult

```dart
class GlobalSearchResult {
  final String id;                         // 唯一标识符
  final String title;                      // 标题
  final String content;                    // 内容
  final String? subtitle;                  // 副标题
  final GlobalSearchResultType type;       // 结果类型
  final dynamic data;                       // 原始数据
  final DateTime? createdAt;              // 创建时间
  final DateTime? updatedAt;              // 更新时间
  final List<String>? tags;                // 标签列表

  // 获取高亮显示的内容片段
  String getHighlightSnippet(String query, {int maxLength = 150});
}
```

### SearchHistoryItem

```dart
class SearchHistoryItem {
  final String query;          // 搜索查询
  final DateTime timestamp;    // 时间戳
  final int resultCount;        // 结果数量

  // 序列化方法
  Map<String, dynamic> toJson();
  factory SearchHistoryItem.fromJson(Map<String, dynamic> json);
}
```

## 使用场景

### 场景1: 基本搜索

```dart
// 1. 初始化服务
final searchService = GlobalSearchService(
  storageService: myStorageService,
  characterService: myCharacterService,
  worldService: myWorldService,
);

await searchService.initialize();

// 2. 执行搜索
searchService.search('魔法');

// 3. 监听搜索状态
searchService.addListener(() {
  if (searchService.hasResults) {
    print('找到 ${searchService.results.length} 个结果');
    for (final result in searchService.results) {
      print('${result.title}: ${result.subtitle}');
    }
  }
});

// 4. 清除搜索
searchService.clear();
```

### 场景2: 结果分组显示

```dart
// 执行搜索
searchService.search('龙');

// 按类型分组显示结果
final grouped = searchService.groupedResults;

// 显示笔记
final notes = grouped[GlobalSearchResultType.note] ?? [];
print('笔记 (${notes.length}):');
for (final note in notes) {
  print('  - ${note.title}');
}

// 显示角色
final characters = grouped[GlobalSearchResultType.character] ?? [];
print('角色 (${characters.length}):');
for (final character in characters) {
  print('  - ${character.title}');
}

// 显示世界观
final worlds = grouped[GlobalSearchResultType.world] ?? [];
print('世界观 (${worlds.length}):');
for (final world in worlds) {
  print('  - ${world.title}');
}
```

### 场景3: 增量搜索

```dart
// 先进行广泛搜索
searchService.search('角色');

// 等待结果后，在当前结果中筛选
searchService.incrementalSearch('战士');

// 也可以继续筛选
searchService.incrementalSearch('人类');

// 最终相当于搜索 "角色 战士 人类"，但在每一步都筛选当前结果
```

### 场景4: 搜索历史管理

```dart
// 获取搜索历史
final history = searchService.searchHistory;

// 显示历史记录
for (final item in history) {
  print('${item.query} - ${item.resultCount} 个结果');
  print('  时间: ${item.timestamp}');
}

// 获取热门搜索
final popular = searchService.popularSearches;
print('热门搜索:');
for (final query in popular) {
  print('  - $query');
}

// 删除特定历史记录
await searchService.removeFromHistory(0);

// 清空所有历史
await searchService.clearHistory();
```

### 场景5: 性能监控

```dart
// 执行多次搜索
searchService.search('测试1');
searchService.search('测试2');
searchService.search('测试3');

// 获取性能统计
final stats = searchService.getPerformanceStats();
print('总搜索次数: ${stats['total_searches']}');
print('总结果数量: ${stats['total_results']}');
print('最后搜索耗时: ${stats['last_search_duration']} ms');
print('平均结果数: ${stats['average_results_per_search']}');
print('缓存大小: ${stats['cache_size']}');

// 重置统计
searchService.resetPerformanceStats();
```

### 场景6: 高亮显示搜索结果

```dart
// 执行搜索
searchService.search('古老的魔法');

// 处理搜索结果
for (final result in searchService.results) {
  // 获取高亮片段
  final snippet = result.getHighlightSnippet('古老的魔法');

  print('标题: ${result.title}');
  print('片段: $snippet');
  print('类型: ${result.type}');
  print('---');
}
```

## 性能考虑

### 时间复杂度

| 操作 | 复杂度 | 说明 |
|------|--------|------|
| search | O(1) | 触发防抖，实际搜索异步执行 |
| _performSearch | O(n) | n为所有数据源的总数据量 |
| _searchNotes | O(n) | n为笔记数量 |
| _searchCharacters | O(n) | n为角色数量 |
| _searchWorlds | O(n*m) | n为世界观数量，m为平均地点和组织数量 |
| _sortByRelevance | O(n log n) | n为总结果数量 |
| incrementalSearch | O(n) | n为当前结果数量 |
| clear | O(1) | 清除状态 |
| clearCache | O(1) | 清除缓存 |

### 空间复杂度

| 组件 | 空间复杂度 | 说明 |
|------|-----------|------|
| _searchCache | O(n*m) | n为缓存查询数，m为平均结果数 |
| _searchHistory | O(n) | n为历史记录数量（最多20） |
| _results | O(n) | n为当前结果数量 |

### 优化策略

1. **防抖处理**: 搜索输入自动防抖，避免频繁搜索
2. **并行搜索**: 同时搜索多个数据源，提高搜索速度
3. **搜索缓存**: 缓存最近50次搜索结果，5分钟过期
4. **增量搜索**: 在当前结果中筛选，避免重复搜索
5. **超时控制**: 搜索超时5秒自动返回

### 缓存策略

```dart
// 缓存配置
static const int _maxCacheSize = 50;              // 最大缓存数量
static const Duration _cacheExpiration = Duration(minutes: 5);  // 缓存过期时间

// 缓存使用
// 1. 自动缓存：每次搜索自动缓存结果
// 2. 自动清理：缓存满时删除最早的缓存
// 3. 自动过期：5分钟后自动删除缓存
// 4. 手动清理：调用 clearCache() 清除所有缓存
```

### 性能监控指标

```dart
// 实时性能指标
int lastSearchDuration;      // 最后一次搜索耗时
int totalSearches;           // 累计搜索次数
int totalResults;            // 累计结果数量
Map<GlobalSearchResultType, int> lastSearchCounts;  // 各类型结果数

// 性能统计
double averageResultsPerSearch = totalResults / totalSearches;
int cacheSize = _searchCache.length;
```

## 搜索算法

### 相关性排序

搜索结果按以下优先级排序：

1. **标题匹配**: 标题包含查询词的结果优先
2. **内容匹配**: 内容中较早出现查询词的结果优先
3. **时间排序**: 更新时间较新的结果优先

```dart
// 排序逻辑（伪代码）
results.sort((a, b) {
  // 1. 标题匹配优先
  if (a.title.contains(query) && !b.title.contains(query)) return -1;
  if (b.title.contains(query) && !a.title.contains(query)) return 1;

  // 2. 内容位置优先
  final aIndex = a.content.indexOf(query);
  final bIndex = b.content.indexOf(query);
  if (aIndex != bIndex) return aIndex.compareTo(bIndex);

  // 3. 时间优先
  return b.updatedAt.compareTo(a.updatedAt);
});
```

### 搜索范围

每个数据源的搜索范围：

| 数据源 | 搜索字段 |
|--------|---------|
| 笔记 | 标题、内容、标签 |
| 角色 | 名称、背景、性格、外貌、标签 |
| 世界观 | 名称、历史、地理、魔法系统、标签 |
| 地点 | 名称、描述 |
| 组织 | 名称、描述 |

## 最佳实践

### 1. 服务初始化

```dart
// 在应用启动时初始化
final searchService = GlobalSearchService(
  storageService: storageService,
  characterService: characterService,
  worldService: worldService,
);
await searchService.initialize();

// 在应用关闭时释放
searchService.dispose();
```

### 2. 响应式UI

```dart
// 使用 ValueListenableBuilder 或 AnimatedBuilder
ValueListenableBuilder(
  valueListenable: searchService,
  builder: (context, _, __) {
    if (searchService.isSearching) {
      return CircularProgressIndicator();
    }

    if (!searchService.hasResults) {
      return Text('没有结果');
    }

    return ListView.builder(
      itemCount: searchService.results.length,
      itemBuilder: (context, index) {
        final result = searchService.results[index];
        return SearchResultTile(result: result);
      },
    );
  },
);
```

### 3. 搜索输入优化

```dart
// 使用防抖的搜索输入
TextField(
  onChanged: (value) {
    // 每次输入都会触发防抖
    searchService.search(value);
  },
  decoration: InputDecoration(
    hintText: '搜索...',
    suffixIcon: searchService.isSearching
        ? CircularProgressIndicator()
        : Icon(Icons.search),
  ),
);
```

### 4. 错误处理

```dart
// 监听搜索状态
searchService.addListener(() {
  if (!searchService.isSearching && !searchService.hasResults) {
    // 搜索完成但没有结果
    if (searchService.query.isNotEmpty) {
      showSnackBar('没有找到相关结果');
    }
  }
});
```

### 5. 内存管理

```dart
// 定期清理缓存
if (searchService.getPerformanceStats()['cache_size'] > 40) {
  searchService.clearCache();
}

// 定期清理历史
if (searchService.searchHistory.length > 15) {
  await searchService.removeFromHistory(searchService.searchHistory.length - 1);
}
```

### 6. 性能优化

```dart
// 在后台预加载热门搜索
final popular = searchService.popularSearches;
for (final query in popular.take(5)) {
  searchService.search(query);
  await Future.delayed(Duration(milliseconds: 100));
}

// 使用增量搜索优化长查询
searchService.search('角色');
await Future.delayed(Duration(milliseconds: 500));
searchService.incrementalSearch('战士');
```

## 错误处理

### 常见错误处理

```dart
// 1. 搜索超时
// 自动处理：搜索超时5秒会返回空结果
// 监控：检查 lastSearchDuration

if (searchService.lastSearchDuration > 4000) {
  print('警告：搜索耗时过长');
}

// 2. 数据源错误
// 自动处理：单个数据源失败不影响其他数据源
// 日志：查看调试日志

// 3. 缓存错误
// 自动处理：缓存失败不影响搜索功能
// 恢复：调用 clearCache() 清除损坏的缓存

// 4. 历史记录错误
// 自动处理：历史记录失败不影响搜索功能
// 恢复：调用 clearHistory() 清除损坏的历史
```

## 扩展接口

### 自定义搜索策略

```dart
// 扩展 GlobalSearchService 以实现自定义搜索
class CustomGlobalSearchService extends GlobalSearchService {
  @override
  List<GlobalSearchResult> _sortByRelevance(
    List<GlobalSearchResult> results,
    String query,
  ) {
    // 实现自定义排序逻辑
    return results..sort((a, b) {
      // 自定义排序策略
      if (a.type == GlobalSearchResultType.note) return -1;
      if (b.type == GlobalSearchResultType.note) return 1;
      return 0;
    });
  }
}
```

### 自定义缓存策略

```dart
// 扩展 GlobalSearchService 以实现自定义缓存
class CachedGlobalSearchService extends GlobalSearchService {
  @override
  void _updateCache(String query, List<GlobalSearchResult> results) {
    // 实现自定义缓存逻辑
    // 例如：基于查询长度决定是否缓存
    if (query.length >= 2) {
      super._updateCache(query, results);
    }
  }
}
```

### 添加新的搜索数据源

```dart
// 扩展 GlobalSearchService 以添加新的数据源
class ExtendedGlobalSearchService extends GlobalSearchService {
  Future<List<GlobalSearchResult>> _searchCustomData(String query) async {
    // 实现自定义数据源搜索
    final customResults = await customDataSource.search(query);
    return customResults.map((item) => GlobalSearchResult(
      id: item.id,
      title: item.name,
      content: item.description,
      type: GlobalSearchResultType.note, // 或添加新类型
      data: item,
    )).toList();
  }

  @override
  Future<void> _performSearch(String query) async {
    // 先调用父类搜索
    await super._performSearch(query);

    // 然后添加自定义搜索结果
    final customResults = await _searchCustomData(query);
    _results.addAll(customResults);
    _results = _sortByRelevance(_results, query);
    notifyListeners();
  }
}
```

## 注意事项

1. **线程安全**: Dart 是单线程模型，所有操作都在主线程执行
2. **内存管理**: 使用完毕后调用 `dispose()` 释放资源
3. **搜索频率**: 防抖机制默认延迟为 `AppConstants.debounceDelay`
4. **缓存限制**: 最多缓存50次搜索结果，每次缓存5分钟过期
5. **历史限制**: 最多保存20条搜索历史记录
6. **超时限制**: 单次搜索超时时间为5秒
7. **并发限制**: 同一时间只能进行一次搜索
8. **数据更新**: 搜索结果不会自动更新，需要重新搜索

## 性能基准

### 预期性能指标

| 指标 | 预期值 | 说明 |
|------|--------|------|
| 搜索响应时间 | < 100ms | 缓存命中时 |
| 搜索响应时间 | < 500ms | 普通搜索（1000条数据） |
| 搜索响应时间 | < 2s | 大数据量搜索（10000条数据） |
| 内存占用 | < 50MB | 包括缓存和历史 |
| 缓存命中率 | > 30% | 热门搜索场景 |

### 优化建议

1. **启用缓存**: 对于频繁搜索，确保缓存机制正常工作
2. **增量搜索**: 对于长查询，使用增量搜索逐步筛选
3. **结果限制**: 对于大数据集，考虑限制返回结果数量
4. **预加载**: 应用启动时预加载热门搜索
5. **性能监控**: 定期检查性能指标，及时发现问题
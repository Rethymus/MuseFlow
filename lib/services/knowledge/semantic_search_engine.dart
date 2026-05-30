import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../features/knowledge/character_model.dart';
import '../../features/knowledge/world_model.dart';
import '../../utils/logger.dart';

/// 搜索结果项
class SearchResultItem {
  final String id;
  final String title;
  final String content;
  final String type; // 'character', 'world', 'location', 'organization'
  final double relevanceScore;
  final Map<String, dynamic> metadata;

  SearchResultItem({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.relevanceScore,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'relevanceScore': relevanceScore,
      'metadata': metadata,
    };
  }

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  String toString() {
    return 'SearchResultItem(id: $id, title: $title, relevance: $relevanceScore)';
  }
}

/// 向量嵌入接口（为未来向量数据库集成预留）
abstract class VectorEmbeddingInterface {
  /// 生成文本嵌入向量
  Future<List<double>> generateEmbedding(String text);

  /// 批量生成嵌入向量
  Future<List<List<double>>> generateBatchEmbeddings(List<String> texts);

  /// 计算向量相似度
  double calculateSimilarity(List<double> vec1, List<double> vec2);
}

/// 简单的TF-IDF嵌入实现（占位实现）
class SimpleTFIDFEmbedding implements VectorEmbeddingInterface {
  @override
  Future<List<double>> generateEmbedding(String text) async {
    // 简化的TF-IDF实现
    final words = text.toLowerCase().split(' ');
    final Map<String, int> wordCount = {};

    for (final word in words) {
      if (word.isNotEmpty) {
        wordCount[word] = (wordCount[word] ?? 0) + 1;
      }
    }

    // 生成固定大小的向量（这里简化为基于单词哈希的向量）
    const vectorSize = 100;
    final vector = List<double>.filled(vectorSize, 0.0);

    for (final entry in wordCount.entries) {
      final index = entry.key.hashCode.abs() % vectorSize;
      vector[index] += entry.value.toDouble();
    }

    // 归一化
    final magnitude = _calculateMagnitude(vector);
    if (magnitude > 0) {
      for (int i = 0; i < vectorSize; i++) {
        vector[i] /= magnitude;
      }
    }

    return vector;
  }

  @override
  Future<List<List<double>>> generateBatchEmbeddings(List<String> texts) async {
    final List<List<double>> embeddings = [];

    for (final text in texts) {
      final embedding = await generateEmbedding(text);
      embeddings.add(embedding);
    }

    return embeddings;
  }

  @override
  double calculateSimilarity(List<double> vec1, List<double> vec2) {
    if (vec1.length != vec2.length) {
      return 0.0;
    }

    return _cosineSimilarity(vec1, vec2);
  }

  double _cosineSimilarity(List<double> vec1, List<double> vec2) {
    double dotProduct = 0.0;
    double magnitude1 = 0.0;
    double magnitude2 = 0.0;

    for (int i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i];
      magnitude1 += vec1[i] * vec1[i];
      magnitude2 += vec2[i] * vec2[i];
    }

    final denominator = (magnitude1 * magnitude2).abs();
    if (denominator == 0) {
      return 0.0;
    }

    return dotProduct / denominator;
  }

  double _calculateMagnitude(List<double> vector) {
    double sum = 0.0;
    for (final value in vector) {
      sum += value * value;
    }
    return sum > 0 ? sqrt(sum) : 1.0;
  }
}

/// 多模态搜索查询
class MultimodalSearchQuery {
  final String textQuery;
  final String? imageQuery; // 图像数据的base64编码
  final String? audioQuery; // 音频查询的描述
  final List<String>? filters;
  final Map<String, dynamic>? parameters;

  MultimodalSearchQuery({
    required this.textQuery,
    this.imageQuery,
    this.audioQuery,
    this.filters,
    this.parameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'textQuery': textQuery,
      'imageQuery': imageQuery,
      'audioQuery': audioQuery,
      'filters': filters,
      'parameters': parameters,
    };
  }
}

/// 语义搜索引擎
class SemanticSearchEngine with ChangeNotifier {
  VectorEmbeddingInterface? _embeddingEngine;
  final Map<String, List<double>> _embeddingCache = {};

  // 索引数据
  final Map<String, List<SearchResultItem>> _characterIndex = {};
  final Map<String, List<SearchResultItem>> _worldIndex = {};
  final Map<String, List<SearchResultItem>> _locationIndex = {};
  final Map<String, List<SearchResultItem>> _organizationIndex = {};

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  int get indexedCharacterCount => _characterIndex.length;
  int get indexedWorldCount => _worldIndex.length;

  /// 初始化搜索引擎
  Future<void> initialize({
    VectorEmbeddingInterface? embeddingEngine,
  }) async {
    Logger.debug('初始化语义搜索引擎');

    // 如果没有提供嵌入引擎，使用简单的TF-IDF实现
    _embeddingEngine = embeddingEngine ?? SimpleTFIDFEmbedding();

    _isInitialized = true;
    notifyListeners();
  }

  /// 设置嵌入引擎（为未来向量数据库集成预留）
  void setEmbeddingEngine(VectorEmbeddingInterface engine) {
    _embeddingEngine = engine;
    Logger.debug('设置新的嵌入引擎');
    notifyListeners();
  }

  /// 索引角色数据
  Future<void> indexCharacters(List<CharacterModel> characters) async {
    if (!_isInitialized) {
      await initialize();
    }

    Logger.debug('索引 ${characters.length} 个角色');

    for (final character in characters) {
      await _indexCharacter(character);
    }

    Logger.debug('角色索引完成，共 ${_characterIndex.length} 项');
    notifyListeners();
  }

  /// 索引单个角色（公共接口）
  Future<void> indexCharacter(CharacterModel character) async {
    await _indexCharacter(character);
  }

  /// 索引单个角色
  Future<void> _indexCharacter(CharacterModel character) async {
    final List<SearchResultItem> items = [];

    // 主条目
    items.add(SearchResultItem(
      id: character.id,
      title: character.name,
      content: _buildCharacterContent(character),
      type: 'character',
      relevanceScore: 1.0,
      metadata: {
        'age': character.age,
        'tags': character.tags,
        'relationships': character.relationships,
      },
    ));

    // 为每个标签创建索引项
    for (final tag in character.tags) {
      items.add(SearchResultItem(
        id: '${character.id}_tag_$tag',
        title: tag,
        content: '标签: $tag (角色: ${character.name})',
        type: 'character_tag',
        relevanceScore: 0.8,
        metadata: {
          'characterId': character.id,
          'characterName': character.name,
          'tagType': 'character',
        },
      ));
    }

    // 为每个关系创建索引项
    for (final relationship in character.relationships) {
      items.add(SearchResultItem(
        id: '${character.id}_rel_${relationship.hashCode}',
        title: relationship,
        content: '关系: $relationship (角色: ${character.name})',
        type: 'character_relationship',
        relevanceScore: 0.7,
        metadata: {
          'characterId': character.id,
          'characterName': character.name,
          'relationshipType': 'character',
        },
      ));
    }

    _characterIndex[character.id] = items;

    // 生成并缓存嵌入向量
    final mainContent = _buildCharacterContent(character);
    final embedding = await _embeddingEngine!.generateEmbedding(mainContent);
    _embeddingCache[character.id] = embedding;
  }

  /// 索引世界观数据
  Future<void> indexWorlds(List<WorldModel> worlds) async {
    if (!_isInitialized) {
      await initialize();
    }

    Logger.debug('索引 ${worlds.length} 个世界观');

    for (final world in worlds) {
      await _indexWorld(world);
    }

    Logger.debug('世界观索引完成，共 ${_worldIndex.length} 项');
    notifyListeners();
  }

  /// 索引单个世界观
  Future<void> _indexWorld(WorldModel world) async {
    final List<SearchResultItem> items = [];

    // 主条目
    items.add(SearchResultItem(
      id: world.id,
      title: world.name,
      content: _buildWorldContent(world),
      type: 'world',
      relevanceScore: 1.0,
      metadata: {
        'worldType': world.worldType,
        'era': world.era,
        'tags': world.tags,
      },
    ));

    // 索引地点
    for (final location in world.locations) {
      items.add(SearchResultItem(
        id: location.id,
        title: location.name,
        content: location.description,
        type: 'location',
        relevanceScore: 0.9,
        metadata: {
          'worldId': world.id,
          'worldName': world.name,
          'relatedCharacters': location.relatedCharacters,
        },
      ));

      // 缓存地点嵌入
      final embedding =
          await _embeddingEngine!.generateEmbedding(location.description);
      _embeddingCache[location.id] = embedding;
    }

    // 索引组织
    for (final organization in world.organizations) {
      items.add(SearchResultItem(
        id: organization.id,
        title: organization.name,
        content: _buildOrganizationContent(organization),
        type: 'organization',
        relevanceScore: 0.9,
        metadata: {
          'worldId': world.id,
          'worldName': world.name,
          'leader': organization.leader,
          'members': organization.members,
        },
      ));

      // 缓存组织嵌入
      final content = _buildOrganizationContent(organization);
      final embedding = await _embeddingEngine!.generateEmbedding(content);
      _embeddingCache[organization.id] = embedding;
    }

    _worldIndex[world.id] = items;

    // 生成并缓存世界主嵌入
    final mainContent = _buildWorldContent(world);
    final embedding = await _embeddingEngine!.generateEmbedding(mainContent);
    _embeddingCache[world.id] = embedding;
  }

  /// 构建角色索引内容
  String _buildCharacterContent(CharacterModel character) {
    final buffer = StringBuffer();

    buffer.write(character.name);
    if (character.age != null) buffer.write(' ${character.age}岁');
    if (character.appearance != null) buffer.write(' ${character.appearance}');
    if (character.personality != null)
      buffer.write(' ${character.personality}');
    if (character.background != null) buffer.write(' ${character.background}');
    if (character.speakingStyle != null)
      buffer.write(' ${character.speakingStyle}');

    if (character.tags.isNotEmpty) {
      buffer.write(' 标签: ${character.tags.join(' ')}');
    }

    if (character.relationships.isNotEmpty) {
      buffer.write(' 关系: ${character.relationships.join(' ')}');
    }

    return buffer.toString();
  }

  /// 构建世界观索引内容
  String _buildWorldContent(WorldModel world) {
    final buffer = StringBuffer();

    buffer.write('${world.name} ${world.worldType}');
    if (world.era != null) buffer.write(' ${world.era}');
    if (world.magicSystem != null) buffer.write(' ${world.magicSystem}');
    if (world.technology != null) buffer.write(' ${world.technology}');
    if (world.geography != null) buffer.write(' ${world.geography}');
    if (world.history != null) buffer.write(' ${world.history}');

    if (world.rules.isNotEmpty) {
      buffer.write(' 规则: ${world.rules.join(' ')}');
    }

    if (world.tags.isNotEmpty) {
      buffer.write(' 标签: ${world.tags.join(' ')}');
    }

    return buffer.toString();
  }

  /// 构建组织索引内容
  String _buildOrganizationContent(Organization organization) {
    final buffer = StringBuffer();

    buffer.write('${organization.name} ${organization.description}');
    if (organization.leader != null)
      buffer.write(' 领导: ${organization.leader}');
    if (organization.philosophy != null)
      buffer.write(' 理念: ${organization.philosophy}');
    if (organization.members.isNotEmpty) {
      buffer.write(' 成员: ${organization.members.join(' ')}');
    }

    return buffer.toString();
  }

  /// 语义搜索
  Future<List<SearchResultItem>> semanticSearch(
    String query, {
    int limit = 10,
    double threshold = 0.3,
    List<String>? types,
  }) async {
    if (!_isInitialized || _embeddingEngine == null) {
      Logger.debug('搜索引擎未初始化');
      return [];
    }

    Logger.debug('执行语义搜索: "$query"');

    // 生成查询嵌入
    final queryEmbedding = await _embeddingEngine!.generateEmbedding(query);

    // 收集所有候选结果
    final List<SearchResultItem> candidates = [];
    candidates.addAll(_characterIndex.values.expand((items) => items));
    candidates.addAll(_worldIndex.values.expand((items) => items));

    // 计算相似度
    final List<SearchResultItem> results = [];
    for (final candidate in candidates) {
      // 类型过滤
      if (types != null && !types.contains(candidate.type)) {
        continue;
      }

      // 获取候选嵌入
      final candidateEmbedding = _embeddingCache[candidate.id];
      if (candidateEmbedding == null) {
        continue;
      }

      // 计算相似度
      final similarity = _embeddingEngine!.calculateSimilarity(
        queryEmbedding,
        candidateEmbedding,
      );

      if (similarity >= threshold) {
        results.add(SearchResultItem(
          id: candidate.id,
          title: candidate.title,
          content: candidate.content,
          type: candidate.type,
          relevanceScore: similarity,
          metadata: candidate.metadata,
        ));
      }
    }

    // 按相关性排序
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    // 返回前N个结果
    return results.take(limit).toList();
  }

  /// 多模态搜索
  Future<List<SearchResultItem>> multimodalSearch(
    MultimodalSearchQuery query, {
    int limit = 10,
    double threshold = 0.3,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    Logger.debug('执行多模态搜索: "${query.textQuery}"');

    // 目前主要基于文本搜索，为多模态预留接口
    final results = await semanticSearch(
      query.textQuery,
      limit: limit,
      threshold: threshold,
      types: query.filters,
    );

    // 这里可以添加图像、音频等模态的处理逻辑
    // 当添加向量数据库集成时，可以扩展此方法

    return results;
  }

  /// 混合搜索（结合语义和关键词搜索）
  Future<List<SearchResultItem>> hybridSearch(
    String query, {
    int limit = 10,
    double semanticWeight = 0.7,
    double keywordWeight = 0.3,
  }) async {
    Logger.debug('执行混合搜索: "$query"');

    // 获取语义搜索结果
    final semanticResults = await semanticSearch(query, limit: limit * 2);
    final semanticScores = <String, double>{};
    for (final result in semanticResults) {
      semanticScores[result.id] = result.relevanceScore;
    }

    // 获取关键词搜索结果
    final keywordResults = _keywordSearch(query, limit: limit * 2);
    final keywordScores = <String, double>{};
    for (final result in keywordResults) {
      keywordScores[result.id] = result.relevanceScore;
    }

    // 合并结果
    final Map<String, SearchResultItem> combinedResults = {};
    final Set<String> allIds = {...semanticScores.keys, ...keywordScores.keys};

    for (final id in allIds) {
      final semanticScore = semanticScores[id] ?? 0.0;
      final keywordScore = keywordScores[id] ?? 0.0;

      // 归一化分数
      final normalizedSemantic = semanticScore;
      final normalizedKeyword = keywordScore;

      // 加权组合
      final combinedScore = (normalizedSemantic * semanticWeight) +
          (normalizedKeyword * keywordWeight);

      // 获取原始结果项
      SearchResultItem? originalItem;
      if (semanticScores.containsKey(id)) {
        originalItem = semanticResults.firstWhere((r) => r.id == id);
      } else {
        originalItem = keywordResults.firstWhere((r) => r.id == id);
      }

      if (originalItem != null) {
        combinedResults[id] = SearchResultItem(
          id: originalItem.id,
          title: originalItem.title,
          content: originalItem.content,
          type: originalItem.type,
          relevanceScore: combinedScore,
          metadata: originalItem.metadata,
        );
      }
    }

    // 排序并返回
    final sortedResults = combinedResults.values.toList()
      ..sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return sortedResults.take(limit).toList();
  }

  /// 关键词搜索（后备方法）
  List<SearchResultItem> _keywordSearch(String query, {int limit = 10}) {
    final lowerQuery = query.toLowerCase();
    final List<SearchResultItem> results = [];

    // 收集所有候选结果
    final List<SearchResultItem> candidates = [];
    candidates.addAll(_characterIndex.values.expand((items) => items));
    candidates.addAll(_worldIndex.values.expand((items) => items));

    // 计算关键词匹配分数
    for (final candidate in candidates) {
      double score = 0.0;

      // 标题匹配（权重更高）
      if (candidate.title.toLowerCase().contains(lowerQuery)) {
        score += 0.8;
      }

      // 内容匹配
      if (candidate.content.toLowerCase().contains(lowerQuery)) {
        score += 0.5;
      }

      // 标签匹配
      final tags = candidate.metadata['tags'] as List<dynamic>?;
      if (tags != null) {
        for (final tag in tags) {
          if (tag.toString().toLowerCase().contains(lowerQuery)) {
            score += 0.3;
          }
        }
      }

      if (score > 0) {
        results.add(SearchResultItem(
          id: candidate.id,
          title: candidate.title,
          content: candidate.content,
          type: candidate.type,
          relevanceScore: score.clamp(0.0, 1.0),
          metadata: candidate.metadata,
        ));
      }
    }

    // 排序并返回
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results.take(limit).toList();
  }

  /// 获取相似内容
  Future<List<SearchResultItem>> findSimilar(
    String itemId, {
    int limit = 5,
    double threshold = 0.5,
  }) async {
    Logger.debug('查找与 $itemId 相似的内容');

    final itemEmbedding = _embeddingCache[itemId];
    if (itemEmbedding == null || _embeddingEngine == null) {
      return [];
    }

    final List<SearchResultItem> similarItems = [];

    // 收集所有候选结果
    final List<SearchResultItem> candidates = [];
    candidates.addAll(_characterIndex.values.expand((items) => items));
    candidates.addAll(_worldIndex.values.expand((items) => items));

    for (final candidate in candidates) {
      if (candidate.id == itemId) continue;

      final candidateEmbedding = _embeddingCache[candidate.id];
      if (candidateEmbedding == null) continue;

      final similarity = _embeddingEngine!.calculateSimilarity(
        itemEmbedding,
        candidateEmbedding,
      );

      if (similarity >= threshold) {
        similarItems.add(SearchResultItem(
          id: candidate.id,
          title: candidate.title,
          content: candidate.content,
          type: candidate.type,
          relevanceScore: similarity,
          metadata: candidate.metadata,
        ));
      }
    }

    // 排序并返回
    similarItems.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return similarItems.take(limit).toList();
  }

  /// 获取搜索建议
  List<String> getSearchSuggestions(String partialQuery, {int limit = 5}) {
    if (partialQuery.isEmpty) return [];

    final lowerQuery = partialQuery.toLowerCase();
    final Set<String> suggestions = {};

    // 从角色名称中获取建议
    for (final items in _characterIndex.values) {
      for (final item in items) {
        if (item.type == 'character' &&
            item.title.toLowerCase().contains(lowerQuery)) {
          suggestions.add(item.title);
        }
        if (item.type == 'character_tag' &&
            item.title.toLowerCase().contains(lowerQuery)) {
          suggestions.add(item.title);
        }
      }
    }

    // 从世界观中获取建议
    for (final items in _worldIndex.values) {
      for (final item in items) {
        if ((item.type == 'world' ||
                item.type == 'location' ||
                item.type == 'organization') &&
            item.title.toLowerCase().contains(lowerQuery)) {
          suggestions.add(item.title);
        }
      }
    }

    return suggestions.toList()..take(limit);
  }

  /// 清空索引
  Future<void> clearIndex() async {
    _characterIndex.clear();
    _worldIndex.clear();
    _locationIndex.clear();
    _organizationIndex.clear();
    _embeddingCache.clear();
    notifyListeners();
    Logger.debug('搜索索引已清空');
  }

  /// 获取索引统计信息
  Map<String, dynamic> getIndexStatistics() {
    int totalItems = 0;
    totalItems +=
        _characterIndex.values.fold(0, (sum, items) => sum + items.length);
    totalItems +=
        _worldIndex.values.fold(0, (sum, items) => sum + items.length);
    totalItems +=
        _locationIndex.values.fold(0, (sum, items) => sum + items.length);
    totalItems +=
        _organizationIndex.values.fold(0, (sum, items) => sum + items.length);

    return {
      'isInitialized': _isInitialized,
      'indexedCharacters': _characterIndex.length,
      'indexedWorlds': _worldIndex.length,
      'indexedLocations': _locationIndex.length,
      'indexedOrganizations': _organizationIndex.length,
      'totalItems': totalItems,
      'cachedEmbeddings': _embeddingCache.length,
      'embeddingEngineType': _embeddingEngine.runtimeType.toString(),
    };
  }

  @override
  void dispose() {
    clearIndex();
    super.dispose();
  }
}

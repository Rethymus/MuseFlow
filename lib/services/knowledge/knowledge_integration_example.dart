import '../../features/knowledge/character_service.dart';
import '../../features/knowledge/world_service.dart';
import 'knowledge_graph_engine.dart';
import 'semantic_search_engine.dart';

/// 知识管理深度增强功能集成示例
///
/// 这个文件展示了如何将知识图谱引擎和语义搜索引擎集成到现有的知识管理系统中
class KnowledgeIntegrationManager {
  final CharacterService characterService;
  final WorldService worldService;
  late final KnowledgeGraphEngine knowledgeGraph;
  late final SemanticSearchEngine semanticSearch;

  bool _isInitialized = false;

  KnowledgeIntegrationManager({
    required this.characterService,
    required this.worldService,
  });

  /// 初始化集成管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 初始化知识图谱引擎
    knowledgeGraph = KnowledgeGraphEngine();
    await knowledgeGraph.initialize();

    // 初始化语义搜索引擎
    semanticSearch = SemanticSearchEngine();
    await semanticSearch.initialize();

    // 连接服务和引擎
    characterService.setKnowledgeGraphEngine(knowledgeGraph);
    characterService.setSemanticSearchEngine(semanticSearch);
    worldService.setKnowledgeGraphEngine(knowledgeGraph);
    worldService.setSemanticSearchEngine(semanticSearch);

    _isInitialized = true;
  }

  /// 构建完整的知识图谱
  Future<void> buildCompleteKnowledgeGraph() async {
    if (!_isInitialized) {
      await initialize();
    }

    // 从角色构建知识图谱
    await knowledgeGraph.buildFromCharacters(characterService.characters);

    // 从世界观构建知识图谱
    await knowledgeGraph.buildFromWorlds(worldService.worlds);

    print(
        '知识图谱构建完成: ${knowledgeGraph.nodeCount} 个节点, ${knowledgeGraph.edgeCount} 条边');
  }

  /// 构建语义搜索索引
  Future<void> buildSemanticSearchIndex() async {
    if (!_isInitialized) {
      await initialize();
    }

    // 索引所有角色
    await semanticSearch.indexCharacters(characterService.characters);

    // 索引所有世界观
    await semanticSearch.indexWorlds(worldService.worlds);

    final stats = semanticSearch.getIndexStatistics();
    print('语义搜索索引构建完成: ${stats['totalItems']} 个项目');
  }

  /// 执行全面的关系发现
  Future<List<Map<String, dynamic>>> discoverAllRelationships() async {
    if (!_isInitialized) {
      await initialize();
    }

    // 发现角色之间的关系
    final characterRelationships =
        await characterService.discoverRelationships();

    // 这里可以添加更多类型的关系发现
    // 例如：角色与世界之间的关系，地点与角色之间的关系等

    return characterRelationships;
  }

  /// 执行智能语义搜索
  Future<List<Map<String, dynamic>>> intelligentSearch(
    String query, {
    int limit = 10,
    bool useHybridSearch = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (useHybridSearch) {
      // 使用混合搜索（语义 + 关键词）
      final characterResults = await characterService.semanticSearchCharacters(
        query,
        limit: limit,
      );

      final worldResults = await worldService.semanticSearchWorlds(
        query,
        limit: limit,
      );

      // 合并结果
      final allResults = [...characterResults, ...worldResults];
      allResults.sort((a, b) => (b['relevanceScore'] as double)
          .compareTo(a['relevanceScore'] as double));

      return allResults.take(limit).toList();
    } else {
      // 仅使用语义搜索
      final searchResults =
          await semanticSearch.semanticSearch(query, limit: limit);
      return searchResults.map((result) => result.toJson()).toList();
    }
  }

  /// 获取角色关联推荐
  List<Map<String, dynamic>> getCharacterRecommendations(String characterId) {
    if (!_isInitialized) {
      throw Exception('Integration manager not initialized');
    }

    return characterService.getRelationshipRecommendations(characterId);
  }

  /// 生成知识网络可视化数据
  Map<String, dynamic> generateVisualizationData({
    String? focusNodeId,
    int maxDepth = 2,
  }) {
    if (!_isInitialized) {
      throw Exception('Integration manager not initialized');
    }

    return knowledgeGraph.generateVisualizationData(
      focusNodeId: focusNodeId,
      maxDepth: maxDepth,
    );
  }

  /// 查找知识路径
  List<String> findKnowledgePath(String startId, String endId) {
    if (!_isInitialized) {
      throw Exception('Integration manager not initialized');
    }

    return knowledgeGraph.findShortestPath(startId, endId);
  }

  /// 获取相似内容
  Future<List<Map<String, dynamic>>> findSimilarContent(
    String itemId, {
    int limit = 5,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 尝试从角色中查找
    final similarCharacters = await characterService.findSimilarCharacters(
      itemId,
      limit: limit,
    );

    if (similarCharacters.isNotEmpty) {
      return similarCharacters;
    }

    // 尝试从世界观中查找
    final similarWorlds = await worldService.findSimilarWorlds(
      itemId,
      limit: limit,
    );

    return similarWorlds;
  }

  /// 导出知识图谱数据
  Map<String, dynamic> exportKnowledgeGraph() {
    if (!_isInitialized) {
      throw Exception('Integration manager not initialized');
    }

    return knowledgeGraph.exportGraph();
  }

  /// 导入知识图谱数据
  Future<void> importKnowledgeGraph(Map<String, dynamic> data) async {
    if (!_isInitialized) {
      await initialize();
    }

    await knowledgeGraph.importGraph(data);
  }

  /// 获取系统统计信息
  Map<String, dynamic> getSystemStatistics() {
    if (!_isInitialized) {
      throw Exception('Integration manager not initialized');
    }

    final graphStats = {
      'nodes': knowledgeGraph.nodeCount,
      'edges': knowledgeGraph.edgeCount,
    };

    final searchStats = semanticSearch.getIndexStatistics();

    return {
      'knowledgeGraph': graphStats,
      'semanticSearch': searchStats,
      'characters': characterService.characterCount,
      'worlds': worldService.worldCount,
    };
  }

  /// 清理资源
  Future<void> dispose() async {
    await knowledgeGraph.clear();
    await semanticSearch.clearIndex();
    _isInitialized = false;
  }
}

// 使用示例：
/*
void main() async {
  // 假设已经有初始化的服务
  final characterService = CharacterService();
  final worldService = WorldService();

  await characterService.initialize();
  await worldService.initialize();

  // 创建集成管理器
  final integrationManager = KnowledgeIntegrationManager(
    characterService: characterService,
    worldService: worldService,
  );

  // 初始化
  await integrationManager.initialize();

  // 构建知识图谱
  await integrationManager.buildCompleteKnowledgeGraph();

  // 构建搜索索引
  await integrationManager.buildSemanticSearchIndex();

  // 执行智能搜索
  final searchResults = await integrationManager.intelligentSearch('勇敢的骑士');
  print('搜索结果: ${searchResults.length} 条');

  // 获取关联推荐
  final recommendations = integrationManager.getCharacterRecommendations('character_id');
  print('推荐关联: ${recommendations.length} 条');

  // 生成可视化数据
  final visualizationData = integrationManager.generateVisualizationData(
    focusNodeId: 'character_id',
    maxDepth: 2,
  );

  // 清理
  await integrationManager.dispose();
}
*/

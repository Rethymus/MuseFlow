import '../../features/knowledge/character_model.dart';
import '../../features/knowledge/world_model.dart';
import 'knowledge_graph_engine.dart';
import 'semantic_search_engine.dart';
import 'package:uuid/uuid.dart';

/// 知识管理功能测试
///
/// 用于验证知识图谱引擎和语义搜索引擎的基本功能
class KnowledgeFeatureTest {
  /// 测试知识图谱引擎
  static Future<Map<String, dynamic>> testKnowledgeGraphEngine() async {
    final results = <String, dynamic>{};
    final engine = KnowledgeGraphEngine();

    try {
      // 1. 初始化测试
      await engine.initialize();
      results['initialization'] = 'PASSED';

      // 2. 创建测试数据
      final characters = [
        CharacterModel(
          id: const Uuid().v4(),
          name: '亚瑟',
          age: 25,
          personality: '勇敢、正直、有领导力',
          background: '年轻的骑士，立志成为传奇英雄',
          tags: ['骑士', '英雄', '主角'],
          relationships: ['梅林的弟子', '桂妮薇儿的守护者'],
        ),
        CharacterModel(
          id: const Uuid().v4(),
          name: '梅林',
          age: 150,
          personality: '智慧、神秘、幽默',
          background: '传奇巫师，亚瑟的导师',
          tags: ['巫师', '导师', '魔法'],
          relationships: ['亚瑟的导师', '魔法师'],
        ),
        CharacterModel(
          id: const Uuid().v4(),
          name: '兰斯洛特',
          age: 28,
          personality: '勇敢、忠诚、浪漫',
          background: '最伟大的骑士，亚瑟的朋友',
          tags: ['骑士', '勇敢', '忠诚'],
          relationships: ['亚瑟的朋友', '圆桌骑士'],
        ),
      ];

      final worlds = [
        WorldModel(
          id: const Uuid().v4(),
          name: '卡米洛特王国',
          worldType: '奇幻',
          era: '中世纪',
          magicSystem: '古典魔法',
          technology: '原始中世纪技术',
          rules: ['荣誉至上', '保护弱者', '忠诚于国王'],
          locations: [
            Location(
              id: const Uuid().v4(),
              name: '卡米洛特城堡',
              description: '宏伟的城堡，亚瑟王的王座所在地',
              relatedCharacters: ['亚瑟', '桂妮薇儿'],
            ),
            Location(
              id: const Uuid().v4(),
              name: '魔法森林',
              description: '神秘的森林，梅林的居所',
              relatedCharacters: ['梅林'],
            ),
          ],
          organizations: [
            Organization(
              id: const Uuid().v4(),
              name: '圆桌骑士团',
              description: '最伟大的骑士组织',
              leader: '亚瑟',
              members: ['兰斯洛特', '高文', '特里斯坦'],
              philosophy: '荣誉、勇气、忠诚',
            ),
          ],
          tags: ['中世纪', '骑士', '魔法'],
        ),
      ];

      // 3. 构建知识图谱
      await engine.buildFromCharacters(characters);
      await engine.buildFromWorlds(worlds);

      results['graphConstruction'] = 'PASSED';
      results['nodeCount'] = engine.nodeCount;
      results['edgeCount'] = engine.edgeCount;

      // 4. 测试关系推荐
      if (engine.nodeCount > 0) {
        final firstNodeId = characters[0].id;
        final recommendations = engine.generateRecommendations(firstNodeId);
        results['relationshipRecommendations'] = 'PASSED';
        results['recommendationCount'] = recommendations.length;
      }

      // 5. 测试可视化数据生成
      final vizData = engine.generateVisualizationData(
        focusNodeId: characters[0].id,
        maxDepth: 1,
      );

      results['visualizationData'] = 'PASSED';
      results['visibleNodes'] = vizData['metadata']['visibleNodes'];
      results['visibleEdges'] = vizData['metadata']['visibleEdges'];

      // 6. 测试路径查找
      if (characters.length >= 2) {
        final path = engine.findShortestPath(
          characters[0].id,
          characters[1].id,
        );
        results['pathFinding'] = 'PASSED';
        results['pathLength'] = path.length;
      }

      // 7. 测试导出/导入
      final exportedGraph = engine.exportGraph();
      await engine.importGraph(exportedGraph);
      results['exportImport'] = 'PASSED';
    } catch (e) {
      results['error'] = e.toString();
      return results;
    }

    return results;
  }

  /// 测试语义搜索引擎
  static Future<Map<String, dynamic>> testSemanticSearchEngine() async {
    final results = <String, dynamic>{};
    final engine = SemanticSearchEngine();

    try {
      // 1. 初始化测试
      await engine.initialize();
      results['initialization'] = 'PASSED';

      // 2. 创建测试数据
      final characters = [
        CharacterModel(
          id: const Uuid().v4(),
          name: '哈利·波特',
          age: 17,
          personality: '勇敢、好奇、重友情',
          background: '年轻的巫师，对抗伏地魔的英雄',
          tags: ['巫师', '英雄', '格兰芬多'],
          relationships: ['罗恩的朋友', '赫敏的朋友'],
        ),
        CharacterModel(
          id: const Uuid().v4(),
          name: '赫敏·格兰杰',
          age: 17,
          personality: '聪明、勤奋、逻辑强',
          background: '麻瓜出身的最优秀女巫师',
          tags: ['巫师', '聪明', '格兰芬多'],
          relationships: ['哈利的朋友', '罗恩的朋友'],
        ),
      ];

      final worlds = [
        WorldModel(
          id: const Uuid().v4(),
          name: '霍格沃茨魔法学校',
          worldType: '奇幻',
          era: '现代',
          magicSystem: '现代魔法',
          technology: '魔法+科技',
          rules: ['校规', '魔法法律'],
          locations: [
            Location(
              id: const Uuid().v4(),
              name: '大礼堂',
              description: '学生用餐和聚会的地方',
              relatedCharacters: [],
            ),
          ],
          organizations: [
            Organization(
              id: const Uuid().v4(),
              name: '凤凰社',
              description: '对抗伏地魔的秘密组织',
              leader: '邓布利多',
              members: ['哈利', '赫敏', '罗恩'],
              philosophy: '正义与勇气',
            ),
          ],
          tags: ['魔法', '学校', '英国'],
        ),
      ];

      // 3. 索引数据
      await engine.indexCharacters(characters);
      await engine.indexWorlds(worlds);

      results['indexing'] = 'PASSED';
      results['indexedCharacters'] = engine.indexedCharacterCount;
      results['indexedWorlds'] = engine.indexedWorldCount;

      // 4. 测试语义搜索
      final searchResults = await engine.semanticSearch('勇敢的巫师', limit: 5);
      results['semanticSearch'] = 'PASSED';
      results['searchResultCount'] = searchResults.length;

      // 5. 测试混合搜索
      final hybridResults = await engine.hybridSearch('哈利的朋友', limit: 5);
      results['hybridSearch'] = 'PASSED';
      results['hybridResultCount'] = hybridResults.length;

      // 6. 测试相似内容查找
      if (characters.isNotEmpty) {
        final similarItems = await engine.findSimilar(
          characters[0].id,
          limit: 3,
        );
        results['similarContent'] = 'PASSED';
        results['similarItemCount'] = similarItems.length;
      }

      // 7. 测试搜索建议
      final suggestions = engine.getSearchSuggestions('哈', limit: 5);
      results['searchSuggestions'] = 'PASSED';
      results['suggestionCount'] = suggestions.length;

      // 8. 获取索引统计
      final stats = engine.getIndexStatistics();
      results['indexStatistics'] = 'PASSED';
      results['totalIndexedItems'] = stats['totalItems'];
    } catch (e) {
      results['error'] = e.toString();
      return results;
    }

    return results;
  }

  /// 运行完整测试套件
  static Future<Map<String, dynamic>> runFullTest() async {
    print('开始知识管理功能测试...');

    final testResults = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
    };

    // 测试知识图谱引擎
    print('测试知识图谱引擎...');
    final graphResults = await testKnowledgeGraphEngine();
    testResults['tests']['knowledgeGraph'] = graphResults;
    print('知识图谱引擎测试完成: ${graphResults['error'] == null ? "成功" : "失败"}');

    // 测试语义搜索引擎
    print('测试语义搜索引擎...');
    final searchResults = await testSemanticSearchEngine();
    testResults['tests']['semanticSearch'] = searchResults;
    print('语义搜索引擎测试完成: ${searchResults['error'] == null ? "成功" : "失败"}');

    // 计算总体结果
    int totalTests = 0;
    int passedTests = 0;

    for (final testCategory in testResults['tests'].values) {
      if (testCategory is Map<String, dynamic>) {
        for (final key in testCategory.keys) {
          if (key != 'error' && key != 'nodeCount' && key != 'edgeCount') {
            totalTests++;
            if (testCategory[key] == 'PASSED') {
              passedTests++;
            }
          }
        }
      }
    }

    testResults['summary'] = {
      'totalTests': totalTests,
      'passedTests': passedTests,
      'failedTests': totalTests - passedTests,
      'successRate': totalTests > 0
          ? (passedTests / totalTests * 100).toStringAsFixed(1) + '%'
          : '0%',
    };

    print('\n测试总结:');
    print('总测试数: ${testResults['summary']['totalTests']}');
    print('通过测试: ${testResults['summary']['passedTests']}');
    print('失败测试: ${testResults['summary']['failedTests']}');
    print('成功率: ${testResults['summary']['successRate']}');

    return testResults;
  }
}

// 运行测试示例：
/*
void main() async {
  final testResults = await KnowledgeFeatureTest.runFullTest();
  print('\n详细结果:');
  print(testResults);
}
*/

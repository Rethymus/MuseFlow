import 'package:flutter/foundation.dart';
import '../../features/knowledge/character_model.dart';
import '../../features/knowledge/world_model.dart';
import '../../utils/logger.dart';

/// 知识图谱节点类型
enum KnowledgeNodeType {
  character,
  world,
  location,
  organization,
  concept,
  relationship,
}

/// 知识图谱节点
class KnowledgeNode {
  final String id;
  final String label;
  final KnowledgeNodeType type;
  final Map<String, dynamic> properties;
  final List<String> connections;

  KnowledgeNode({
    required this.id,
    required this.label,
    required this.type,
    this.properties = const {},
    this.connections = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'properties': properties,
      'connections': connections,
    };
  }

  factory KnowledgeNode.fromJson(Map<String, dynamic> json) {
    return KnowledgeNode(
      id: json['id'] as String,
      label: json['label'] as String,
      type: KnowledgeNodeType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => KnowledgeNodeType.concept,
      ),
      properties: json['properties'] as Map<String, dynamic>? ?? {},
      connections: (json['connections'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// 知识图谱边（关系）
class KnowledgeEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final String relationship;
  final double weight;
  final Map<String, dynamic> properties;

  KnowledgeEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.relationship,
    this.weight = 1.0,
    this.properties = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'targetId': targetId,
      'relationship': relationship,
      'weight': weight,
      'properties': properties,
    };
  }

  factory KnowledgeEdge.fromJson(Map<String, dynamic> json) {
    return KnowledgeEdge(
      id: json['id'] as String,
      sourceId: json['sourceId'] as String,
      targetId: json['targetId'] as String,
      relationship: json['relationship'] as String,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// 关联推荐
class RelationshipRecommendation {
  final String sourceId;
  final String targetId;
  final String relationshipType;
  final double confidence;
  final String reason;

  RelationshipRecommendation({
    required this.sourceId,
    required this.targetId,
    required this.relationshipType,
    required this.confidence,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'targetId': targetId,
      'relationshipType': relationshipType,
      'confidence': confidence,
      'reason': reason,
    };
  }
}

/// 知识图谱引擎
///
/// 提供自动发现实体关系、可视化知识网络数据生成、智能关联推荐功能
class KnowledgeGraphEngine with ChangeNotifier {
  final Map<String, KnowledgeNode> _nodes = {};
  final Map<String, KnowledgeEdge> _edges = {};

  // 缓存分析结果
  Map<String, List<RelationshipRecommendation>> _recommendationCache = {};

  List<KnowledgeNode> get nodes => _nodes.values.toList();
  List<KnowledgeEdge> get edges => _edges.values.toList();

  int get nodeCount => _nodes.length;
  int get edgeCount => _edges.length;

  /// 初始化知识图谱
  Future<void> initialize() async {
    Logger.debug('初始化知识图谱引擎');
    _nodes.clear();
    _edges.clear();
    _recommendationCache.clear();
    notifyListeners();
  }

  /// 从角色列表构建知识图谱
  Future<void> buildFromCharacters(List<CharacterModel> characters) async {
    Logger.debug('从 ${characters.length} 个角色构建知识图谱');

    for (final character in characters) {
      await _addCharacterNode(character);
    }

    // 发现角色之间的关系
    await _discoverCharacterRelationships(characters);

    notifyListeners();
  }

  /// 从世界观构建知识图谱
  Future<void> buildFromWorlds(List<WorldModel> worlds) async {
    Logger.debug('从 ${worlds.length} 个世界观构建知识图谱');

    for (final world in worlds) {
      await _addWorldNode(world);

      // 添加地点节点
      for (final location in world.locations) {
        await _addLocationNode(location, world.id);
      }

      // 添加组织节点
      for (final organization in world.organizations) {
        await _addOrganizationNode(organization, world.id);
      }
    }

    notifyListeners();
  }

  /// 添加角色节点
  Future<void> _addCharacterNode(CharacterModel character) async {
    final node = KnowledgeNode(
      id: character.id,
      label: character.name,
      type: KnowledgeNodeType.character,
      properties: {
        'age': character.age,
        'personality': character.personality,
        'background': character.background,
        'tags': character.tags,
        'appearance': character.appearance,
        'speakingStyle': character.speakingStyle,
      },
    );

    _nodes[character.id] = node;
  }

  /// 添加世界观节点
  Future<void> _addWorldNode(WorldModel world) async {
    final node = KnowledgeNode(
      id: world.id,
      label: world.name,
      type: KnowledgeNodeType.world,
      properties: {
        'worldType': world.worldType,
        'era': world.era,
        'magicSystem': world.magicSystem,
        'technology': world.technology,
        'tags': world.tags,
      },
    );

    _nodes[world.id] = node;
  }

  /// 添加地点节点
  Future<void> _addLocationNode(Location location, String worldId) async {
    final node = KnowledgeNode(
      id: location.id,
      label: location.name,
      type: KnowledgeNodeType.location,
      properties: {
        'description': location.description,
        'worldId': worldId,
      },
    );

    _nodes[location.id] = node;

    // 创建地点到世界的关系
    final edge = KnowledgeEdge(
      id: '${worldId}_${location.id}',
      sourceId: worldId,
      targetId: location.id,
      relationship: 'contains',
      weight: 1.0,
    );

    _edges[edge.id] = edge;
  }

  /// 添加组织节点
  Future<void> _addOrganizationNode(Organization organization, String worldId) async {
    final node = KnowledgeNode(
      id: organization.id,
      label: organization.name,
      type: KnowledgeNodeType.organization,
      properties: {
        'description': organization.description,
        'leader': organization.leader,
        'philosophy': organization.philosophy,
        'worldId': worldId,
      },
    );

    _nodes[organization.id] = node;

    // 创建组织到世界的关系
    final edge = KnowledgeEdge(
      id: '${worldId}_${organization.id}',
      sourceId: worldId,
      targetId: organization.id,
      relationship: 'contains',
      weight: 1.0,
    );

    _edges[edge.id] = edge;
  }

  /// 自动发现角色之间的关系
  Future<void> _discoverCharacterRelationships(List<CharacterModel> characters) async {
    for (int i = 0; i < characters.length; i++) {
      for (int j = i + 1; j < characters.length; j++) {
        final char1 = characters[i];
        final char2 = characters[j];

        // 检查显式关系
        await _checkExplicitRelationships(char1, char2);

        // 检查隐式关系（基于标签、背景等）
        await _discoverImplicitRelationships(char1, char2);
      }
    }
  }

  /// 检查显式关系
  Future<void> _checkExplicitRelationships(CharacterModel char1, CharacterModel char2) async {
    // 检查char1的关系列表中是否提到char2
    for (final relationship in char1.relationships) {
      if (relationship.toLowerCase().contains(char2.name.toLowerCase())) {
        final edge = KnowledgeEdge(
          id: '${char1.id}_${char2.id}',
          sourceId: char1.id,
          targetId: char2.id,
          relationship: 'related_to',
          weight: 1.0,
          properties: {'description': relationship},
        );
        _edges[edge.id] = edge;
      }
    }

    // 检查char2的关系列表中是否提到char1
    for (final relationship in char2.relationships) {
      if (relationship.toLowerCase().contains(char1.name.toLowerCase())) {
        final edge = KnowledgeEdge(
          id: '${char2.id}_${char1.id}',
          sourceId: char2.id,
          targetId: char1.id,
          relationship: 'related_to',
          weight: 1.0,
          properties: {'description': relationship},
        );
        _edges[edge.id] = edge;
      }
    }
  }

  /// 发现隐式关系
  Future<void> _discoverImplicitRelationships(CharacterModel char1, CharacterModel char2) async {
    double relationshipStrength = 0.0;
    final List<String> reasons = [];

    // 检查共同标签
    final commonTags = char1.tags.where((tag) => char2.tags.contains(tag)).toList();
    if (commonTags.isNotEmpty) {
      relationshipStrength += commonTags.length * 0.2;
      reasons.add('共同标签: ${commonTags.join(", ")}');
    }

    // 检查背景相似性
    if (char1.background != null && char2.background != null) {
      final background1 = char1.background!.toLowerCase();
      final background2 = char2.background!.toLowerCase();

      // 简单的文本相似性检查
      if (background1.contains(background2) || background2.contains(background1)) {
        relationshipStrength += 0.3;
        reasons.add('背景相似');
      }
    }

    // 检查性格相似性
    if (char1.personality != null && char2.personality != null) {
      final personality1 = char1.personality!.toLowerCase();
      final personality2 = char2.personality!.toLowerCase();

      if (personality1.contains(personality2) || personality2.contains(personality1)) {
        relationshipStrength += 0.2;
        reasons.add('性格相似');
      }
    }

    // 如果关系强度足够，创建隐式关系边
    if (relationshipStrength >= 0.5) {
      final edge = KnowledgeEdge(
        id: 'implicit_${char1.id}_${char2.id}',
        sourceId: char1.id,
        targetId: char2.id,
        relationship: 'potentially_related',
        weight: relationshipStrength,
        properties: {
          'reason': reasons.join('; '),
          'implicit': true,
        },
      );
      _edges[edge.id] = edge;
    }
  }

  /// 生成可视化知识网络数据
  Map<String, dynamic> generateVisualizationData({
    String? focusNodeId,
    int maxDepth = 2,
    int maxNodes = 50,
  }) {
    final List<KnowledgeNode> visibleNodes = [];
    final List<KnowledgeEdge> visibleEdges = [];
    final Set<String> visitedNodeIds = {};

    // 如果指定了焦点节点，从该节点开始遍历
    if (focusNodeId != null && _nodes.containsKey(focusNodeId)) {
      _bfsTraversal(focusNodeId, maxDepth, visibleNodes, visibleEdges, visitedNodeIds);
    } else {
      // 否则显示所有节点（限制数量）
      for (final node in _nodes.values) {
        if (visibleNodes.length >= maxNodes) break;
        visibleNodes.add(node);
        visitedNodeIds.add(node.id);
      }

      // 添加相关边
      for (final edge in _edges.values) {
        if (visitedNodeIds.contains(edge.sourceId) &&
            visitedNodeIds.contains(edge.targetId)) {
          visibleEdges.add(edge);
        }
      }
    }

    return {
      'nodes': visibleNodes.map((node) => node.toJson()).toList(),
      'edges': visibleEdges.map((edge) => edge.toJson()).toList(),
      'metadata': {
        'totalNodes': _nodes.length,
        'totalEdges': _edges.length,
        'visibleNodes': visibleNodes.length,
        'visibleEdges': visibleEdges.length,
        'focusNodeId': focusNodeId,
        'maxDepth': maxDepth,
      },
    };
  }

  /// BFS遍历图
  void _bfsTraversal(
    String startNodeId,
    int maxDepth,
    List<KnowledgeNode> visibleNodes,
    List<KnowledgeEdge> visibleEdges,
    Set<String> visitedNodeIds,
  ) {
    final List<(String, int)> queue = [(startNodeId, 0)];
    visitedNodeIds.add(startNodeId);

    while (queue.isNotEmpty && visibleNodes.length < 50) {
      final (currentNodeId, depth) = queue.removeAt(0);

      if (depth > maxDepth) continue;

      final currentNode = _nodes[currentNodeId];
      if (currentNode != null) {
        visibleNodes.add(currentNode);
      }

      // 查找相关边和邻居节点
      for (final edge in _edges.values) {
        if (edge.sourceId == currentNodeId || edge.targetId == currentNodeId) {
          final neighborId = edge.sourceId == currentNodeId ? edge.targetId : edge.sourceId;

          if (!visitedNodeIds.contains(neighborId)) {
            visitedNodeIds.add(neighborId);
            queue.add((neighborId, depth + 1));
          }

          if (visitedNodeIds.contains(edge.sourceId) &&
              visitedNodeIds.contains(edge.targetId)) {
            visibleEdges.add(edge);
          }
        }
      }
    }
  }

  /// 生成关联推荐
  List<RelationshipRecommendation> generateRecommendations(String nodeId) {
    if (_recommendationCache.containsKey(nodeId)) {
      return _recommendationCache[nodeId]!;
    }

    final List<RelationshipRecommendation> recommendations = [];
    final sourceNode = _nodes[nodeId];

    if (sourceNode == null) {
      return recommendations;
    }

    // 基于标签相似性推荐
    recommendations.addAll(_recommendByTags(sourceNode));

    // 基于共同邻居推荐
    recommendations.addAll(_recommendByCommonNeighbors(nodeId));

    // 基于内容相似性推荐
    recommendations.addAll(_recommendByContentSimilarity(sourceNode));

    // 排序并缓存
    recommendations.sort((a, b) => b.confidence.compareTo(a.confidence));
    _recommendationCache[nodeId] = recommendations.take(10).toList();

    return _recommendationCache[nodeId]!;
  }

  /// 基于标签推荐
  List<RelationshipRecommendation> _recommendByTags(KnowledgeNode sourceNode) {
    final List<RelationshipRecommendation> recommendations = [];
    final sourceTags = (sourceNode.properties['tags'] as List<dynamic>?)?.cast<String>() ?? [];

    for (final node in _nodes.values) {
      if (node.id == sourceNode.id) continue;

      final targetTags = (node.properties['tags'] as List<dynamic>?)?.cast<String>() ?? [];
      final commonTags = sourceTags.where((tag) => targetTags.contains(tag)).toList();

      if (commonTags.isNotEmpty) {
        recommendations.add(RelationshipRecommendation(
          sourceId: sourceNode.id,
          targetId: node.id,
          relationshipType: 'similar_interests',
          confidence: commonTags.length * 0.3,
          reason: '共同标签: ${commonTags.join(", ")}',
        ));
      }
    }

    return recommendations;
  }

  /// 基于共同邻居推荐
  List<RelationshipRecommendation> _recommendByCommonNeighbors(String sourceId) {
    final List<RelationshipRecommendation> recommendations = [];
    final neighbors = _getNodeNeighbors(sourceId);

    for (final node in _nodes.values) {
      if (node.id == sourceId) continue;

      final targetNeighbors = _getNodeNeighbors(node.id);
      final commonNeighbors = neighbors.where((id) => targetNeighbors.contains(id)).toList();

      if (commonNeighbors.length >= 2) {
        recommendations.add(RelationshipRecommendation(
          sourceId: sourceId,
          targetId: node.id,
          relationshipType: 'social_connection',
          confidence: commonNeighbors.length * 0.2,
          reason: '共同连接: ${commonNeighbors.length}个',
        ));
      }
    }

    return recommendations;
  }

  /// 基于内容相似性推荐
  List<RelationshipRecommendation> _recommendByContentSimilarity(KnowledgeNode sourceNode) {
    final List<RelationshipRecommendation> recommendations = [];

    for (final node in _nodes.values) {
      if (node.id == sourceNode.id) continue;

      double similarity = 0.0;

      // 检查背景相似性
      final sourceBackground = sourceNode.properties['background'] as String?;
      final targetBackground = node.properties['background'] as String?;
      if (sourceBackground != null && targetBackground != null) {
        if (_calculateTextSimilarity(sourceBackground, targetBackground) > 0.5) {
          similarity += 0.4;
        }
      }

      // 检查性格相似性
      final sourcePersonality = sourceNode.properties['personality'] as String?;
      final targetPersonality = node.properties['personality'] as String?;
      if (sourcePersonality != null && targetPersonality != null) {
        if (_calculateTextSimilarity(sourcePersonality, targetPersonality) > 0.5) {
          similarity += 0.3;
        }
      }

      if (similarity >= 0.5) {
        recommendations.add(RelationshipRecommendation(
          sourceId: sourceNode.id,
          targetId: node.id,
          relationshipType: 'content_similarity',
          confidence: similarity,
          reason: '内容相似度高',
        ));
      }
    }

    return recommendations;
  }

  /// 获取节点的邻居
  Set<String> _getNodeNeighbors(String nodeId) {
    final Set<String> neighbors = {};

    for (final edge in _edges.values) {
      if (edge.sourceId == nodeId) {
        neighbors.add(edge.targetId);
      } else if (edge.targetId == nodeId) {
        neighbors.add(edge.sourceId);
      }
    }

    return neighbors;
  }

  /// 计算文本相似性（简化版本）
  double _calculateTextSimilarity(String text1, String text2) {
    final lower1 = text1.toLowerCase();
    final lower2 = text2.toLowerCase();

    if (lower1.contains(lower2) || lower2.contains(lower1)) {
      return 0.8;
    }

    final words1 = lower1.split(' ');
    final words2 = lower2.split(' ');
    final commonWords = words1.where((word) => words2.contains(word)).toList();

    if (commonWords.length > 2) {
      return 0.6;
    }

    return 0.0;
  }

  /// 查找最短路径
  List<String> findShortestPath(String startId, String endId) {
    if (!_nodes.containsKey(startId) || !_nodes.containsKey(endId)) {
      return [];
    }

    if (startId == endId) {
      return [startId];
    }

    final Map<String, String> parentMap = {};
    final List<String> queue = [startId];
    final Set<String> visited = {startId};

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);

      if (currentId == endId) {
        // 重建路径
        final List<String> path = [];
        String? nodeId = endId;
        while (nodeId != null) {
          path.insert(0, nodeId);
          nodeId = parentMap[nodeId];
        }
        return path;
      }

      // 获取邻居
      final neighbors = _getNodeNeighbors(currentId);
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          parentMap[neighbor] = currentId;
          queue.add(neighbor);
        }
      }
    }

    return []; // 没有找到路径
  }

  /// 获取节点统计信息
  Map<String, dynamic> getNodeStatistics(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null) {
      return {};
    }

    final neighbors = _getNodeNeighbors(nodeId);
    final List<Map<String, dynamic>> connections = [];

    for (final edge in _edges.values) {
      if (edge.sourceId == nodeId || edge.targetId == nodeId) {
        final otherNodeId = edge.sourceId == nodeId ? edge.targetId : edge.sourceId;
        final otherNode = _nodes[otherNodeId];

        if (otherNode != null) {
          connections.add({
            'target': otherNode.label,
            'relationship': edge.relationship,
            'weight': edge.weight,
          });
        }
      }
    }

    return {
      'node': node.toJson(),
      'connectionCount': neighbors.length,
      'connections': connections,
      'type': node.type.name,
    };
  }

  /// 清空图谱
  Future<void> clear() async {
    _nodes.clear();
    _edges.clear();
    _recommendationCache.clear();
    notifyListeners();
  }

  /// 导出图谱数据
  Map<String, dynamic> exportGraph() {
    return {
      'nodes': _nodes.values.map((node) => node.toJson()).toList(),
      'edges': _edges.values.map((edge) => edge.toJson()).toList(),
      'metadata': {
        'nodeCount': _nodes.length,
        'edgeCount': _edges.length,
        'exportDate': DateTime.now().toIso8601String(),
      },
    };
  }

  /// 导入图谱数据
  Future<void> importGraph(Map<String, dynamic> data) async {
    try {
      _nodes.clear();
      _edges.clear();
      _recommendationCache.clear();

      final List<dynamic> nodesData = data['nodes'] ?? [];
      for (final nodeData in nodesData) {
        final node = KnowledgeNode.fromJson(nodeData as Map<String, dynamic>);
        _nodes[node.id] = node;
      }

      final List<dynamic> edgesData = data['edges'] ?? [];
      for (final edgeData in edgesData) {
        final edge = KnowledgeEdge.fromJson(edgeData as Map<String, dynamic>);
        _edges[edge.id] = edge;
      }

      notifyListeners();
      Logger.debug('成功导入 ${_nodes.length} 个节点和 ${_edges.length} 条边');
    } catch (e) {
      Logger.debug('导入图谱数据失败: $e');
    }
  }
}
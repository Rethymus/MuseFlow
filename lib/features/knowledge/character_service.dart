import '../../utils/logger.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'character_model.dart';
import '../../utils/file_security_validator.dart';
import '../../services/knowledge/knowledge_graph_engine.dart';
import '../../services/knowledge/semantic_search_engine.dart';

/// 角色卡数据服务
class CharacterService with ChangeNotifier {
  static const String _boxName = 'characters';
  Box<CharacterModel>? _box;

  // ignore: unused_field
  List<CharacterModel> _characters = [];
  CharacterModel? _currentCharacter;
  String? _currentProjectId;

  // 知识图谱和搜索引擎引用（可选依赖）
  KnowledgeGraphEngine? _knowledgeGraph;
  SemanticSearchEngine? _semanticSearch;

  List<CharacterModel> get characters => _characters;
  CharacterModel? get currentCharacter => _currentCharacter;

  bool get isInitialized => _box != null;
  int get characterCount => _characters.length;

  /// 初始化服务
  Future<void> initialize({String? projectId}) async {
    if (_box != null && _currentProjectId == projectId) return;

    _currentProjectId = projectId;

    // 如果是不同的项目，关闭旧的box
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }

    // 打开或创建box
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<CharacterModel>(_boxName);
    } else {
      _box = Hive.box<CharacterModel>(_boxName);
    }

    _loadCharacters();
    notifyListeners();
  }

  /// 设置知识图谱引擎（可选依赖）
  void setKnowledgeGraphEngine(KnowledgeGraphEngine engine) {
    _knowledgeGraph = engine;
    Logger.debug('CharacterService: 设置知识图谱引擎');
  }

  /// 设置语义搜索引擎（可选依赖）
  void setSemanticSearchEngine(SemanticSearchEngine engine) {
    _semanticSearch = engine;
    Logger.debug('CharacterService: 设置语义搜索引擎');
  }

  /// 从Hive加载数据
  void _loadCharacters() {
    _characters.clear();
    if (_box != null) {
      _characters.addAll(_box!.values.toList());
      // 按更新时间排序
      _characters.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
  }

  /// 创建新角色
  Future<CharacterModel> createCharacter({
    required String name,
    int? age,
    String? appearance,
    String? personality,
    String? background,
    String? speakingStyle,
    List<String>? relationships,
    List<String>? tags,
    String? avatarPath,
    String? notes,
  }) async {
    final character = CharacterModel(
      id: const Uuid().v4(),
      name: name,
      age: age,
      appearance: appearance,
      personality: personality,
      background: background,
      speakingStyle: speakingStyle,
      relationships: relationships ?? [],
      tags: tags ?? [],
      avatarPath: avatarPath,
      notes: notes,
    );

    await _box!.put(character.id, character);
    _characters.insert(0, character);

    // 同步到知识图谱
    if (_knowledgeGraph != null) {
      try {
        await _knowledgeGraph!.addCharacterNode(character);
      } catch (e) {
        Logger.debug('知识图谱同步失败: $e');
      }
    }

    // 同步到语义搜索
    if (_semanticSearch != null) {
      try {
        await _semanticSearch!.indexCharacter(character);
      } catch (e) {
        Logger.debug('语义搜索索引失败: $e');
      }
    }

    notifyListeners();

    return character;
  }

  /// 更新角色
  Future<void> updateCharacter(CharacterModel character) async {
    final updated = character.copyWith(
      updatedAt: DateTime.now(),
    );

    await _box!.put(updated.id, updated);

    // 更新列表中的角色
    final index = _characters.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _characters[index] = updated;
      // 重新排序
      _characters.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    if (_currentCharacter?.id == updated.id) {
      _currentCharacter = updated;
    }

    // 同步到知识图谱
    if (_knowledgeGraph != null) {
      try {
        await _knowledgeGraph!.addCharacterNode(updated);
      } catch (e) {
        Logger.debug('知识图谱同步失败: $e');
      }
    }

    // 同步到语义搜索
    if (_semanticSearch != null) {
      try {
        await _semanticSearch!.indexCharacter(updated);
      } catch (e) {
        Logger.debug('语义搜索索引失败: $e');
      }
    }

    notifyListeners();
  }

  /// 删除角色
  Future<void> deleteCharacter(String id) async {
    await _box!.delete(id);
    _characters.removeWhere((c) => c.id == id);

    if (_currentCharacter?.id == id) {
      _currentCharacter = null;
    }

    notifyListeners();
  }

  /// 设置当前角色
  void setCurrentCharacter(CharacterModel? character) {
    _currentCharacter = character;
    notifyListeners();
  }

  /// 获取角色详情
  CharacterModel? getCharacter(String id) {
    try {
      return _box!.get(id);
    } catch (e) {
      return null;
    }
  }

  /// 搜索角色
  List<CharacterModel> searchCharacters(String query) {
    if (query.isEmpty) return _characters;

    return _characters.where((character) {
      return character.matchesQuery(query);
    }).toList();
  }

  /// 按标签筛选
  List<CharacterModel> filterByTag(String tag) {
    return _characters
        .where((character) => character.tags.contains(tag))
        .toList();
  }

  /// 获取所有标签
  Set<String> getAllTags() {
    final tags = <String>{};
    for (final character in _characters) {
      tags.addAll(character.tags);
    }
    return tags;
  }

  /// 批量导入角色
  Future<int> importFromJson(Map<String, dynamic> data) async {
    int count = 0;

    try {
      final List<dynamic> charactersData = data['characters'] ?? [];

      for (final characterData in charactersData) {
        try {
          final character =
              CharacterModel.fromJson(characterData as Map<String, dynamic>);

          // 检查是否已存在（通过ID）
          if (_box!.containsKey(character.id)) {
            // 更新现有角色
            await updateCharacter(character);
          } else {
            // 添加新角色
            await _box!.put(character.id, character);
            _characters.add(character);
          }
          count++;
        } catch (e) {
          Logger.debug('导入角色失败: $e');
        }
      }

      _loadCharacters();
      notifyListeners();
    } catch (e) {
      Logger.debug('批量导入失败: $e');
    }

    return count;
  }

  /// 批量导出角色
  Future<Map<String, dynamic>> exportToJson({List<String>? ids}) async {
    final List<Map<String, dynamic>> charactersData = [];

    final charactersToExport = ids != null
        ? _characters.where((c) => ids.contains(c.id))
        : _characters;

    for (final character in charactersToExport) {
      try {
        charactersData.add(character.toJson());
      } catch (e) {
        Logger.debug('导出角色失败: ${character.name}, $e');
      }
    }

    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'count': charactersData.length,
      'characters': charactersData,
    };
  }

  /// 从文件导入
  Future<int> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return 0;

      final file = result.files.first;
      if (file.path == null) return 0;

      // 1. 验证文件路径
      final pathValidation = await FileSecurityValidator.instance.validatePath(
        file.path!,
        requireExistence: true,
      );

      if (!pathValidation.isValid) {
        Logger.debug('导入失败：${pathValidation.errorMessage}');
        return 0;
      }

      final validatedPath = pathValidation.sanitizedPath ?? file.path!;

      // 2. 验证文件类型
      final typeValidation =
          FileSecurityValidator.instance.validateFileType(validatedPath);
      if (!typeValidation.isValid) {
        Logger.debug('导入失败：${typeValidation.errorMessage}');
        return 0;
      }

      // 3. 验证文件大小
      final fileObj = File(validatedPath);
      final fileSize = await fileObj.length();

      if (fileSize > FileSecurityValidator.maxSingleFileSize) {
        Logger.debug('导入失败：文件过大 ($fileSize bytes)');
        return 0;
      }

      // 4. 读取并解析文件内容
      final jsonString = await fileObj.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // 5. 导入数据
      final count = await importFromJson(data);

      // 6. 更新会话大小
      if (count > 0) {
        FileSecurityValidator.instance.updateSessionSize(fileSize);
      }

      return count;
    } catch (e) {
      Logger.debug('文件导入失败: $e');
      return 0;
    }
  }

  /// 导出到文件
  Future<bool> exportToFile({List<String>? ids}) async {
    try {
      final data = await exportToJson(ids: ids);
      final jsonString = json.encode(data);

      // 1. 检查内容大小
      final contentSize = jsonString.length;
      if (contentSize > FileSecurityValidator.maxSingleFileSize) {
        Logger.debug('导出失败：内容过大 (${contentSize} bytes)');
        return false;
      }

      // 2. 使用文件选择器保存文件
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出角色卡',
        fileName: 'characters_${DateTime.now().toIso8601String()}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath == null) return false;

      // 3. 验证文件路径
      final validation = await FileSecurityValidator.instance.validateFile(
        outputPath,
        checkWritePermission: true,
        checkType: true,
      );

      if (!validation.isValid) {
        Logger.debug('导出失败：${validation.errorMessage}');

        // 使用安全路径作为后备
        final safePath =
            await FileSecurityValidator.instance.createSafeOutputPath(
          'characters_${DateTime.now().toIso8601String()}.json',
          'exports',
        );

        await File(safePath).writeAsString(jsonString);
        FileSecurityValidator.instance.updateSessionSize(contentSize);

        Logger.debug('使用安全路径导出: $safePath');
        return true;
      }

      // 4. 写入用户选择的路径
      await File(outputPath).writeAsString(jsonString);
      FileSecurityValidator.instance.updateSessionSize(contentSize);

      Logger.debug('角色卡导出成功: $outputPath');
      return true;
    } catch (e) {
      Logger.debug('文件导出失败: $e');
      return false;
    }
  }

  /// 清空所有数据
  Future<void> clearAll() async {
    await _box!.clear();
    _characters.clear();
    _currentCharacter = null;
    notifyListeners();
  }

  /// 关闭服务
  Future<void> dispose() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
    _characters.clear();
    _currentCharacter = null;
    super.dispose();
  }

  // ========== 知识图谱和语义搜索集成功能 ==========

  /// 发现角色间的关系
  Future<List<Map<String, dynamic>>> discoverRelationships() async {
    if (_knowledgeGraph == null) {
      Logger.debug('知识图谱引擎未设置，无法发现关系');
      return [];
    }

    await _knowledgeGraph!.discoverCharacterRelationships(_characters);

    // 返回发现的关系
    final List<Map<String, dynamic>> relationships = [];
    final edgesMap = _knowledgeGraph!.edgesMap;
    final nodesMap = _knowledgeGraph!.nodesMap;
    for (final edge in edgesMap.values) {
      if (edge.properties['implicit'] == true) {
        final sourceNode = nodesMap[edge.sourceId];
        final targetNode = nodesMap[edge.targetId];

        if (sourceNode != null && targetNode != null) {
          relationships.add({
            'source': sourceNode.label,
            'target': targetNode.label,
            'relationship': edge.relationship,
            'confidence': edge.weight,
            'reason': edge.properties['reason'],
          });
        }
      }
    }

    return relationships;
  }

  /// 获取角色关联推荐
  List<Map<String, dynamic>> getRelationshipRecommendations(
    String characterId,
  ) {
    if (_knowledgeGraph == null) {
      return [];
    }

    final recommendations =
        _knowledgeGraph!.generateRecommendations(characterId);
    final nodesMap = _knowledgeGraph!.nodesMap;
    final List<Map<String, dynamic>> results = [];

    for (final rec in recommendations) {
      final targetNode = nodesMap[rec.targetId];
      if (targetNode != null) {
        results.add({
          'characterId': rec.targetId,
          'characterName': targetNode.label,
          'relationshipType': rec.relationshipType,
          'confidence': rec.confidence,
          'reason': rec.reason,
        });
      }
    }

    return results;
  }

  /// 语义搜索角色
  Future<List<Map<String, dynamic>>> semanticSearchCharacters(
    String query, {
    int limit = 10,
  }) async {
    if (_semanticSearch == null) {
      // 回退到基本搜索
      final results = searchCharacters(query);
      return results
          .map((char) => {
                'id': char.id,
                'name': char.name,
                'type': 'character',
                'relevanceScore': 1.0,
                'character': char,
              })
          .toList();
    }

    final searchResults = await _semanticSearch!.semanticSearch(
      query,
      limit: limit,
      types: ['character'],
    );

    final List<Map<String, dynamic>> results = [];
    for (final result in searchResults) {
      final character = getCharacter(result.id);
      if (character != null) {
        results.add({
          'id': result.id,
          'name': result.title,
          'type': result.type,
          'relevanceScore': result.relevanceScore,
          'character': character,
        });
      }
    }

    return results;
  }

  /// 查找相似角色
  Future<List<Map<String, dynamic>>> findSimilarCharacters(
    String characterId, {
    int limit = 5,
  }) async {
    if (_semanticSearch == null) {
      return [];
    }

    final similarResults = await _semanticSearch!.findSimilar(
      characterId,
      limit: limit,
    );

    final List<Map<String, dynamic>> results = [];
    for (final result in similarResults) {
      if (result.type == 'character') {
        final character = getCharacter(result.id);
        if (character != null) {
          results.add({
            'id': result.id,
            'name': result.title,
            'similarity': result.relevanceScore,
            'character': character,
          });
        }
      }
    }

    return results;
  }

  /// 获取角色在知识图谱中的统计信息
  Map<String, dynamic> getCharacterGraphStats(String characterId) {
    if (_knowledgeGraph == null) {
      return {};
    }

    return _knowledgeGraph!.getNodeStatistics(characterId);
  }

  /// 重新构建知识图谱
  Future<void> rebuildKnowledgeGraph() async {
    if (_knowledgeGraph == null) {
      Logger.debug('知识图谱引擎未设置');
      return;
    }

    await _knowledgeGraph!.buildFromCharacters(_characters);
    Logger.debug('知识图谱重建完成，包含 ${_knowledgeGraph!.nodeCount} 个节点');
  }

  /// 重新索引角色到语义搜索
  Future<void> reindexCharacters() async {
    if (_semanticSearch == null) {
      Logger.debug('语义搜索引擎未设置');
      return;
    }

    await _semanticSearch!.indexCharacters(_characters);
    Logger.debug('角色重新索引完成');
  }
}

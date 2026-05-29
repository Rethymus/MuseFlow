import '../../utils/logger.dart';
import '../../config/app_constants.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'world_model.dart';
import '../../utils/file_security_validator.dart';
import '../../services/knowledge/knowledge_graph_engine.dart';
import '../../services/knowledge/semantic_search_engine.dart';

/// 世界观数据服务
class WorldService with ChangeNotifier {
  static const String _boxName = 'worlds';
  Box<WorldModel>? _box;

  List<WorldModel> _worlds = [];
  WorldModel? _currentWorld;
  String? _currentProjectId;

  // 知识图谱和搜索引擎引用（可选依赖）
  KnowledgeGraphEngine? _knowledgeGraph;
  SemanticSearchEngine? _semanticSearch;

  List<WorldModel> get worlds => _worlds;
  WorldModel? get currentWorld => _currentWorld;

  bool get isInitialized => _box != null;
  int get worldCount => _worlds.length;

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
      _box = await Hive.openBox<WorldModel>(_boxName);
    } else {
      _box = Hive.box<WorldModel>(_boxName);
    }

    _loadWorlds();
    notifyListeners();
  }

  /// 设置知识图谱引擎（可选依赖）
  void setKnowledgeGraphEngine(KnowledgeGraphEngine engine) {
    _knowledgeGraph = engine;
    Logger.debug('WorldService: 设置知识图谱引擎');
  }

  /// 设置语义搜索引擎（可选依赖）
  void setSemanticSearchEngine(SemanticSearchEngine engine) {
    _semanticSearch = engine;
    Logger.debug('WorldService: 设置语义搜索引擎');
  }

  /// 从Hive加载数据
  void _loadWorlds() {
    _worlds.clear();
    if (_box != null) {
      _worlds.addAll(_box!.values.toList());
      // 按更新时间排序
      _worlds.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
  }

  /// 创建新世界观
  Future<WorldModel> createWorld({
    required String name,
    required String worldType,
    String? era,
    String? magicSystem,
    String? technology,
    List<String>? rules,
    List<Location>? locations,
    List<Organization>? organizations,
    String? geography,
    String? history,
    List<String>? tags,
    String? notes,
  }) async {
    final world = WorldModel(
      id: const Uuid().v4(),
      name: name,
      worldType: worldType,
      era: era,
      magicSystem: magicSystem,
      technology: technology,
      rules: rules ?? [],
      locations: locations ?? [],
      organizations: organizations ?? [],
      geography: geography,
      history: history,
      tags: tags ?? [],
      notes: notes,
    );

    await _box!.put(world.id, world);
    _worlds.insert(0, world);
    notifyListeners();

    return world;
  }

  /// 更新世界观
  Future<void> updateWorld(WorldModel world) async {
    final updated = world.copyWith(
      updatedAt: DateTime.now(),
    );

    await _box!.put(updated.id, updated);

    // 更新列表中的世界观
    final index = _worlds.indexWhere((w) => w.id == updated.id);
    if (index != -1) {
      _worlds[index] = updated;
      // 重新排序
      _worlds.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    if (_currentWorld?.id == updated.id) {
      _currentWorld = updated;
    }

    notifyListeners();
  }

  /// 删除世界观
  Future<void> deleteWorld(String id) async {
    await _box!.delete(id);
    _worlds.removeWhere((w) => w.id == id);

    if (_currentWorld?.id == id) {
      _currentWorld = null;
    }

    notifyListeners();
  }

  /// 设置当前世界观
  void setCurrentWorld(WorldModel? world) {
    _currentWorld = world;
    notifyListeners();
  }

  /// 获取世界观详情
  WorldModel? getWorld(String id) {
    try {
      return _box!.get(id);
    } catch (e) {
      return null;
    }
  }

  /// 搜索世界观
  List<WorldModel> searchWorlds(String query) {
    if (query.isEmpty) return _worlds;

    final lowerQuery = query.toLowerCase();
    return _worlds.where((world) {
      return world.matchesQuery(query);
    }).toList();
  }

  /// 按标签筛选
  List<WorldModel> filterByTag(String tag) {
    return _worlds.where((world) => world.tags.contains(tag)).toList();
  }

  /// 按类型筛选
  List<WorldModel> filterByType(String worldType) {
    return _worlds.where((world) => world.worldType == worldType).toList();
  }

  /// 获取所有标签
  Set<String> getAllTags() {
    final tags = <String>{};
    for (final world in _worlds) {
      tags.addAll(world.tags);
    }
    return tags;
  }

  /// 获取所有世界类型
  Set<String> getAllTypes() {
    final types = <String>{};
    for (final world in _worlds) {
      types.add(world.worldType);
    }
    return types;
  }

  /// 批量导入世界观
  Future<int> importFromJson(Map<String, dynamic> data) async {
    int count = 0;

    try {
      final List<dynamic> worldsData = data['worlds'] ?? [];

      for (final worldData in worldsData) {
        try {
          final world = WorldModel.fromJson(worldData as Map<String, dynamic>);

          // 检查是否已存在（通过ID）
          if (_box!.containsKey(world.id)) {
            // 更新现有世界观
            await updateWorld(world);
          } else {
            // 添加新世界观
            await _box!.put(world.id, world);
            _worlds.add(world);
          }
          count++;
        } catch (e) {
          Logger.debug('导入世界观失败: $e');
        }
      }

      _loadWorlds();
      notifyListeners();
    } catch (e) {
      Logger.debug('批量导入失败: $e');
    }

    return count;
  }

  /// 批量导出世界观
  Map<String, dynamic> exportToJson({List<String>? ids}) async {
    final List<Map<String, dynamic>> worldsData = [];

    final worldsToExport =
        ids != null ? _worlds.where((w) => ids.contains(w.id)) : _worlds;

    for (final world in worldsToExport) {
      try {
        worldsData.add(world.toJson());
      } catch (e) {
        Logger.debug('导出世界观失败: ${world.name}, $e');
      }
    }

    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'count': worldsData.length,
      'worlds': worldsData,
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
        Logger.debug('导入失败：文件过大 (${fileSize} bytes)');
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
        dialogTitle: '导出世界观',
        fileName: 'worlds_${DateTime.now().toIso8601String()}.json',
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
          'worlds_${DateTime.now().toIso8601String()}.json',
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

      Logger.debug('世界观导出成功: $outputPath');
      return true;
    } catch (e) {
      Logger.debug('文件导出失败: $e');
      return false;
    }
  }

  /// 清空所有数据
  Future<void> clearAll() async {
    await _box!.clear();
    _worlds.clear();
    _currentWorld = null;
    notifyListeners();
  }

  /// 关闭服务
  Future<void> dispose() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
    _worlds.clear();
    _currentWorld = null;
    super.dispose();
  }

  // ========== 知识图谱和语义搜索集成功能 ==========

  /// 语义搜索世界观
  Future<List<Map<String, dynamic>>> semanticSearchWorlds(
    String query, {
    int limit = 10,
  }) async {
    if (_semanticSearch == null) {
      // 回退到基本搜索
      final results = searchWorlds(query);
      return results
          .map((world) => {
                'id': world.id,
                'name': world.name,
                'type': 'world',
                'relevanceScore': 1.0,
                'world': world,
              })
          .toList();
    }

    final searchResults = await _semanticSearch!.semanticSearch(
      query,
      limit: limit,
    );

    final List<Map<String, dynamic>> results = [];
    for (final result in searchResults) {
      if (result.type == 'world' ||
          result.type == 'location' ||
          result.type == 'organization') {
        final world =
            getWorld(result.metadata['worldId'] as String? ?? result.id);
        if (world != null) {
          results.add({
            'id': result.id,
            'name': result.title,
            'type': result.type,
            'relevanceScore': result.relevanceScore,
            'world': world,
          });
        }
      }
    }

    return results;
  }

  /// 查找相似世界观
  Future<List<Map<String, dynamic>>> findSimilarWorlds(
    String worldId, {
    int limit = 5,
  }) async {
    if (_semanticSearch == null) {
      return [];
    }

    final similarResults = await _semanticSearch!.findSimilar(
      worldId,
      limit: limit,
    );

    final List<Map<String, dynamic>> results = [];
    for (final result in similarResults) {
      if (result.type == 'world') {
        final world = getWorld(result.id);
        if (world != null) {
          results.add({
            'id': result.id,
            'name': result.title,
            'similarity': result.relevanceScore,
            'world': world,
          });
        }
      }
    }

    return results;
  }

  /// 获取世界观在知识图谱中的统计信息
  Map<String, dynamic> getWorldGraphStats(String worldId) {
    if (_knowledgeGraph == null) {
      return {};
    }

    return _knowledgeGraph!.getNodeStatistics(worldId);
  }

  /// 重新构建知识图谱
  Future<void> rebuildKnowledgeGraph() async {
    if (_knowledgeGraph == null) {
      Logger.debug('知识图谱引擎未设置');
      return;
    }

    await _knowledgeGraph!.buildFromWorlds(_worlds);
    Logger.debug('世界观知识图谱重建完成，包含 ${_knowledgeGraph!.nodeCount} 个节点');
  }

  /// 重新索引世界观到语义搜索
  Future<void> reindexWorlds() async {
    if (_semanticSearch == null) {
      Logger.debug('语义搜索引擎未设置');
      return;
    }

    await _semanticSearch!.indexWorlds(_worlds);
    Logger.debug('世界观重新索引完成');
  }

  /// 获取世界观的关联内容（地点、组织等）
  List<Map<String, dynamic>> getWorldRelatedContent(String worldId) {
    final world = getWorld(worldId);
    if (world == null) {
      return [];
    }

    final List<Map<String, dynamic>> relatedContent = [];

    // 添加地点信息
    for (final location in world.locations) {
      relatedContent.add({
        'id': location.id,
        'name': location.name,
        'type': 'location',
        'description': location.description,
        'relatedCharacters': location.relatedCharacters,
      });
    }

    // 添加组织信息
    for (final organization in world.organizations) {
      relatedContent.add({
        'id': organization.id,
        'name': organization.name,
        'type': 'organization',
        'description': organization.description,
        'leader': organization.leader,
        'members': organization.members,
      });
    }

    return relatedContent;
  }
}

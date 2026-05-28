import '../../config/app_constants.dart';
import '../../utils/logger.dart';
/// 知识库功能使用示例
///
/// 注意：此文件展示了如何使用知识库功能，需要Flutter环境运行

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 假设的导入路径
// import 'knowledge.dart';

/// 示例1：基本初始化
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Hive
  await Hive.initFlutter();

  // 初始化知识库
  await KnowledgeFeature.initialize();

  runApp(
    MultiProvider(
      providers: [
        // 添加知识库Providers
        ...KnowledgeFeature.getProviders(),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuseFlow Demo',
      home: HomePage(),
      routes: {
        '/knowledge': (context) => KnowledgeFeature.getScreen(),
      },
    );
  }
}

/// 示例2：在编辑器中使用知识库搜索
class EditorWithKnowledge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI写作编辑器'),
      ),
      body: Column(
        children: [
          // 知识库搜索栏
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: KnowledgeFeature.getQuickSearch(
              hintText: '搜索角色和世界观...',
              onResultSelected: (result) {
                _handleKnowledgeInsert(context, result);
              },
            ),
          ),

          // 编辑器内容区域
          Expanded(
            child: TextField(
              maxLines: null,
              decoration: InputDecoration(
                hintText: '开始写作...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleKnowledgeInsert(BuildContext context, dynamic result) {
    // 根据搜索结果类型处理
    if (result is SearchResult) {
      switch (result.type) {
        case SearchResultType.character:
          final character = result.data as CharacterModel;
          _insertCharacterPrompt(character);
          break;
        case SearchResultType.world:
          final world = result.data as WorldModel;
          _insertWorldPrompt(world);
          break;
        default:
          break;
      }
    }
  }

  void _insertCharacterPrompt(CharacterModel character) {
    // 将角色信息插入到编辑器
    final prompt = character.generateAIPrompt();
    // 这里可以实现具体的插入逻辑
    Logger.debug('插入角色信息: $prompt');
  }

  void _insertWorldPrompt(WorldModel world) {
    // 将世界观信息插入到编辑器
    final prompt = world.generateAIPrompt();
    // 这里可以实现具体的插入逻辑
    Logger.debug('插入世界观信息: $prompt');
  }
}

/// 示例3：创建和管理角色卡
class CharacterManagementExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final characterService = context.watch<CharacterService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('角色管理'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createSampleCharacter(context),
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: characterService.characters.length,
        itemBuilder: (context, index) {
          final character = characterService.characters[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(character.name[0]),
            ),
            title: Text(character.name),
            subtitle: Text(character.tags.join(', ')),
            onTap: () {
              characterService.setCurrentCharacter(character);
              // 显示详情
            },
          );
        },
      ),
    );
  }

  Future<void> _createSampleCharacter(BuildContext context) async {
    final service = context.read<CharacterService>();

    // 创建示例角色
    final character = await service.createCharacter(
      name: '艾莉亚',
      age: 25,
      appearance: '身高170cm，银色长发，碧眼',
      personality: '勇敢、果断、富有正义感',
      background: '出身贵族世家的年轻战士',
      speakingStyle: '简练直接，偶尔表现出优雅的贵族气质',
      relationships: ['与主角是青梅竹马', '王国的守护者'],
      tags: ['主角', '战士', '贵族'],
    );

    // 显示成功消息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('创建角色: ${character.name}')),
    );
  }
}

/// 示例4：批量导入导出
class DataManagementExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('数据管理'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.file_download),
            title: Text('导出角色卡'),
            subtitle: Text('导出所有角色卡为JSON文件'),
            onTap: () => _exportCharacters(context),
          ),
          ListTile(
            leading: Icon(Icons.file_upload),
            title: Text('导入角色卡'),
            subtitle: Text('从JSON文件导入角色卡'),
            onTap: () => _importCharacters(context),
          ),
          ListTile(
            leading: Icon(Icons.backup),
            title: Text('导出世界观'),
            subtitle: Text('导出所有世界观为JSON文件'),
            onTap: () => _exportWorlds(context),
          ),
          ListTile(
            leading: Icon(Icons.restore),
            title: Text('导入世界观'),
            subtitle: Text('从JSON文件导入世界观'),
            onTap: () => _importWorlds(context),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCharacters(BuildContext context) async {
    final service = context.read<CharacterService>();
    final success = await service.exportToFile();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出成功')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败')),
      );
    }
  }

  Future<void> _importCharacters(BuildContext context) async {
    final service = context.read<CharacterService>();
    final count = await service.importFromFile();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('成功导入 $count 个角色卡')),
    );
  }

  Future<void> _exportWorlds(BuildContext context) async {
    final service = context.read<WorldService>();
    final success = await service.exportToFile();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出成功')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败')),
      );
    }
  }

  Future<void> _importWorlds(BuildContext context) async {
    final service = context.read<WorldService>();
    final count = await service.importFromFile();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('成功导入 $count 个世界观')),
    );
  }
}

/// 示例5：搜索和筛选
class SearchExample extends StatefulWidget {
  @override
  State<SearchExample> createState() => _SearchExampleState();
}

class _SearchExampleState extends State<SearchExample> {
  final TextEditingController _searchController = TextEditingController();
  List<CharacterModel> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(BuildContext context) {
    final service = context.read<CharacterService>();
    setState(() {
      _searchResults = service.searchCharacters(_searchController.text);
    });
  }

  void _filterByTag(BuildContext context, String tag) {
    final service = context.read<CharacterService>();
    setState(() {
      _searchResults = service.filterByTag(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final characterService = context.watch<CharacterService>();
    final allTags = characterService.getAllTags();

    return Scaffold(
      appBar: AppBar(
        title: Text('搜索和筛选'),
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '搜索角色',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                  },
                ),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _performSearch(context),
            ),
          ),

          // 标签筛选
          if (allTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('按标签筛选:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allTags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () => _filterByTag(context, tag),
                        deleteIcon: Icon(Icons.filter_list),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // 搜索结果
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final character = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(character.name[0])),
                  title: Text(character.name),
                  subtitle: Text(character.tags.join(', ')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 示例6：AI集成
class AIIntegrationExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final characterService = context.watch<CharacterService>();
    final worldService = context.watch<WorldService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('AI写作助手'),
      ),
      body: ListView(
        children: [
          if (characterService.currentCharacter != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前角色:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(characterService.currentCharacter!.name),
                    SizedBox(height: 16),
                    Text('AI提示词:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        characterService.currentCharacter!.generateAIPrompt(),
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _copyToClipboard(
                          characterService.currentCharacter!.generateAIPrompt(),
                        );
                      },
                      child: Text('复制提示词'),
                    ),
                  ],
                ),
              ),
            ),

          if (worldService.currentWorld != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前世界观:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(worldService.currentWorld!.name),
                    SizedBox(height: 16),
                    Text('AI提示词:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        worldService.currentWorld!.generateAIPrompt(),
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _copyToClipboard(
                          worldService.currentWorld!.generateAIPrompt(),
                        );
                      },
                      child: Text('复制提示词'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    // 实现复制到剪贴板的逻辑
    Logger.debug('复制到剪贴板: $text');
  }
}

/// 示例7：快捷键集成
class KeyboardShortcutExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, KeyboardKey.keyK):
            const _ShowSearchIntent(),
      },
      actions: {
        _ShowSearchIntent: CallbackAction<_ShowSearchIntent>(
          onInvoke: (_ShowSearchIntent intent) {
            _showSearchDialog(context);
            return null;
          },
        ),
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('快捷键示例'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('按 Ctrl+K 打开搜索'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showSearchDialog(context),
                child: Text('打开搜索 (Ctrl+K)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    KnowledgeSearchDialog.show(context);
  }
}

class _ShowSearchIntent extends Intent {
  const _ShowSearchIntent();
}
*/

/// 主函数注释
///
/// 要运行这些示例，需要：
/// 1. 确保已安装Flutter SDK
/// 2. 运行 `flutter pub get` 安装依赖
/// 3. 运行 `flutter pub run build_runner build` 生成Hive适配器
/// 4. 取消上面的注释并运行相应的示例

void main() {
  Logger.debug('知识库功能使用示例');
  Logger.debug('请取消代码中的注释来查看具体使用方法');
  Logger.debug('');
  Logger.debug('主要功能:');
  Logger.debug('1. 角色卡管理 - 创建、编辑、删除角色');
  Logger.debug('2. 世界观设定 - 管理世界规则和设定');
  Logger.debug('3. 智能搜索 - 搜索角色、世界观、地点、组织');
  Logger.debug('4. 批量导入导出 - JSON格式的数据交换');
  Logger.debug('5. AI集成 - 自动生成AI写作提示词');
  Logger.debug('6. 快捷键支持 - 提高使用效率');
}

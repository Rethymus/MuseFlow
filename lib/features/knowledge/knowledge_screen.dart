import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'character_service.dart';
import 'character_model.dart';
import 'world_service.dart';
import 'world_model.dart';
import 'knowledge_search.dart';
import 'knowledge_helpers.dart';
import 'character_form_screen.dart';
import 'world_form_screen.dart';

/// 知识库主界面
class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    final characterService = context.read<CharacterService>();
    final worldService = context.read<WorldService>();

    await Future.wait([
      characterService.initialize(),
      worldService.initialize(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库'),
        actions: [
          // 搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),

          // 导入按钮
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () => _handleImport(),
            tooltip: '导入',
          ),

          // 导出按钮
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _handleExport(),
            tooltip: '导出',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '角色卡'),
            Tab(text: '世界观'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CharacterTab(),
          _WorldTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleAdd(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSearchDialog() {
    KnowledgeSearchDialog.show(context);
  }

  void _handleImport() {
    final tabIndex = _tabController.index;
    if (tabIndex == 0) {
      _importCharacters();
    } else {
      _importWorlds();
    }
  }

  void _handleExport() {
    final tabIndex = _tabController.index;
    if (tabIndex == 0) {
      _exportCharacters();
    } else {
      _exportWorlds();
    }
  }

  void _handleAdd() {
    final tabIndex = _tabController.index;
    if (tabIndex == 0) {
      _showCharacterForm();
    } else {
      _showWorldForm();
    }
  }

  Future<void> _importCharacters() async {
    final service = context.read<CharacterService>();
    final count = await service.importFromFile();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 $count 个角色卡')),
      );
    }
  }

  Future<void> _exportCharacters() async {
    final service = context.read<CharacterService>();
    final success = await service.exportToFile();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '导出成功' : '导出失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _importWorlds() async {
    final service = context.read<WorldService>();
    final count = await service.importFromFile();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 $count 个世界观')),
      );
    }
  }

  Future<void> _exportWorlds() async {
    final service = context.read<WorldService>();
    final success = await service.exportToFile();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '导出成功' : '导出失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showCharacterForm({CharacterModel? character}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CharacterFormScreen(character: character),
      ),
    );
  }

  void _showWorldForm({WorldModel? world}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorldFormScreen(world: world),
      ),
    );
  }
}

/// 角色卡标签页
class _CharacterTab extends StatelessWidget {
  const _CharacterTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CharacterService>(
      builder: (context, service, child) {
        if (!service.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        if (service.characters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  '还没有角色卡',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击右下角的 + 创建第一个角色卡',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Row(
          children: [
            // 左侧：角色列表
            SizedBox(
              width: 300,
              child: _buildCharacterList(context, service),
            ),

            // 分隔线
            const VerticalDivider(width: 1),

            // 右侧：详情面板
            Expanded(
              child: service.currentCharacter != null
                  ? _CharacterDetailPanel(
                      character: service.currentCharacter!,
                    )
                  : buildEmptyDetail('角色卡'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCharacterList(BuildContext context, CharacterService service) {
    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索角色...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: (query) {
              // 可以添加搜索逻辑
            },
          ),
        ),

        // 角色列表
        Expanded(
          child: ListView.builder(
            itemCount: service.characters.length,
            itemBuilder: (context, index) {
              final character = service.characters[index];
              final isSelected = service.currentCharacter?.id == character.id;

              return ListTile(
                selected: isSelected,
                leading: CircleAvatar(
                  child: Text(character.name[0]),
                ),
                title: Text(character.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (character.age != null) Text('${character.age}岁'),
                    if (character.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: character.tags
                            .take(2)
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                  ],
                ),
                onTap: () {
                  service.setCurrentCharacter(character);
                },
                onLongPress: () {
                  _showCharacterOptions(
                    context,
                    service,
                    character,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCharacterOptions(
    BuildContext context,
    CharacterService service,
    CharacterModel character,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CharacterFormScreen(character: character),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('删除'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认删除'),
                    content: Text('确定要删除角色 "${character.name}" 吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await service.deleteCharacter(character.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 角色详情面板
class _CharacterDetailPanel extends StatelessWidget {
  final CharacterModel character;

  const _CharacterDetailPanel({required this.character});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                child: Text(
                  character.name[0],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (character.age != null)
                      Text(
                        '${character.age}岁',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 标签
          if (character.tags.isNotEmpty) ...[
            const Text(
              '标签',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  character.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // 详细信息
          buildSection('外貌', character.appearance),
          buildSection('性格', character.personality),
          buildSection('背景', character.background),
          buildSection('说话风格', character.speakingStyle),

          if (character.relationships.isNotEmpty) ...[
            const Text(
              '人际关系',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...character.relationships.map(
              (rel) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(rel)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          buildSection('备注', character.notes),

          // AI提示词预览
          const SizedBox(height: 16),
          const Text(
            'AI提示词预览',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              character.generateAIPrompt(),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 世界观标签页
class _WorldTab extends StatelessWidget {
  const _WorldTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<WorldService>(
      builder: (context, service, child) {
        if (!service.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        if (service.worlds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.public, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  '还没有世界观',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击右下角的 + 创建第一个世界观',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Row(
          children: [
            // 左侧：世界观列表
            SizedBox(
              width: 300,
              child: _buildWorldList(context, service),
            ),

            // 分隔线
            const VerticalDivider(width: 1),

            // 右侧：详情面板
            Expanded(
              child: service.currentWorld != null
                  ? _WorldDetailPanel(world: service.currentWorld!)
                  : buildEmptyDetail('世界观'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorldList(BuildContext context, WorldService service) {
    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索世界观...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: (query) {
              // 可以添加搜索逻辑
            },
          ),
        ),

        // 世界观列表
        Expanded(
          child: ListView.builder(
            itemCount: service.worlds.length,
            itemBuilder: (context, index) {
              final world = service.worlds[index];
              final isSelected = service.currentWorld?.id == world.id;

              return ListTile(
                selected: isSelected,
                leading: CircleAvatar(
                  child: Icon(getWorldIcon(world.worldType)),
                ),
                title: Text(world.name),
                subtitle: Text(world.worldType),
                trailing: world.tags.isNotEmpty
                    ? Icon(Icons.label, color: Colors.blue[300])
                    : null,
                onTap: () {
                  service.setCurrentWorld(world);
                },
                onLongPress: () {
                  _showWorldOptions(context, service, world);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showWorldOptions(
    BuildContext context,
    WorldService service,
    WorldModel world,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WorldFormScreen(world: world),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('删除'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认删除'),
                    content: Text('确定要删除世界观 "${world.name}" 吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await service.deleteWorld(world.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 世界观详情面板
class _WorldDetailPanel extends StatelessWidget {
  final WorldModel world;

  const _WorldDetailPanel({required this.world});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                child: Icon(getWorldIcon(world.worldType)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      world.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      world.worldType,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 标签
          if (world.tags.isNotEmpty) ...[
            const Text(
              '标签',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  world.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // 基本信息行
          if (world.era != null ||
              world.magicSystem != null ||
              world.technology != null)
            Row(
              children: [
                if (world.era != null) _buildBadge('时代', world.era!),
                if (world.magicSystem != null)
                  _buildBadge('魔法', world.magicSystem!),
                if (world.technology != null)
                  _buildBadge('科技', world.technology!),
              ],
            ),

          const SizedBox(height: 16),

          // 详细信息
          buildSection('地理环境', world.geography),
          buildSection('历史背景', world.history),

          if (world.rules.isNotEmpty) ...[
            const Text(
              '世界规则',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...world.rules.map(
              (rule) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(rule)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (world.locations.isNotEmpty) ...[
            const Text(
              '主要地点',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...world.locations.map(
              (location) => Card(
                child: ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(location.name),
                  subtitle: Text(location.description),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (world.organizations.isNotEmpty) ...[
            const Text(
              '主要势力',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...world.organizations.map(
              (org) => Card(
                child: ListTile(
                  leading: const Icon(Icons.groups),
                  title: Text(org.name),
                  subtitle: Text(org.description),
                  trailing:
                      org.leader != null ? Text('领袖: ${org.leader}') : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          buildSection('备注', world.notes),

          // AI提示词预览
          const SizedBox(height: 16),
          const Text(
            'AI提示词预览',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              world.generateAIPrompt(),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

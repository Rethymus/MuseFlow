import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart' show Uuid;

import 'character_service.dart';
import 'character_model.dart';
import 'world_service.dart';
import 'world_model.dart';
import 'knowledge_search.dart';

// ============================================================
// 知识库页面共享工具方法
// ============================================================

/// 根据世界观类型返回对应图标
IconData _getWorldIcon(String worldType) {
  switch (worldType.toLowerCase()) {
    case '奇幻':
      return Icons.auto_awesome;
    case '科幻':
      return Icons.rocket_launch;
    case '现实':
      return Icons.location_city;
    case '历史':
      return Icons.history_edu;
    default:
      return Icons.public;
  }
}

/// 构建空详情占位组件，[type] 为类型名称（如"角色卡"、"世界观"）
Widget _buildEmptyDetail(String type) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.description, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          '选择一个$type查看详情',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    ),
  );
}

/// 构建带标题和内容的详情区块，内容为空时返回空组件
Widget _buildSection(String title, String? content) {
  if (content?.isEmpty ?? true) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text(content!),
      const SizedBox(height: 16),
    ],
  );
}

/// 知识库主界面
class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({Key? key}) : super(key: key);

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
                  : _buildEmptyDetail('角色卡'),
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
          _buildSection('外貌', character.appearance),
          _buildSection('性格', character.personality),
          _buildSection('背景', character.background),
          _buildSection('说话风格', character.speakingStyle),

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

          _buildSection('备注', character.notes),

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
                  : _buildEmptyDetail('世界观'),
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
                  child: Icon(_getWorldIcon(world.worldType)),
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
                child: Icon(_getWorldIcon(world.worldType)),
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
          _buildSection('地理环境', world.geography),
          _buildSection('历史背景', world.history),

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

          _buildSection('备注', world.notes),

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

/// 角色表单屏幕
class CharacterFormScreen extends StatefulWidget {
  final CharacterModel? character;

  const CharacterFormScreen({Key? key, this.character}) : super(key: key);

  @override
  State<CharacterFormScreen> createState() => _CharacterFormScreenState();
}

class _CharacterFormScreenState extends State<CharacterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _appearanceController;
  late final TextEditingController _personalityController;
  late final TextEditingController _backgroundController;
  late final TextEditingController _speakingStyleController;
  late final TextEditingController _notesController;
  final List<String> _relationships = [];
  final List<String> _tags = [];
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character?.name ?? '');
    _ageController =
        TextEditingController(text: widget.character?.age?.toString() ?? '');
    _appearanceController =
        TextEditingController(text: widget.character?.appearance ?? '');
    _personalityController =
        TextEditingController(text: widget.character?.personality ?? '');
    _backgroundController =
        TextEditingController(text: widget.character?.background ?? '');
    _speakingStyleController =
        TextEditingController(text: widget.character?.speakingStyle ?? '');
    _notesController =
        TextEditingController(text: widget.character?.notes ?? '');
    if (widget.character != null) {
      _relationships.addAll(widget.character!.relationships);
      _tags.addAll(widget.character!.tags);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _appearanceController.dispose();
    _personalityController.dispose();
    _backgroundController.dispose();
    _speakingStyleController.dispose();
    _notesController.dispose();
    _relationshipController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addRelationship() {
    if (_relationshipController.text.isNotEmpty) {
      setState(() {
        _relationships.add(_relationshipController.text);
        _relationshipController.clear();
      });
    }
  }

  void _removeRelationship(int index) {
    setState(() {
      _relationships.removeAt(index);
    });
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text);
        _tagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final service = context.read<CharacterService>();

      final age = _ageController.text.isNotEmpty
          ? int.tryParse(_ageController.text)
          : null;

      if (widget.character != null) {
        // 更新现有角色
        final updated = widget.character!.copyWith(
          name: _nameController.text,
          age: age,
          appearance: _appearanceController.text,
          personality: _personalityController.text,
          background: _backgroundController.text,
          speakingStyle: _speakingStyleController.text,
          relationships: _relationships,
          tags: _tags,
          notes: _notesController.text,
        );
        await service.updateCharacter(updated);
      } else {
        // 创建新角色
        await service.createCharacter(
          name: _nameController.text,
          age: age,
          appearance: _appearanceController.text,
          personality: _personalityController.text,
          background: _backgroundController.text,
          speakingStyle: _speakingStyleController.text,
          relationships: _relationships,
          tags: _tags,
          notes: _notesController.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.character != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑角色' : '创建角色'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 基本信息
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '姓名',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? '请输入姓名' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: '年龄',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // 详细信息
            TextFormField(
              controller: _appearanceController,
              decoration: const InputDecoration(
                labelText: '外貌',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _personalityController,
              decoration: const InputDecoration(
                labelText: '性格',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _backgroundController,
              decoration: const InputDecoration(
                labelText: '背景',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _speakingStyleController,
              decoration: const InputDecoration(
                labelText: '说话风格',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // 人际关系
            const Text('人际关系', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _relationshipController,
                    decoration: const InputDecoration(
                      hintText: '添加关系',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addRelationship(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addRelationship,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._relationships.map((rel) => ListTile(
                  title: Text(rel),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        _removeRelationship(_relationships.indexOf(rel)),
                  ),
                )),

            const SizedBox(height: 16),

            // 标签
            const Text('标签', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: '添加标签',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () => _removeTag(_tags.indexOf(tag)),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 16),

            // 备注
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}

/// 世界观表单屏幕
class WorldFormScreen extends StatefulWidget {
  final WorldModel? world;

  const WorldFormScreen({Key? key, this.world}) : super(key: key);

  @override
  State<WorldFormScreen> createState() => _WorldFormScreenState();
}

class _WorldFormScreenState extends State<WorldFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _worldTypeController;
  late final TextEditingController _eraController;
  late final TextEditingController _magicSystemController;
  late final TextEditingController _technologyController;
  late final TextEditingController _geographyController;
  late final TextEditingController _historyController;
  late final TextEditingController _notesController;
  final List<String> _rules = [];
  final List<String> _tags = [];
  final List<Location> _locations = [];
  final List<Organization> _organizations = [];
  final TextEditingController _ruleController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.world?.name ?? '');
    _worldTypeController =
        TextEditingController(text: widget.world?.worldType ?? '奇幻');
    _eraController = TextEditingController(text: widget.world?.era ?? '');
    _magicSystemController =
        TextEditingController(text: widget.world?.magicSystem ?? '');
    _technologyController =
        TextEditingController(text: widget.world?.technology ?? '');
    _geographyController =
        TextEditingController(text: widget.world?.geography ?? '');
    _historyController =
        TextEditingController(text: widget.world?.history ?? '');
    _notesController = TextEditingController(text: widget.world?.notes ?? '');

    if (widget.world != null) {
      _rules.addAll(widget.world!.rules);
      _tags.addAll(widget.world!.tags);
      _locations.addAll(widget.world!.locations);
      _organizations.addAll(widget.world!.organizations);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _worldTypeController.dispose();
    _eraController.dispose();
    _magicSystemController.dispose();
    _technologyController.dispose();
    _geographyController.dispose();
    _historyController.dispose();
    _notesController.dispose();
    _ruleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addRule() {
    if (_ruleController.text.isNotEmpty) {
      setState(() {
        _rules.add(_ruleController.text);
        _ruleController.clear();
      });
    }
  }

  void _removeRule(int index) {
    setState(() {
      _rules.removeAt(index);
    });
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text);
        _tagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  void _addLocation() {
    showDialog(
      context: context,
      builder: (context) => _LocationFormDialog(
        onSave: (location) {
          setState(() {
            _locations.add(location);
          });
        },
      ),
    );
  }

  void _editLocation(Location location) {
    showDialog(
      context: context,
      builder: (context) => _LocationFormDialog(
        location: location,
        onSave: (updated) {
          setState(() {
            final index = _locations.indexWhere((l) => l.id == updated.id);
            if (index != -1) {
              _locations[index] = updated;
            }
          });
        },
      ),
    );
  }

  void _removeLocation(String id) {
    setState(() {
      _locations.removeWhere((l) => l.id == id);
    });
  }

  void _addOrganization() {
    showDialog(
      context: context,
      builder: (context) => _OrganizationFormDialog(
        onSave: (org) {
          setState(() {
            _organizations.add(org);
          });
        },
      ),
    );
  }

  void _editOrganization(Organization org) {
    showDialog(
      context: context,
      builder: (context) => _OrganizationFormDialog(
        organization: org,
        onSave: (updated) {
          setState(() {
            final index = _organizations.indexWhere((o) => o.id == updated.id);
            if (index != -1) {
              _organizations[index] = updated;
            }
          });
        },
      ),
    );
  }

  void _removeOrganization(String id) {
    setState(() {
      _organizations.removeWhere((o) => o.id == id);
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final service = context.read<WorldService>();

      if (widget.world != null) {
        // 更新现有世界观
        final updated = widget.world!.copyWith(
          name: _nameController.text,
          worldType: _worldTypeController.text,
          era: _eraController.text,
          magicSystem: _magicSystemController.text,
          technology: _technologyController.text,
          geography: _geographyController.text,
          history: _historyController.text,
          rules: _rules,
          tags: _tags,
          locations: _locations,
          organizations: _organizations,
          notes: _notesController.text,
        );
        await service.updateWorld(updated);
      } else {
        // 创建新世界观
        await service.createWorld(
          name: _nameController.text,
          worldType: _worldTypeController.text,
          era: _eraController.text,
          magicSystem: _magicSystemController.text,
          technology: _technologyController.text,
          geography: _geographyController.text,
          history: _historyController.text,
          rules: _rules,
          tags: _tags,
          locations: _locations,
          organizations: _organizations,
          notes: _notesController.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.world != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑世界观' : '创建世界观'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 基本信息
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '世界名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? '请输入世界名称' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _worldTypeController,
              decoration: const InputDecoration(
                labelText: '世界类型',
                border: OutlineInputBorder(),
                hintText: '如：奇幻、科幻、现实、历史',
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _eraController,
              decoration: const InputDecoration(
                labelText: '时代',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // 系统设定
            TextFormField(
              controller: _magicSystemController,
              decoration: const InputDecoration(
                labelText: '魔法体系',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _technologyController,
              decoration: const InputDecoration(
                labelText: '科技水平',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // 环境和历史
            TextFormField(
              controller: _geographyController,
              decoration: const InputDecoration(
                labelText: '地理环境',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _historyController,
              decoration: const InputDecoration(
                labelText: '历史背景',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // 世界规则
            const Text('世界规则', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ruleController,
                    decoration: const InputDecoration(
                      hintText: '添加规则',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addRule(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addRule,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._rules.map((rule) => ListTile(
                  title: Text(rule),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeRule(_rules.indexOf(rule)),
                  ),
                )),

            const SizedBox(height: 16),

            // 地点
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('主要地点',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('添加地点'),
                  onPressed: _addLocation,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._locations.map((location) => ListTile(
                  title: Text(location.name),
                  subtitle: Text(location.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editLocation(location),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeLocation(location.id),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 16),

            // 势力组织
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('主要势力',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('添加势力'),
                  onPressed: _addOrganization,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._organizations.map((org) => ListTile(
                  title: Text(org.name),
                  subtitle: Text(org.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editOrganization(org),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeOrganization(org.id),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 16),

            // 标签
            const Text('标签', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: '添加标签',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () => _removeTag(_tags.indexOf(tag)),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 16),

            // 备注
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}

/// 地点表单对话框
class _LocationFormDialog extends StatefulWidget {
  final Location? location;
  final Function(Location) onSave;

  const _LocationFormDialog({
    Key? key,
    this.location,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends State<_LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final List<String> _relatedCharacters = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.location?.description ?? '');
    if (widget.location != null) {
      _relatedCharacters.addAll(widget.location!.relatedCharacters);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final location = Location(
        id: widget.location?.id ?? const Uuid().v4(),
        name: _nameController.text,
        description: _descriptionController.text,
        relatedCharacters: _relatedCharacters,
      );
      widget.onSave(location);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.location != null ? '编辑地点' : '添加地点'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '地点名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? '请输入地点名称' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? '请输入描述' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 组织表单对话框
class _OrganizationFormDialog extends StatefulWidget {
  final Organization? organization;
  final Function(Organization) onSave;

  const _OrganizationFormDialog({
    Key? key,
    this.organization,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_OrganizationFormDialog> createState() =>
      _OrganizationFormDialogState();
}

class _OrganizationFormDialogState extends State<_OrganizationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _leaderController;
  late final TextEditingController _philosophyController;
  final List<String> _members = [];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.organization?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.organization?.description ?? '');
    _leaderController =
        TextEditingController(text: widget.organization?.leader ?? '');
    _philosophyController =
        TextEditingController(text: widget.organization?.philosophy ?? '');
    if (widget.organization != null) {
      _members.addAll(widget.organization!.members);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _leaderController.dispose();
    _philosophyController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final org = Organization(
        id: widget.organization?.id ?? const Uuid().v4(),
        name: _nameController.text,
        description: _descriptionController.text,
        leader: _leaderController.text,
        philosophy: _philosophyController.text,
        members: _members,
      );
      widget.onSave(org);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.organization != null ? '编辑组织' : '添加组织'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '组织名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? '请输入组织名称' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? '请输入描述' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _leaderController,
                decoration: const InputDecoration(
                  labelText: '领袖',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _philosophyController,
                decoration: const InputDecoration(
                  labelText: '理念/宗旨',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

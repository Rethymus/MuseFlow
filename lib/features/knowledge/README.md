# MuseFlow 知识库系统

完整的角色卡和世界观设定管理系统，支持智能搜索、批量导入导出和AI写作集成。

## 功能特性

### 1. 角色卡管理
- **基本信息**：姓名、年龄、外貌、性格、背景故事
- **说话风格**：记录角色的说话特点和语言风格
- **人际关系**：管理角色之间的关系网络
- **标签系统**：快速分类和筛选角色
- **AI集成**：自动生成角色描述的AI提示词

### 2. 世界观设定
- **世界类型**：奇幻、科幻、现实、历史等
- **时代设定**：时代背景和世界观
- **系统设定**：魔法体系、科技水平
- **地点管理**：世界的地理环境和重要地点
- **势力组织**：世界的势力、组织及其关系
- **AI集成**：自动生成世界观描述的AI提示词

### 3. 智能搜索
- **全局搜索**：一键搜索角色、世界观、地点、组织
- **模糊匹配**：支持关键词模糊搜索
- **分类筛选**：按标签和类型筛选
- **快速插入**：搜索结果可直接插入到AI写作中

### 4. 数据管理
- **本地存储**：基于Hive的高性能本地数据库
- **批量导入**：支持JSON格式的批量导入
- **批量导出**：导出为JSON格式便于备份和分享
- **数据安全**：支持多项目数据隔离

## 项目结构

```
lib/features/knowledge/
├── knowledge.dart              # 功能导出入口
├── knowledge_init.dart         # 初始化和配置
├── knowledge_screen.dart       # 主界面UI
├── knowledge_search.dart       # 搜索功能
├── character_model.dart        # 角色卡数据模型
├── world_model.dart            # 世界观数据模型
├── character_service.dart      # 角色卡服务
└── world_service.dart          # 世界观服务
```

## 快速开始

### 1. 初始化

在 `main.dart` 中添加：

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'lib/features/knowledge/knowledge.dart';

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

        // 其他providers...
      ],
      child: MyApp(),
    ),
  );
}
```

### 2. 添加导航路由

```dart
MaterialApp(
  routes: {
    '/knowledge': (context) => KnowledgeFeature.getScreen(),
  },
)
```

### 3. 在编辑器中集成搜索

```dart
import 'lib/features/knowledge/knowledge.dart';

class EditorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 添加知识库搜索栏
        KnowledgeFeature.getQuickSearch(
          hintText: '搜索角色和世界观...',
          onResultSelected: (result) {
            // 将搜索结果插入到编辑器
            _handleKnowledgeInsert(result);
          },
        ),

        // 编辑器内容
        Expanded(
          child: EditorWidget(),
        ),
      ],
    );
  }

  void _handleKnowledgeInsert(dynamic result) {
    // 处理搜索结果的插入逻辑
    // 可以插入角色描述、世界观设定等
  }
}
```

## 使用示例

### 创建角色卡

```dart
final characterService = context.read<CharacterService>();

final character = await characterService.createCharacter(
  name: '艾莉亚',
  age: 25,
  appearance: '身高170cm，银色长发，碧眼',
  personality: '勇敢、果断、富有正义感',
  background: '出身贵族世家的年轻战士',
  speakingStyle: '简练直接，偶尔表现出优雅的贵族气质',
  relationships: ['与主角是青梅竹马', '王国的守护者'],
  tags: ['主角', '战士', '贵族'],
);

// 自动生成AI提示词
final aiPrompt = character.generateAIPrompt();
print(aiPrompt);
```

### 创建世界观

```dart
final worldService = context.read<WorldService>();

final world = await worldService.createWorld(
  name: '艾瑟尼亚大陆',
  worldType: '奇幻',
  era: '中世纪风格',
  magicSystem: '元素魔法体系',
  technology: '低魔技术水平',
  geography: '大陆地形多样，包含森林、山脉、沙漠',
  history: '历经千年战争的古老大陆',
  rules: [
    '魔法需要天赋和训练',
    '神明真实存在但很少干涉',
    '龙族已经消失千年'
  ],
  locations: [
    Location(
      id: 'loc_1',
      name: '王都',
      description: '艾瑟尼亚的政治和经济中心',
    ),
  ],
  tags: ['高魔世界', '战争', '冒险'],
);
```

### 搜索知识库

```dart
// 显示全局搜索对话框
await KnowledgeSearchDialog.show(context);

// 或者使用快速搜索栏
KnowledgeQuickSearch(
  hintText: '搜索角色、世界观...',
  onResultSelected: (result) {
    switch (result.type) {
      case SearchResultType.character:
        final character = result.data as CharacterModel;
        print('找到角色: ${character.name}');
        break;
      case SearchResultType.world:
        final world = result.data as WorldModel;
        print('找到世界观: ${world.name}');
        break;
      // 其他类型...
    }
  },
)
```

### 批量导入导出

```dart
// 导出所有角色卡
final characterService = context.read<CharacterService>();
await characterService.exportToFile();

// 导入角色卡
final count = await characterService.importFromFile();
print('成功导入 $count 个角色卡');

// 导出特定世界观
final worldService = context.read<WorldService>();
await worldService.exportToFile(ids: ['world_id_1', 'world_id_2']);
```

## 数据格式

### 角色卡JSON格式

```json
{
  "id": "uuid",
  "name": "角色姓名",
  "age": 25,
  "appearance": "外貌描述",
  "personality": "性格特点",
  "background": "背景故事",
  "speakingStyle": "说话风格",
  "relationships": ["关系1", "关系2"],
  "tags": ["标签1", "标签2"],
  "notes": "备注信息",
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

### 世界观JSON格式

```json
{
  "id": "uuid",
  "name": "世界名称",
  "worldType": "世界类型",
  "era": "时代",
  "magicSystem": "魔法体系",
  "technology": "科技水平",
  "geography": "地理环境",
  "history": "历史背景",
  "rules": ["规则1", "规则2"],
  "tags": ["标签1", "标签2"],
  "locations": [
    {
      "id": "uuid",
      "name": "地点名称",
      "description": "地点描述",
      "relatedCharacters": ["角色1", "角色2"]
    }
  ],
  "organizations": [
    {
      "id": "uuid",
      "name": "组织名称",
      "description": "组织描述",
      "leader": "领袖",
      "members": ["成员1", "成员2"],
      "philosophy": "组织理念"
    }
  ],
  "notes": "备注信息",
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

## AI写作集成

知识库系统专为AI写作优化，可以自动生成结构化的AI提示词：

```dart
// 角色AI提示词
final character = characterService.currentCharacter;
final characterPrompt = character.generateAIPrompt();

// 输出示例：
// 角色名称：艾莉亚
// 年龄：25岁
// 外貌：身高170cm，银色长发，碧眼
// 性格：勇敢、果断、富有正义感
// 背景：出身贵族世家的年轻战士
// 说话风格：简练直接，偶尔表现出优雅的贵族气质
// 关键词：主角、战士、贵族

// 世界观AI提示词
final world = worldService.currentWorld;
final worldPrompt = world.generateAIPrompt();

// 输出示例：
// 世界名称：艾瑟尼亚大陆
// 世界类型：奇幻
// 时代：中世纪风格
// 魔法体系：元素魔法体系
// 世界规则：
//   - 魔法需要天赋和训练
//   - 神明真实存在但很少干涉
// 主要地点：
//   - 王都：艾瑟尼亚的政治和经济中心
```

## 高级功能

### 1. 标签管理

```dart
// 获取所有标签
final allTags = characterService.getAllTags();

// 按标签筛选
final warriors = characterService.filterByTag('战士');
final fantasyWorlds = worldService.filterByTag('奇幻');
```

### 2. 搜索和筛选

```dart
// 搜索角色
final results = characterService.searchCharacters('艾莉亚');

// 按类型筛选世界观
final fantasyWorlds = worldService.filterByType('奇幻');
```

### 3. 数据持久化

```dart
// 初始化时指定项目ID（支持多项目）
await characterService.initialize(projectId: 'project_1');

// 清空数据
await characterService.clearAll();

// 关闭服务
await characterService.dispose();
```

## 快捷键

- `Ctrl/Cmd + K`：打开全局搜索对话框
- `Ctrl/Cmd + N`：新建角色卡/世界观
- `Ctrl/Cmd + E`：编辑当前选中项
- `Ctrl/Cmd + D`：删除当前选中项

## 注意事项

1. **Hive初始化**：确保在使用知识库功能前完成Hive初始化
2. **Provider配置**：需要在应用根节点添加知识库的Providers
3. **适配器注册**：适配器只需注册一次，重复注册会报错
4. **数据迁移**：更换设备时需要导出数据再导入
5. **性能优化**：大量数据时建议使用分页或虚拟滚动

## 常见问题

### Q: 如何备份数据？
A: 使用导出功能将数据保存为JSON文件，需要时导入即可。

### Q: 支持多项目吗？
A: 支持，初始化时传入不同的projectId即可实现数据隔离。

### Q: 如何与AI写作集成？
A: 使用generateAIPrompt()方法生成结构化提示词，传递给AI模型。

### Q: 可以批量编辑吗？
A: 目前支持批量导入导出，批量编辑功能可以自行扩展。

## 扩展开发

### 添加新的搜索类型

```dart
// 在knowledge_search.dart中扩展SearchResultType
enum SearchResultType {
  character,
  world,
  location,
  organization,
  customType, // 添加新类型
}
```

### 自定义UI

可以继承或修改knowledge_screen.dart中的组件来自定义UI。

### 添加新字段

在相应的Model中添加HiveField字段，运行代码生成即可。

## 许可证

MIT License

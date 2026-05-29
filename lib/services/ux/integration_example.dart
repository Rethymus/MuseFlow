import 'package:flutter/material.dart';
import 'ux_service_integration.dart';

/// UX服务集成示例 - 展示如何在现有应用中逐步启用UX功能
///
/// 这个示例展示了三种集成方式：
/// 1. 最小集成 - 仅启用基础服务
/// 2. 中等集成 - 添加交互记录
/// 3. 完整集成 - 使用所有UX功能
class UXIntegrationExample extends StatelessWidget {
  const UXIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuseFlow UX集成示例',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const IntegrationGuidePage(),
    );
  }
}

/// 集成指南页面
class IntegrationGuidePage extends StatefulWidget {
  const IntegrationGuidePage({super.key});

  @override
  State<IntegrationGuidePage> createState() => _IntegrationGuidePageState();
}

class _IntegrationGuidePageState extends State<IntegrationGuidePage> {
  String _selectedMode = 'minimal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UX服务集成指南'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntegrationModeSelector(),
          const SizedBox(height: 24),
          _buildModeInstructions(),
          const SizedBox(height: 24),
          _buildCodeExample(),
          const SizedBox(height: 24),
          _buildTestingSection(),
        ],
      ),
    );
  }

  /// 构建集成模式选择器
  Widget _buildIntegrationModeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择集成模式',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('最小集成'),
              subtitle: const Text('仅启用基础服务，不改变现有UI'),
              value: 'minimal',
              groupValue: _selectedMode,
              onChanged: (value) => setState(() => _selectedMode = value!),
            ),
            RadioListTile<String>(
              title: const Text('中等集成'),
              subtitle: const Text('添加交互记录和基础优化'),
              value: 'moderate',
              groupValue: _selectedMode,
              onChanged: (value) => setState(() => _selectedMode = value!),
            ),
            RadioListTile<String>(
              title: const Text('完整集成'),
              subtitle: const Text('启用所有UX功能和界面增强'),
              value: 'full',
              groupValue: _selectedMode,
              onChanged: (value) => setState(() => _selectedMode = value!),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建模式说明
  Widget _buildModeInstructions() {
    String title;
    List<String> instructions;
    List<String> features;

    switch (_selectedMode) {
      case 'minimal':
        title = '最小集成步骤';
        instructions = [
          '1. 在 main.dart 中初始化UX服务',
          '2. 不修改现有UI组件',
          '3. 可选择性启用沉浸模式',
        ];
        features = [
          '✅ 基础服务初始化',
          '✅ 可选的沉浸模式',
          '✅ 无UI改动',
          '❌ 自适应UI',
          '❌ 交互分析',
        ];
        break;

      case 'moderate':
        title = '中等集成步骤';
        instructions = [
          '1. 在关键操作点添加交互记录',
          '2. 在设置页面添加UX配置选项',
          '3. 显示基础的个性化推荐',
        ];
        features = [
          '✅ 基础服务初始化',
          '✅ 交互记录功能',
          '✅ UX设置页面',
          '✅ 基础推荐系统',
          '❌ 完整的自适应UI',
          '❌ 自动沉浸模式',
        ];
        break;

      case 'full':
        title = '完整集成步骤';
        instructions = [
          '1. 使用 UXEnhancedHomePage 替换现有首页',
          '2. 在应用中添加UX设置入口',
          '3. 启用所有个性化功能',
          '4. 配置自动优化选项',
        ];
        features = [
          '✅ 完整的服务初始化',
          '✅ 自适应UI系统',
          '✅ 沉浸模式集成',
          '✅ 交互分析功能',
          '✅ 个性化推荐',
          '✅ 自动优化',
        ];
        break;

      default:
        title = '未知模式';
        instructions = [];
        features = [];
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...instructions.map((instruction) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(instruction, style: const TextStyle(fontSize: 14)),
            )),
            const SizedBox(height: 16),
            const Text('功能支持：', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(feature, style: const TextStyle(fontSize: 14)),
            )),
          ],
        ),
      ),
    );
  }

  /// 构建代码示例
  Widget _buildCodeExample() {
    String codeExample;

    switch (_selectedMode) {
      case 'minimal':
        codeExample = '''
// 在 main.dart 中初始化
import 'package:flutter/material.dart';
import 'services/ux/ux_service_integration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化UX服务（不阻塞启动）
  UXServiceIntegration.initialize().catchError((e) {
    debugPrint('UX服务初始化失败: \$e');
  });

  runApp(MyApp());
}

// 现有应用保持不变
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ExistingHomePage(), // 使用现有页面
    );
  }
}
''';
        break;

      case 'moderate':
        codeExample = '''
// 1. 在现有操作中添加交互记录
import 'services/ux/ux_service_integration.dart';

class ExistingHomePage extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    // 记录页面访问
    UXServiceIntegration.trackUserBehavior('page_visit', {
      'page': 'home',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          // 2. 添加沉浸模式按钮
          IconButton(
            icon: Icon(Icons.center_focus_strong),
            onPressed: () async {
              await UXServiceIntegration.immersiveMode.activate();
            },
          ),
          // 3. 添加设置入口
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UXSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: ExistingContent(),
    );
  }
}

// 4. 在关键操作中记录交互
Future<void> saveNote() async {
  // 原有保存逻辑
  await noteRepository.save(note);

  // 记录交互
  await UXServiceIntegration.trackUserBehavior('note_saved', {
    'word_count': note.content.length,
    'has_title': note.title.isNotEmpty,
  });
}
''';
        break;

      case 'full':
        codeExample = '''
// 1. 使用UX增强版页面
import 'pages/ux_enhanced_home_page.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _getAdaptiveTheme(), // 使用自适应主题
      home: UXEnhancedHomePage(), // 替换为UX增强版
    );
  }

  // 2. 获取自适应主题
  ThemeData _getAdaptiveTheme() {
    final baseTheme = ThemeData(useMaterial3: true);
    final uiManager = AdaptiveUIManager.instance;
    return uiManager.getAdaptiveTheme(baseTheme);
  }
}

// 3. 在应用状态中集成UX服务
class AppState extends ChangeNotifier {
  final UXServiceProvider uxService;

  AppState(this.uxService);

  static Future<AppState> create() async {
    final uxService = await UXServiceProvider.create();
    return AppState(uxService);
  }

  // 现有方法...
  void createNewNote() {
    // 原有逻辑
    notes.add(newNote);

    // 记录交互
    uxService.trackBehavior('note_created', {
      'total_notes': notes.length,
    });

    notifyListeners();
  }
}

// 4. 在main函数中初始化
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化UX服务
  await UXServiceIntegration.initialize();

  final appState = await AppState.create();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: MyApp(),
    ),
  );
}
''';
        break;

      default:
        codeExample = '// 选择一个集成模式查看代码示例';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '代码示例',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                codeExample,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建测试部分
  Widget _buildTestingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '测试UX功能',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.science),
              label: const Text('启动功能演示'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UXFeaturesDemo(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.analytics),
              label: const Text('查看服务状态'),
              onPressed: () => _showServiceStatus(),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('重置所有UX数据'),
              onPressed: () => _confirmResetData(),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示服务状态
  void _showServiceStatus() {
    final status = UXServiceIntegration.getStatusSummary();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('UX服务状态'),
        content: SingleChildScrollView(
          child: Text(
            const JsonEncoder.withIndent('  ').convert(status),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 确认重置数据
  void _confirmResetData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('这将清除所有用户习惯和交互历史数据，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await UXServiceIntegration.clearAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据已重置')),
              );
            },
            child: const Text('确认重置', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 功能演示组件（简化版）
class UXFeaturesDemo extends StatelessWidget {
  const UXFeaturesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UX功能演示'),
      ),
      body: const Center(
        child: Text('完整演示请参考 lib/widgets/ux_features_demo.dart'),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:museflow/features/editor/editor.dart';
import 'package:museflow/features/editor/editor_config.dart';

/// MuseFlow 编辑器示例应用
/// 演示编辑器模块的各种功能和用法

void main() {
  // 确保Flutter绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const MuseFlowExampleApp());
}

class MuseFlowExampleApp extends StatelessWidget {
  const MuseFlowExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuseFlow Editor Example',
      debugShowCheckedModeBanner: false,

      // 主题配置
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,

        // 编辑器主题
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.6,
            letterSpacing: 0.5,
          ),
        ),
      ),

      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      themeMode: ThemeMode.system,

      // 路由配置
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/editor': (context) => const EditorExampleScreen(),
        '/config': (context) => const ConfigExampleScreen(),
        '/advanced': (context) => const AdvancedExampleScreen(),
      },
    );
  }
}

/// 主屏幕 - 应用入口
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MuseFlow Editor Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '编辑器示例',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 基础编辑器
          _buildExampleCard(
            context,
            title: '基础编辑器',
            description: '展示编辑器的基本功能和UI',
            icon: Icons.edit_note,
            route: '/editor',
          ),

          const SizedBox(height: 12),

          // 配置示例
          _buildExampleCard(
            context,
            title: '配置示例',
            description: '演示如何自定义编辑器配置',
            icon: Icons.settings,
            route: '/config',
          ),

          const SizedBox(height: 12),

          // 高级功能
          _buildExampleCard(
            context,
            title: '高级功能',
            description: '展示AI集成和数据持久化',
            icon: Icons.psychology,
            route: '/advanced',
          ),

          const SizedBox(height: 24),

          // 功能介绍
          const Text(
            '核心功能',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildFeatureItem(
            '思维碎片',
            '快速记录想法，子弹笔记模式',
            Icons.lightbulb,
          ),
          _buildFeatureItem(
            'AI润色',
            '智能文本润色，改善表达',
            Icons.auto_fix_high,
          ),
          _buildFeatureItem(
            'AI扩写',
            '扩展内容，丰富表达',
            Icons.expand,
          ),
          _buildFeatureItem(
            '格式清洗',
            '一键清除Markdown残留',
            Icons.cleaning_services,
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String route,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
    );
  }
}

/// 基础编辑器示例
class EditorExampleScreen extends StatelessWidget {
  const EditorExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基础编辑器'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const EditorScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('编辑器已准备就绪！'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: const Icon(Icons.info),
      ),
    );
  }
}

/// 配置示例屏幕
class ConfigExampleScreen extends StatefulWidget {
  const ConfigExampleScreen({super.key});

  @override
  State<ConfigExampleScreen> createState() => _ConfigExampleScreenState();
}

class _ConfigExampleScreenState extends State<ConfigExampleScreen> {
  EditorThemeConfig _themeConfig = EditorThemeConfig.defaultTheme;
  EditorBehaviorConfig _behaviorConfig = EditorBehaviorConfig.defaultBehavior;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置示例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 主题配置
          const Text('主题配置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('暗色模式'),
            subtitle: const Text('切换暗色/亮色主题'),
            value: _themeConfig.isDark,
            onChanged: (value) {
              setState(() {
                _themeConfig = _themeConfig.copyWith(isDark: value);
              });
            },
          ),

          ListTile(
            title: const Text('字体大小'),
            subtitle: Text('${_themeConfig.fontSize}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      _themeConfig = _themeConfig.copyWith(
                        fontSize: (_themeConfig.fontSize - 2).clamp(12.0, 24.0),
                      );
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _themeConfig = _themeConfig.copyWith(
                        fontSize: (_themeConfig.fontSize + 2).clamp(12.0, 24.0),
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          // 行为配置
          const Text('行为配置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('自动保存'),
            subtitle: const Text('定期自动保存编辑内容'),
            value: _behaviorConfig.autoSave,
            onChanged: (value) {
              setState(() {
                _behaviorConfig = _behaviorConfig.copyWith(autoSave: value);
              });
            },
          ),

          SwitchListTile(
            title: const Text('拼写检查'),
            subtitle: const Text('启用拼写检查功能'),
            value: _behaviorConfig.enableSpellCheck,
            onChanged: (value) {
              setState(() {
                _behaviorConfig =
                    _behaviorConfig.copyWith(enableSpellCheck: value);
              });
            },
          ),

          const Divider(height: 32),

          // 配置预览
          const Text('当前配置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('主题: ${_themeConfig.isDark ? "暗色" : "亮色"}'),
                  Text('字体: ${_themeConfig.fontSize}'),
                  Text('行高: ${_themeConfig.lineHeight}'),
                  const SizedBox(height: 8),
                  Text('自动保存: ${_behaviorConfig.autoSave ? "开启" : "关闭"}'),
                  Text(
                      '拼写检查: ${_behaviorConfig.enableSpellCheck ? "开启" : "关闭"}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 高级功能示例
class AdvancedExampleScreen extends StatelessWidget {
  const AdvancedExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高级功能'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'AI集成',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '支持多种AI服务',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• OpenAI (GPT-4, GPT-3.5)'),
                  Text('• Anthropic Claude'),
                  Text('• DeepSeek'),
                  Text('• 本地模型 (Ollama)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '数据持久化',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '多种存储方案',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Hive 本地数据库'),
                  Text('• SQLite 关系数据库'),
                  Text('• 文件系统存储'),
                  Text('• 云端同步支持'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '扩展功能',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '丰富的扩展接口',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• 自定义AI服务'),
                  Text('• 扩展格式清洗规则'),
                  Text('• 自定义文本处理器'),
                  Text('• 插件系统支持'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.code),
            label: const Text('查看集成代码'),
            onPressed: () {
              // 打开集成文档
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请查看 INTEGRATION.md 文件'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

# MuseFlow 编辑器模块集成指南

## 模块概览

编辑器模块是 MuseFlow 应用的核心组件，提供完整的文本编辑和AI辅助写作功能。本指南帮助开发者将编辑器模块集成到现有应用中。

## 目录结构

```
lib/features/editor/
├── editor_screen.dart          # 主编辑器界面
├── text_controller.dart        # 扩展的文本控制器
├── ai_action_handler.dart      # AI操作处理器
├── format_cleaner.dart         # 格式清洗工具
├── editor_config.dart          # 配置管理
├── editor_test.dart            # 单元测试
├── editor.dart                 # 模块导出文件
├── README.md                   # 模块说明文档
├── USAGE_GUIDE.md             # 用户使用指南
└── INTEGRATION.md             # 本集成文档

lib/widgets/thought_fragment/
└── thought_fragment_widget.dart # 思维碎片组件
```

## 快速集成

### 1. 基础集成

```dart
import 'package:flutter/material.dart';
import 'package:museflow/features/editor/editor.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EditorScreen(),
    );
  }
}
```

### 2. 配置AI服务

```dart
import 'package:museflow/features/editor/editor_config.dart';
import 'package:museflow/features/editor/ai_action_handler.dart';

// 配置OpenAI服务
final aiConfig = AIServiceConfig(
  provider: 'openai',
  apiKey: 'your-api-key',
  model: 'gpt-4',
  temperature: 0.7,
);

// 创建AI处理器
final aiHandler = AIActionHandler(
  onResult: (action, result) {
    // 处理AI结果
    print('AI $action: $result');
  },
  onError: (error) {
    // 处理错误
    print('AI Error: $error');
  },
);
```

### 3. 自定义配置

```dart
import 'package:museflow/features/editor/editor_config.dart';

// 自定义编辑器行为
final behaviorConfig = EditorBehaviorConfig(
  autoSave: true,
  autoSaveInterval: 60,
  enableSpellCheck: true,
  enableAutoComplete: false,
);

// 自定义主题
final themeConfig = EditorThemeConfig(
  isDark: true,
  fontSize: 18.0,
  lineHeight: 1.8,
  fontFamily: 'CustomFont',
);
```

## 高级集成

### 1. 自定义AI服务

```dart
import 'package:museflow/features/editor/ai_action_handler.dart';

class CustomAIService implements AIService {
  @override
  Future<String> request({
    required String prompt,
    required String operation,
    Map<String, dynamic>? parameters,
  }) async {
    // 实现自定义AI调用逻辑
    final response = await yourCustomAPI(prompt);
    return response;
  }

  @override
  Stream<String> requestStream({
    required String prompt,
    required String operation,
    Map<String, dynamic>? parameters,
  }) async* {
    // 实现流式响应逻辑
    yield* yourCustomStreamAPI(prompt);
  }
}

// 使用自定义服务
final customService = CustomAIService();
final aiHandler = AIActionHandler(
  onResult: (action, result) {},
  onError: (error) {},
);
```

### 2. 扩展编辑器功能

```dart
import 'package:museflow/features/editor/text_controller.dart';

class ExtendedTextController extends EditorTextController {
  // 添加自定义功能
  void applyCustomFormat() {
    final selected = selectedText;
    if (selected.isNotEmpty) {
      final formatted = _yourCustomFormat(selected);
      replaceSelection(formatted);
    }
  }

  String _yourCustomFormat(String text) {
    // 实现自定义格式化逻辑
    return text.toUpperCase();
  }
}
```

### 3. 自定义格式清洗规则

```dart
import 'package:museflow/features/editor/format_cleaner.dart';

class CustomFormatCleaner extends FormatCleaner {
  @override
  String cleanMarkdown(String text) {
    // 调用基础清洗
    String cleaned = super.cleanMarkdown(text);

    // 添加自定义清洗规则
    cleaned = _applyCustomRules(cleaned);

    return cleaned;
  }

  String _applyCustomRules(String text) {
    // 实现自定义清洗逻辑
    return text.replaceAll('custom-pattern', 'replacement');
  }
}
```

### 4. 集成数据持久化

```dart
import 'package:museflow/widgets/thought_fragment/thought_fragment_widget.dart';

class FragmentPersistenceManager {
  final SharedPreferences _prefs;
  final String _key = 'thought_fragments';

  FragmentPersistenceManager(this._prefs);

  // 保存碎片
  Future<void> saveFragments(List<ThoughtFragmentData> fragments) async {
    final json = fragments.map((f) => jsonEncode(f)).toList();
    await _prefs.setStringList(_key, json);
  }

  // 加载碎片
  Future<List<ThoughtFragmentData>> loadFragments() async {
    final json = _prefs.getStringList(_key) ?? [];
    return json.map((j) => ThoughtFragmentData.fromJson(jsonDecode(j))).toList();
  }

  // 清除碎片
  Future<void> clearFragments() async {
    await _prefs.remove(_key);
  }
}
```

## 与其他模块集成

### 1. 与知识库模块集成

```dart
import 'package:museflow/features/editor/editor.dart';
import 'package:museflow/features/knowledge/knowledge.dart';

class IntegratedEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧编辑器
        Expanded(
          flex: 2,
          child: EditorScreen(
            onContentChange: (content) {
              // 将编辑内容保存到知识库
              KnowledgeService().saveContent(content);
            },
          ),
        ),
        // 右侧知识库
        Expanded(
          child: KnowledgeBrowser(
            onItemSelect: (item) {
              // 将知识库内容插入编辑器
              EditorController().insertText(item.content);
            },
          ),
        ),
      ],
    );
  }
}
```

### 2. 与AI服务层集成

```dart
import 'package:museflow/features/ai_service/ai_service.dart';
import 'package:museflow/features/editor/editor.dart';

class AIIntegratedEditor extends StatefulWidget {
  @override
  State<AIIntegratedEditor> createState() => _AIIntegratedEditorState();
}

class _AIIntegratedEditorState extends State<AIIntegratedEditor> {
  late AIService _aiService;
  late AIActionHandler _aiHandler;

  @override
  void initState() {
    super.initState();
    _aiService = AIService();
    _aiHandler = AIActionHandler(
      onResult: _handleAIResult,
      onError: _handleAIError,
    );
  }

  void _handleAIResult(String action, String result) {
    // 处理AI结果并更新UI
    setState(() {
      // 更新编辑器内容
    });
  }

  void _handleAIError(String error) {
    // 显示错误提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('AI错误: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EditorScreen(
      aiHandler: _aiHandler,
    );
  }
}
```

### 3. 与搜索模块集成

```dart
import 'package:museflow/features/search/search.dart';

class SearchableEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索栏
        SearchBar(
          onSearch: (query) {
            // 在编辑器内容中搜索
            final results = SearchService().searchInEditor(query);
            _highlightSearchResults(results);
          },
        ),
        // 编辑器
        Expanded(
          child: EditorScreen(),
        ),
      ],
    );
  }

  void _highlightSearchResults(List<SearchResult> results) {
    // 高亮显示搜索结果
  }
}
```

## 测试和调试

### 1. 运行测试

```bash
# 运行编辑器模块测试
flutter test test/features/editor/

# 运行特定测试
flutter test test/features/editor/editor_test.dart

# 生成测试覆盖率报告
flutter test --coverage test/features/editor/
```

### 2. 调试模式

```dart
import 'package:museflow/features/editor/editor_config.dart';

void main() {
  // 启用调试模式
  EditorConfig.enableDebugMode = true;
  EditorConfig.logAIRequests = true;
  EditorConfig.logUserActions = true;

  runApp(MyApp());
}
```

### 3. 性能监控

```dart
import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static void monitorEditor(EditorTextController controller) {
    controller.addListener(() {
      if (kDebugMode) {
        final textLength = controller.text.length;
        final selection = controller.selection;

        debugPrint('Text length: $textLength');
        debugPrint('Selection: ${selection.start}-${selection.end}');

        // 性能警告
        if (textLength > 50000) {
          debugPrint('Warning: Large text may impact performance');
        }
      }
    });
  }
}
```

## 部署建议

### 1. 性能优化

- **大文本处理**：对于超过50KB的文本，考虑分页或虚拟化
- **AI调用优化**：实现请求缓存和去重
- **内存管理**：定期清理历史记录和缓存

### 2. 用户体验

- **加载状态**：为AI操作显示加载指示器
- **错误处理**：提供友好的错误提示和恢复选项
- **离线支持**：实现离线编辑和同步功能

### 3. 安全考虑

- **API密钥保护**：不要在客户端硬编码API密钥
- **数据加密**：敏感内容应该加密存储
- **权限控制**：实现适当的访问控制

## 故障排除

### 常见问题

**Q: 编辑器在桌面端显示异常**
A: 检查窗口管理配置，确保正确设置了桌面端参数

**Q: AI调用失败**
A: 验证API密钥和服务配置，检查网络连接

**Q: 性能问题**
A: 检查文本大小，启用性能监控，考虑优化数据结构

### 获取帮助

- 查看模块README和USAGE_GUIDE
- 检查单元测试示例
- 参考集成示例代码

## 更新维护

### 版本兼容性

- Flutter 3.0+
- Dart 3.0+
- 支持的平台：Windows、Android、macOS、Linux

### 更新策略

- 遵循语义化版本控制
- 提供迁移指南
- 保持向后兼容性

---

**最后更新：2025年1月**
**版本：1.0.0**

# MuseFlow 核心编辑器模块

这是 MuseFlow 应用的核心功能模块，实现了完整的文本编辑和AI辅助写作功能。

## 功能特性

### 1. 思维碎片输入
- **子弹笔记模式**：支持快速记录想法和灵感
- **侧边栏管理**：所有碎片在侧边栏中统一管理
- **标签支持**：可为碎片添加标签进行分类
- **快速插入**：一键将碎片插入到主编辑区

### 2. 分段润色
- **AI文本润色**：选中文字后调用AI进行润色
- **上下文感知**：可设置前文作为参考，提高润色准确性
- **快捷键操作**：Ctrl+K 快速触发润色
- **状态反馈**：实时显示AI处理状态

### 3. AI辅助功能
- **文本扩写**：Ctrl+E 扩展选中文本内容
- **大纲生成**：Ctrl+O 自动生成内容大纲
- **摘要提取**：快速提取核心观点
- **风格转换**：支持多种写作风格转换

### 4. 格式清洗
- **一键清理**：清除Markdown格式残留
- **智能转换**：保留基本结构，清除冗余格式
- **预览功能**：显示将要执行的操作预览

### 5. 沉浸式UI
- **极简设计**：专注写作，减少干扰
- **响应式布局**：适配不同屏幕尺寸
- **主题支持**：支持亮色/暗色主题
- **可调节界面**：侧边栏可隐藏，编辑区可调整

## 核心组件

### EditorScreen
主编辑器界面，包含：
- 主编辑区：支持多行文本输入
- 侧边栏：思维碎片列表
- 工具栏：撤销/重做、格式清洗、上下文锚点
- AI操作栏：润色、扩写、大纲功能

### EditorTextController
扩展的文本控制器，提供：
- 撤销/重做功能
- 文本选择监听
- 段落操作
- 历史记录管理

### AIActionHandler
AI操作处理器，负责：
- 构建AI提示词
- 管理操作队列
- 处理异步调用
- 错误处理和重试

### FormatCleaner
格式清洗工具，支持：
- 清除Markdown残留
- 标准化空格和换行
- 转换标点符号
- 格式检测和预览

### ThoughtFragmentWidget
思维碎片组件，包含：
- 碎片显示卡片
- 添加/编辑对话框
- 列表视图
- 标签管理

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| Ctrl+K | AI润色选中文本 |
| Ctrl+E | AI扩写选中文本 |
| Ctrl+O | 生成内容大纲 |
| Ctrl+Z | 撤销 |
| Ctrl+Y | 重做 |

## 使用示例

```dart
import 'package:museflow/features/editor/editor.dart';

// 在应用中使用编辑器
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EditorScreen(),
    );
  }
}
```

## AI服务集成

编辑器模块支持多种AI服务：

1. **OpenAI** (GPT-4, GPT-3.5)
2. **Anthropic Claude** (Claude 3 Opus/Sonnet)
3. **DeepSeek**
4. **本地模型** (Ollama)

AI服务通过适配器模式集成，可灵活切换和扩展。

## 架构设计

```
lib/features/editor/
├── editor_screen.dart        # 主编辑器界面
├── text_controller.dart      # 文本控制器
├── ai_action_handler.dart    # AI操作处理器
├── format_cleaner.dart       # 格式清洗工具
└── editor.dart              # 模块导出文件
```

## 扩展开发

### 添加新的AI操作

1. 在 `AIActionHandler` 中添加新方法
2. 构建相应的提示词
3. 在 `EditorScreen` 中添加UI触发点

### 自定义格式清洗规则

1. 在 `FormatCleaner` 中添加新的 `_CleanRule`
2. 定义匹配模式和替换规则
3. 更新清洗逻辑

### 扩展思维碎片功能

1. 在 `ThoughtFragmentData` 中添加新字段
2. 更新相关UI组件
3. 实现数据持久化

## 注意事项

1. **输入法支持**：使用原生 TextField 确保输入法兼容性
2. **性能优化**：大文本处理时注意内存使用
3. **异步处理**：AI操作需要正确处理异步状态
4. **错误处理**：网络失败时提供友好的错误提示

## 未来计划

- [ ] 添加更多AI写作功能
- [ ] 实现协作编辑
- [ ] 支持多文档管理
- [ ] 添加版本控制
- [ ] 实现导出功能

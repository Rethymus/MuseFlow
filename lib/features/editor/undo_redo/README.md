# MuseFlow 撤销/重做系统

## 功能概述

MuseFlow的撤销/重做系统提供了完整的文本编辑历史管理功能，解决了P0问题#5中关于缺少基础撤销/重做功能的问题。

## 核心特性

### 1. 多级历史记录
- 支持50级历史记录（可配置）
- 内存优化管理（默认10MB限制）
- 自动清理旧记录

### 2. 智能动作管理
- 自动合并连续输入（500ms内的操作）
- 支持复合操作
- 反向撤销保证

### 3. 丰富的动作类型
- `TextInsertAction`: 文本插入
- `TextDeleteAction`: 文本删除
- `TextReplaceAction`: 文本替换
- `CompositeAction`: 复合操作
- `FormatAction`: 格式化操作

### 4. 用户界面
- 工具栏快捷按钮
- 历史记录面板
- 内存使用指示器
- 操作反馈提示

## 使用方法

### 基本使用

```dart
import 'package:museflow/features/editor/undo_redo/undo_redo.dart';

// 创建管理器
final manager = UndoRedoManager(
  maxHistoryLength: 50,
  maxMemoryUsage: 10 * 1024 * 1024,
  enableMerge: true,
);

// 执行动作
final action = TextInsertAction(
  position: 0,
  insertedText: 'Hello',
  onInsert: (text) => updateText(text),
  onRemove: () => removeText(),
);

manager.executeAction(action);

// 撤销
manager.undo();

// 重做
manager.redo();
```

### 快捷键

- `Ctrl+Z`: 撤销
- `Ctrl+Y` 或 `Ctrl+Shift+Z`: 重做

### 在编辑器中集成

```dart
class MyEditor extends StatefulWidget {
  @override
  State<MyEditor> createState() => _MyEditorState();
}

class _MyEditorState extends State<MyEditor> {
  late final EditorTextController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EditorTextController();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      child: TextField(
        controller: _controller,
        // 其他配置...
      ),
    );
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isControlPressed = HardwareKeyboard.instance.isControlPressed;

    if (!isControlPressed) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyZ:
        _controller.undo();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyY:
        _controller.redo();
        return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
```

## 架构设计

### 核心组件

#### 1. TextEditAction (抽象基类)
定义所有可撤销/重做操作的基本接口：
- `execute()`: 执行操作
- `undo()`: 撤销操作
- `description`: 操作描述
- `canMerge`: 是否可合并
- `merge()`: 合并操作

#### 2. UndoRedoManager (管理器)
管理历史记录栈和操作执行：
- `_undoStack`: 撤销栈
- `_redoStack`: 重做栈
- 内存管理
- 动作合并逻辑

#### 3. HistoryPanel (UI组件)
历史记录显示面板：
- 历史列表
- 内存指示器
- 快速跳转

### 内存优化策略

1. **动作大小限制**: 单个动作超过一定大小会被压缩
2. **LRU清理**: 内存超限时删除最旧的动作
3. **智能合并**: 连续的小动作会被合并
4. **压缩优化**: 可主动压缩历史记录

### 动作合并算法

```dart
bool get canMerge => true;

TextEditAction? merge(TextEditAction other) {
  // 只合并同类型动作
  if (other is! TextInsertAction) return null;

  // 检查时间间隔
  final timeDiff = other.timestamp.difference(timestamp).inMilliseconds;
  if (timeDiff > 500) return null;

  // 检查位置连续性
  if (position + insertedText.length != other.position) return null;

  // 合并动作
  return TextInsertAction(
    position: position,
    insertedText: insertedText + other.insertedText,
    // ...
  );
}
```

## 性能考虑

### 时间复杂度
- 执行操作: O(1)
- 撤销/重做: O(1)
- 历史记录查询: O(n)

### 空间复杂度
- 基本空间: O(n)，n为历史记录数量
- 最大空间: 由 `maxMemoryUsage` 参数控制

### 优化建议
1. 对于大量文本操作，使用批量操作
2. 定期调用 `compressHistory()` 压缩历史
3. 合理设置 `maxHistoryLength` 和 `maxMemoryUsage`

## 测试

系统包含完整的单元测试：

```dart
// 运行测试
flutter test test/undo_redo_test.dart
```

### 测试覆盖
- 基本撤销/重做功能
- 多级历史管理
- 动作合并
- 内存限制
- 复合操作
- 边界情况

## 配置选项

### UndoRedoManager配置
```dart
UndoRedoManager(
  maxHistoryLength: 50,      // 最大历史记录数
  maxMemoryUsage: 10 * 1024 * 1024,  // 最大内存使用(字节)
  enableMerge: true,          // 启用动作合并
)
```

### EditorConfig配置
```dart
class EditorConfig {
  static const int maxHistoryLength = 50;
  static const Map<String, String> defaultShortcuts = {
    'undo': 'Ctrl+Z',
    'redo': 'Ctrl+Y',
  };
}
```

## 扩展开发

### 自定义动作类型

```dart
class CustomAction extends TextEditAction {
  @override
  String get actionType => 'custom';

  @override
  String get description => '自定义操作';

  @override
  void execute() {
    // 执行逻辑
  }

  @override
  void undo() {
    // 撤销逻辑
  }
}
```

### 自定义合并策略

```dart
class SmartMergeAction extends TextEditAction {
  @override
  bool get canMerge => true;

  @override
  TextEditAction? merge(TextEditAction other) {
    // 自定义合并逻辑
    if (shouldMerge(other)) {
      return createMergedAction(other);
    }
    return null;
  }
}
```

## 常见问题

### Q: 如何清空历史记录？
```dart
controller.clearHistory();
// 或
manager.clear();
```

### Q: 如何批量操作？
```dart
manager.beginBatch();
// 执行多个操作
manager.executeAction(action1);
manager.executeAction(action2);
manager.endBatch();
```

### Q: 如何压缩历史？
```dart
manager.compressHistory();
```

### Q: 如何获取历史统计？
```dart
final items = manager.historyItems;
final memoryKB = manager.memoryUsageKB;
final percent = manager.memoryUsagePercent;
```

## 相关文件

- `/lib/features/editor/undo_redo/text_edit_action.dart`: 动作定义
- `/lib/features/editor/undo_redo/undo_redo_manager.dart`: 管理器实现
- `/lib/features/editor/undo_redo/history_panel.dart`: UI组件
- `/lib/features/editor/text_controller.dart`: 集成到编辑器
- `/lib/features/editor/editor_screen.dart`: 界面集成

## 未来改进

1. 支持历史记录持久化
2. 支持历史记录导出/导入
3. 支持历史记录搜索
4. 支持历史记录分支
5. 支持协作编辑中的冲突解决

## 技术栈

- Flutter/Dart
- StatefulWidget状态管理
- 自定义文本控制器
- 键盘事件处理
- 内存优化算法
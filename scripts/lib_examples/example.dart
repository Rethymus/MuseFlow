import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../undo_redo/undo_redo.dart';
import '../text_controller.dart';

/// 撤销/重做功能示例
///
/// 演示如何在编辑器中使用撤销/重做功能
class UndoRedoExample extends StatefulWidget {
  const UndoRedoExample({super.key});

  @override
  State<UndoRedoExample> createState() => _UndoRedoExampleState();
}

class _UndoRedoExampleState extends State<UndoRedoExample> {
  late final EditorTextController _controller;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _controller = EditorTextController(
      text: '''欢迎使用 MuseFlow 编辑器！

这是一个支持撤销/重做功能的文本编辑器。

快捷键：
- Ctrl+Z: 撤销
- Ctrl+Y: 重做
- Ctrl+Shift+Z: 重做

试着输入一些文字，然后使用快捷键来撤销和重做！''',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleUndo() {
    if (_controller.canUndo) {
      _controller.undo();
      _showFeedback('撤销: ${_controller.undoRedoManager.undoDescription}');
    }
  }

  void _handleRedo() {
    if (_controller.canRedo) {
      _controller.redo();
      _showFeedback('重做: ${_controller.undoRedoManager.redoDescription}');
    }
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isControlPressed = HardwareKeyboard.instance.isControlPressed;

    if (!isControlPressed) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyZ:
        if (HardwareKeyboard.instance.isShiftPressed) {
          _handleRedo();
        } else {
          _handleUndo();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyY:
        _handleRedo();
        return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('撤销/重做示例'),
        actions: [
          AnimatedBuilder(
            animation: _controller.undoRedoManager,
            builder: (context, child) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: _controller.canUndo ? _handleUndo : null,
                    tooltip: '撤销 (Ctrl+Z)',
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo),
                    onPressed: _controller.canRedo ? _handleRedo : null,
                    tooltip: '重做 (Ctrl+Y)',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.history,
                      color: _showHistory ? Colors.blue : null,
                    ),
                    onPressed: () {
                      setState(() => _showHistory = !_showHistory);
                    },
                    tooltip: '查看历史',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Focus(
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '开始输入...',
                ),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),
            if (_showHistory)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: HistoryPanel(
                  undoRedoManager: _controller.undoRedoManager,
                  onClose: () => setState(() => _showHistory = false),
                  onClear: () => _controller.clearHistory(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 简单的撤销/重做演示
class SimpleUndoRedoDemo extends StatefulWidget {
  const SimpleUndoRedoDemo({super.key});

  @override
  State<SimpleUndoRedoDemo> createState() => _SimpleUndoRedoDemoState();
}

class _SimpleUndoRedoDemoState extends State<SimpleUndoRedoDemo> {
  final UndoRedoManager _manager = UndoRedoManager();
  final List<String> _items = [];
  String _status = '准备就绪';

  void _addItem() {
    final item = '项目 ${_items.length + 1}';
    final action = BasicTextEditAction(
      actionType: 'add',
      description: '添加 $item',
      onExecute: () {
        setState(() {
          _items.add(item);
          _status = '已添加: $item';
        });
      },
      onUndo: () {
        setState(() {
          _items.removeLast();
          _status = '已撤销: $item';
        });
      },
    );

    _manager.executeAction(action);
  }

  void _undo() {
    if (_manager.canUndo) {
      _manager.undo();
      _status = '撤销操作: ${_manager.undoDescription}';
    } else {
      _status = '没有可撤销的操作';
    }
    setState(() {});
  }

  void _redo() {
    if (_manager.canRedo) {
      _manager.redo();
      _status = '重做操作: ${_manager.redoDescription}';
    } else {
      _status = '没有可重做的操作';
    }
    setState(() {});
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('简单撤销/重做演示'),
      ),
      body: Column(
        children: [
          // 状态栏
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Text(
              _status,
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // 控制按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _addItem,
                  child: const Text('添加项目'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _manager.canUndo ? _undo : null,
                  child: const Text('撤销'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _manager.canRedo ? _redo : null,
                  child: const Text('重做'),
                ),
              ],
            ),
          ),

          // 项目列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(_items[index]),
                );
              },
            ),
          ),

          // 历史信息
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('可撤销: ${_manager.canUndo ? "是" : "否"}'),
                Text('可重做: ${_manager.canRedo ? "是" : "否"}'),
                Text('历史记录数: ${_manager.historyItems.length}'),
                Text('内存使用: ${_manager.memoryUsageKB} KB'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 运行示例
void main() {
  runApp(const MaterialApp(
    home: UndoRedoExample(),
  ));
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'text_controller.dart';
import 'ai_action_handler.dart';
import 'format_cleaner.dart';
import 'undo_redo/undo_redo.dart';
import 'intent_confirmation_dialog.dart';
import '../../widgets/thought_fragment/thought_fragment_widget.dart'
    as widget_show;
import '../../widgets/context_anchor_indicator.dart';
import '../../models/intent_confirmation.dart';
import '../../config/app_constants.dart';

/// 主编辑器界面 - MuseFlow的核心功能
/// 实现思维碎片输入、分段润色、上下文锚点等功能
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // 核心控制器
  late final EditorTextController _textController;
  late final AIActionHandler _aiHandler;
  late final FormatCleaner _formatCleaner;

  // UI状态
  final List<widget_show.ThoughtFragmentData> _fragments = [];
  final ValueNotifier<String> _selectedText = ValueNotifier('');
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);
  final ValueNotifier<String> _contextAnchor = ValueNotifier('');

  // 布局控制
  bool _showSidebar = true;
  bool _showHistory = false;
  double _sidebarWidth = 280;

  // 意图确认配置
  bool _enableIntentConfirmation = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupKeyboardHandlers();
  }

  void _initializeControllers() {
    _textController = EditorTextController();
    _formatCleaner = FormatCleaner();
    _aiHandler = AIActionHandler(
      onResult: _handleAIResult,
      onError: _handleAIError,
      onIntentConfirmation: _showIntentConfirmationDialog,
      enableIntentConfirmation: _enableIntentConfirmation,
    );
  }

  void _setupKeyboardHandlers() {
    // 快捷键监听将在 _handleKeyEvent 中实现
  }

  @override
  void dispose() {
    _textController.dispose();
    _aiHandler.dispose();
    _formatCleaner.dispose();
    _selectedText.dispose();
    _isProcessing.dispose();
    _contextAnchor.dispose();
    super.dispose();
  }

  // 处理AI操作结果
  void _handleAIResult(String action, String result) {
    setState(() {
      _isProcessing.value = false;

      switch (action) {
        case 'polish':
          _replaceSelectedText(result);
          break;
        case 'expand':
          _insertTextAtCursor(result);
          break;
        case 'outline':
          _showOutlineDialog(result);
          break;
      }
    });
  }

  // 处理AI操作错误
  void _handleAIError(String error) {
    setState(() {
      _isProcessing.value = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AI操作失败: $error'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '重试',
          onPressed: () => _retryLastAction(),
        ),
      ),
    );
  }

  // 显示意图确认对话框
  void _showIntentConfirmationDialog(IntentConfirmation intent) {
    setState(() {
      _isProcessing.value = false;
    });

    showDialog(
      context: context,
      builder: (context) => IntentConfirmationDialog(
        intent: intent,
        onConfirm: (confirmedIntent) {
          setState(() {
            _isProcessing.value = true;
          });
          _aiHandler.executeConfirmedIntent(confirmedIntent);
        },
        onCancel: () {
          _aiHandler.rejectIntent(intent);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI操作已取消'),
              behavior: SnackBarBehavior.floating,
              duration: AppConstants.slowAnimationDuration,
            ),
          );
        },
      ),
    );
  }

  // 替换选中的文本
  void _replaceSelectedText(String newText) {
    final selection = _textController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final text = _textController.value.text;
      final before = text.substring(0, selection.start);
      final after = text.substring(selection.end);
      _textController.value = TextEditingValue(
        text: before + newText + after,
        selection:
            TextSelection.collapsed(offset: before.length + newText.length),
      );
    }
  }

  // 在光标位置插入文本
  void _insertTextAtCursor(String text) {
    final cursorPosition = _textController.selection.baseOffset;
    final currentText = _textController.value.text;
    final newText = currentText.substring(0, cursorPosition) +
        text +
        currentText.substring(cursorPosition);

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPosition + text.length),
    );
  }

  // 显示大纲对话框
  void _showOutlineDialog(String outline) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('内容大纲'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: outline.split('\n').length,
            itemBuilder: (context, index) {
              final lines = outline.split('\n');
              return ListTile(
                leading: Text('${index + 1}.'),
                title: Text(lines[index]),
              );
            },
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

  // 重试上一次操作
  void _retryLastAction() {
    // 实现重试逻辑
  }

  // 处理文本选择
  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause? cause) {
    if (selection.isValid && !selection.isCollapsed) {
      _selectedText.value = _textController.value.text.substring(
        selection.start,
        selection.end,
      );
    } else {
      _selectedText.value = '';
    }
  }

  // 添加思维碎片
  void _addFragment(String text, [List<String>? tags]) {
    if (text.trim().isEmpty) return;

    setState(() {
      _fragments.add(widget_show.ThoughtFragmentData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        createdAt: DateTime.now(),
        tags: tags ?? [],
      ));
    });

    // 可选：将碎片插入到主编辑区
    if (_textController.value.text.isEmpty) {
      _textController.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Row(
          children: [
            // 侧边栏 - 思维碎片列表
            _buildSidebar(),

            // 主编辑区
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // 顶部工具栏
                      _buildToolbar(),

                      // 编辑区域
                      Expanded(
                        child: _buildEditorArea(),
                      ),

                      // 底部AI操作栏
                      _buildAIBar(),
                    ],
                  ),
                  // 历史记录面板
                  if (_showHistory)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: HistoryPanel(
                        undoRedoManager: _textController.undoRedoManager,
                        onClose: () => setState(() => _showHistory = false),
                        onClear: () => _textController.clearHistory(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建侧边栏
  Widget _buildSidebar() {
    if (!_showSidebar) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      width: _sidebarWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 侧边栏头部
          _buildSidebarHeader(),

          // 思维碎片列表
          Expanded(
            child: _fragments.isEmpty
                ? _buildEmptyFragmentsState()
                : _buildFragmentsList(),
          ),
        ],
      ),
    );
  }

  // 侧边栏头部
  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, size: 20),
          const SizedBox(width: 8),
          const Text(
            '思维碎片',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () => _showAddFragmentDialog(),
            tooltip: '添加碎片',
          ),
        ],
      ),
    );
  }

  // 空状态
  Widget _buildEmptyFragmentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无思维碎片',
            style: TextStyle(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('添加碎片'),
            onPressed: () => _showAddFragmentDialog(),
          ),
        ],
      ),
    );
  }

  // 碎片列表
  Widget _buildFragmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _fragments.length,
      itemBuilder: (context, index) {
        final fragment = _fragments[index];
        return widget_show.ThoughtFragmentWidget(
          fragment: fragment,
          onTap: () => _insertFragmentAtCursor(fragment.content),
          onDelete: () => _deleteFragment(index),
        );
      },
    );
  }

  // 显示添加碎片对话框
  void _showAddFragmentDialog() {
    showDialog(
      context: context,
      builder: (context) => widget_show.ThoughtFragmentDialog(
        onAdd: (content, tags) => _addFragment(content, tags),
      ),
    );
  }

  // 在光标处插入碎片
  void _insertFragmentAtCursor(String content) {
    _insertTextAtCursor('\n$content\n');
  }

  // 删除碎片
  void _deleteFragment(int index) {
    setState(() {
      _fragments.removeAt(index);
    });
  }

  // 构建工具栏
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // 侧边栏切换
          IconButton(
            icon: Icon(_showSidebar ? Icons.menu_open : Icons.menu),
            onPressed: () => setState(() => _showSidebar = !_showSidebar),
            tooltip: '切换侧边栏',
          ),

          const SizedBox(width: 8),

          // 撤销/重做
          AnimatedBuilder(
            animation: _textController.undoRedoManager,
            builder: (context, child) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: _textController.canUndo ? _handleUndo : null,
                    tooltip: '撤销 (Ctrl+Z)',
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo),
                    onPressed: _textController.canRedo ? _handleRedo : null,
                    tooltip: '重做 (Ctrl+Y)',
                  ),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () =>
                        setState(() => _showHistory = !_showHistory),
                    tooltip: '查看历史',
                    color: _showHistory
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ],
              );
            },
          ),

          const Spacer(),

          // 格式清洗按钮
          TextButton.icon(
            icon: const Icon(Icons.cleaning_services),
            label: const Text('格式清洗'),
            onPressed: _cleanFormatting,
          ),

          const SizedBox(width: 8),

          // 上下文锚点
          ValueListenableBuilder<String>(
            valueListenable: _contextAnchor,
            builder: (context, anchor, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: anchor.isNotEmpty
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: IconButton(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        anchor.isEmpty ? Icons.bookmark_border : Icons.bookmark,
                        color: anchor.isNotEmpty ? Colors.blue.shade700 : null,
                      ),
                      if (anchor.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '已设置',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onPressed: _setContextAnchor,
                  tooltip: anchor.isEmpty ? '设置上下文锚点' : '编辑上下文锚点',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 处理撤销
  void _handleUndo() {
    if (_textController.canUndo) {
      _textController.undo();
      _showUndoRedoFeedback(
          '撤销', _textController.undoRedoManager.undoDescription);
    } else {
      _showNoMoreActionsFeedback('撤销');
    }
  }

  // 处理重做
  void _handleRedo() {
    if (_textController.canRedo) {
      _textController.redo();
      _showUndoRedoFeedback(
          '重做', _textController.undoRedoManager.redoDescription);
    } else {
      _showNoMoreActionsFeedback('重做');
    }
  }

  // 显示撤销/重做反馈
  void _showUndoRedoFeedback(String action, String description) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action: $description'),
        behavior: SnackBarBehavior.floating,
        duration: AppConstants.slowAnimationDuration,
      ),
    );
  }

  // 显示没有更多操作的反馈
  void _showNoMoreActionsFeedback(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('没有可$action的操作'),
        behavior: SnackBarBehavior.floating,
        duration: AppConstants.mediumAnimationDuration,
      ),
    );
  }

  // 格式清洗
  void _cleanFormatting() {
    final currentText = _textController.value.text;
    final cleaned = _formatCleaner.cleanMarkdown(currentText);

    if (cleaned != currentText) {
      _textController.value = TextEditingValue(
        text: cleaned,
        selection: _textController.selection,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('格式已清洗'),
          behavior: SnackBarBehavior.floating,
          duration: AppConstants.extraLongDelay,
        ),
      );
    }
  }

  // 设置上下文锚点
  void _setContextAnchor() {
    final selectedText = _selectedText.value;
    final currentAnchor = _contextAnchor.value;

    showDialog(
      context: context,
      builder: (context) => ContextAnchorDialog(
        initialContent: selectedText.isNotEmpty ? selectedText : currentAnchor,
        onConfirm: (content) {
          if (content.isEmpty) {
            _contextAnchor.value = '';
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已清除上下文锚点'),
                behavior: SnackBarBehavior.floating,
                duration: AppConstants.slowAnimationDuration,
              ),
            );
          } else {
            _contextAnchor.value = content;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ 上下文锚点已设置'),
                backgroundColor: Colors.blue.shade700,
                behavior: SnackBarBehavior.floating,
                duration: AppConstants.extraSlowAnimationDuration,
                action: SnackBarAction(
                  label: '查看',
                  textColor: Colors.white,
                  onPressed: () => _showContextAnchorPreview(),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // 显示上下文锚点预览
  void _showContextAnchorPreview() {
    final anchor = _contextAnchor.value;
    if (anchor.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.anchor, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('上下文锚点内容'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    anchor,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.text_fields,
                        size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text('${anchor.length} 字符'),
                    const SizedBox(width: 16),
                    Icon(Icons.format_size,
                        size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                        '${anchor.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length} 词'),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('编辑'),
            onPressed: () {
              Navigator.pop(context);
              _setContextAnchor();
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('关闭'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // 构建主编辑区
  Widget _buildEditorArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: TextField(
        controller: _textController,
        focusNode: _textController.focusNode,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          hintText:
              '开始写作...\n\n支持快捷键:\nCtrl+K: AI润色\nCtrl+E: AI扩写\nCtrl+O: 生成大纲',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              fontSize: 16,
            ),
      ),
    );
  }

  // 构建AI操作栏
  Widget _buildAIBar() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isProcessing,
      builder: (context, isProcessing, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              // 处理状态指示器
              if (isProcessing) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                const Text('AI正在思考...'),
                const SizedBox(width: 24),
              ],

              // AI操作按钮
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAIActionButton(
                      icon: Icons.auto_fix_high,
                      label: '润色',
                      shortcut: 'Ctrl+K',
                      onPressed: isProcessing ? null : _polishSelection,
                    ),
                    const SizedBox(width: 16),
                    _buildAIActionButton(
                      icon: Icons.expand,
                      label: '扩写',
                      shortcut: 'Ctrl+E',
                      onPressed: isProcessing ? null : _expandSelection,
                    ),
                    const SizedBox(width: 16),
                    _buildAIActionButton(
                      icon: Icons.view_agenda,
                      label: '大纲',
                      shortcut: 'Ctrl+O',
                      onPressed: isProcessing ? null : _generateOutline,
                    ),
                  ],
                ),
              ),

              // 上下文锚点显示
              ValueListenableBuilder<String>(
                valueListenable: _contextAnchor,
                builder: (context, anchor, child) {
                  if (anchor.isEmpty) {
                    return ContextAnchorEmptyState(
                      onSetAnchor: _setContextAnchor,
                    );
                  }

                  return ContextAnchorIndicator(
                    anchorContent: anchor,
                    onClear: () => _contextAnchor.value = '',
                    onEdit: _setContextAnchor,
                    onTap: _showContextAnchorPreview,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建AI操作按钮
  Widget _buildAIActionButton({
    required IconData icon,
    required String label,
    required String shortcut,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  // AI润色
  void _polishSelection() {
    final selectedText = _selectedText.value;
    if (selectedText.isEmpty) {
      _showNoSelectionWarning();
      return;
    }

    setState(() {
      _isProcessing.value = true;
    });

    _aiHandler.polish(
      text: selectedText,
      context: _contextAnchor.value,
    );
  }

  // AI扩写
  void _expandSelection() {
    final selectedText = _selectedText.value;
    if (selectedText.isEmpty) {
      _showNoSelectionWarning();
      return;
    }

    setState(() {
      _isProcessing.value = true;
    });

    _aiHandler.expand(
      text: selectedText,
      context: _contextAnchor.value,
    );
  }

  // 生成大纲
  void _generateOutline() {
    final fullText = _textController.value.text;
    if (fullText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先输入一些文本'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing.value = true;
    });

    _aiHandler.outline(text: fullText);
  }

  // 显示未选择文本警告
  void _showNoSelectionWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('请先选择要处理的文本'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 处理键盘快捷键
  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // 检查是否按下了控制键
    final isControlPressed = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (!isControlPressed) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyZ:
        // Ctrl+Z 或 Shift+Ctrl+Z
        if (HardwareKeyboard.instance.isShiftPressed) {
          _handleRedo();
        } else {
          _handleUndo();
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.keyY:
        // Ctrl+Y 重做
        _handleRedo();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.keyK:
        _polishSelection();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.keyE:
        _expandSelection();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.keyO:
        _generateOutline();
        return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}

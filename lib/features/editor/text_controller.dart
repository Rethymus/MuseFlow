import 'package:flutter/material.dart';
import 'dart:math';
import 'undo_redo/undo_redo_manager.dart';
import 'undo_redo/text_edit_action.dart';

/// 自定义编辑器文本控制器
/// 扩展TextEditingController以支持编辑器特有功能
class EditorTextController extends TextEditingController {
  EditorTextController({super.text}) {
    _initializeUndoRedo();
  }

  // 撤销/重做管理器
  late final UndoRedoManager _undoRedoManager;
  bool _isProcessingChange = false;

  // 初始化撤销重做管理器
  void _initializeUndoRedo() {
    _undoRedoManager = UndoRedoManager(
      maxHistoryLength: 50,
      maxMemoryUsage: 10 * 1024 * 1024, // 10MB
      enableMerge: true,
    );
  }

  // 焦点节点
  final FocusNode focusNode = FocusNode();

  @override
  set value(TextEditingValue newValue) {
    // 检测文本变化并创建相应的动作
    if (!_isProcessingChange && value != newValue) {
      _createActionForChange(newValue);
    }

    super.value = newValue;
  }

  // 为文本变化创建动作
  void _createActionForChange(TextEditingValue newValue) {
    final oldValue = value;
    final oldText = oldValue.text;
    final newText = newValue.text;

    // 如果文本没有变化，只是光标移动，不创建动作
    if (oldText == newText) return;

    // 计算变化差异
    final diff = _computeTextDiff(
        oldText, newText, oldValue.selection, newValue.selection);

    if (diff == null) return;

    // 创建相应的动作
    TextEditAction? action;

    switch (diff.type) {
      case DiffType.insert:
        action = TextInsertAction(
          position: diff.position,
          insertedText: diff.text,
          onInsert: (text) {
            _isProcessingChange = true;
            final currentValue = value;
            final currentText = currentValue.text;
            final newText = currentText.substring(0, diff.position) +
                text +
                currentText.substring(diff.position);
            value = TextEditingValue(
              text: newText,
              selection:
                  TextSelection.collapsed(offset: diff.position + text.length),
            );
            _isProcessingChange = false;
          },
          onRemove: () {
            _isProcessingChange = true;
            final currentValue = value;
            final currentText = currentValue.text;
            final newText = currentText.substring(0, diff.position) +
                currentText.substring(diff.position + diff.text.length);
            value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: diff.position),
            );
            _isProcessingChange = false;
          },
        );
        break;

      case DiffType.delete:
        action = TextDeleteAction(
          position: diff.position,
          deletedText: diff.text,
          onRestore: (text) {
            _isProcessingChange = true;
            final currentValue = value;
            final currentText = currentValue.text;
            final newText = currentText.substring(0, diff.position) +
                text +
                currentText.substring(diff.position);
            value = TextEditingValue(
              text: newText,
              selection:
                  TextSelection.collapsed(offset: diff.position + text.length),
            );
            _isProcessingChange = false;
          },
          onDelete: () {
            _isProcessingChange = true;
            final currentValue = value;
            final currentText = currentValue.text;
            final newText = currentText.substring(0, diff.position) +
                currentText.substring(diff.position + diff.text.length);
            value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: diff.position),
            );
            _isProcessingChange = false;
          },
        );
        break;

      case DiffType.replace:
        action = TextReplaceAction(
          startPosition: diff.position,
          endPosition: diff.position + diff.text.length,
          oldText: diff.text,
          newText: newText.substring(
              diff.position,
              diff.position +
                  (newText.length - oldText.length + diff.text.length)),
          onReplace: (oldText, newText) {
            _isProcessingChange = true;
            final currentValue = this.value;
            final currentText = currentValue.text;
            final beforeText = currentText.substring(0, diff.position);
            final afterText =
                currentText.substring(diff.position + oldText.length);
            final resultText = beforeText + newText + afterText;
            this.value = TextEditingValue(
              text: resultText,
              selection: TextSelection.collapsed(
                  offset: diff.position + newText.length),
            );
            _isProcessingChange = false;
          },
        );
        break;
    }

    if (action != null) {
      _undoRedoManager.executeAction(action);
    }
  }

  // 计算文本差异
  _TextDiff? _computeTextDiff(String oldText, String newText,
      TextSelection oldSelection, TextSelection newSelection) {
    // 简单的文本差异计算
    if (oldText.length == newText.length) {
      // 可能是替换操作
      final position = _findFirstDifference(oldText, newText);
      if (position == -1) return null;

      int endPosition = _findLastDifference(oldText, newText);
      if (endPosition == -1) endPosition = oldText.length - 1;

      return _TextDiff(
        type: DiffType.replace,
        position: position,
        text: oldText.substring(position, endPosition + 1),
      );
    } else if (newText.length > oldText.length) {
      // 可能是插入操作
      final position = _findFirstDifference(oldText, newText);
      if (position == -1) return null;

      final insertedLength = newText.length - oldText.length;
      return _TextDiff(
        type: DiffType.insert,
        position: position,
        text: newText.substring(position, position + insertedLength),
      );
    } else {
      // 可能是删除操作
      final position = _findFirstDifference(oldText, newText);
      if (position == -1) return null;

      final deletedLength = oldText.length - newText.length;
      return _TextDiff(
        type: DiffType.delete,
        position: position,
        text: oldText.substring(position, position + deletedLength),
      );
    }
  }

  // 查找第一个不同的位置
  int _findFirstDifference(String text1, String text2) {
    final minLength = min(text1.length, text2.length);
    for (int i = 0; i < minLength; i++) {
      if (text1[i] != text2[i]) return i;
    }
    return minLength;
  }

  // 查找最后一个不同的位置
  int _findLastDifference(String text1, String text2) {
    final minLength = min(text1.length, text2.length);
    for (int i = minLength - 1; i >= 0; i--) {
      if (text1[i] != text2[i]) return i;
    }
    return -1;
  }

  /// 撤销操作
  void undo() {
    if (!_undoRedoManager.canUndo) return;
    _undoRedoManager.undo();
  }

  /// 重做操作
  void redo() {
    if (!_undoRedoManager.canRedo) return;
    _undoRedoManager.redo();
  }

  /// 是否可以撤销
  bool get canUndo => _undoRedoManager.canUndo;

  /// 是否可以重做
  bool get canRedo => _undoRedoManager.canRedo;

  /// 获取撤销/重做管理器
  UndoRedoManager get undoRedoManager => _undoRedoManager;

  /// 获取选中的文本
  String get selectedText {
    final selection = this.selection;
    if (!selection.isValid || selection.isCollapsed) {
      return '';
    }
    return text.substring(selection.start, selection.end);
  }

  /// 获取选中文本的前文（用于上下文锚点）
  String getTextBeforeSelection({int maxLength = 500}) {
    final selection = this.selection;
    if (!selection.isValid) return '';

    final startIndex = selection.start;
    if (startIndex <= 0) return '';

    final beforeText = text.substring(
      0,
      startIndex,
    );

    // 如果超过最大长度，截取最后部分
    if (beforeText.length > maxLength) {
      return beforeText.substring(beforeText.length - maxLength);
    }

    return beforeText;
  }

  /// 获取选中文本的后文
  String getTextAfterSelection({int maxLength = 500}) {
    final selection = this.selection;
    if (!selection.isValid) return '';

    final endIndex = selection.end;
    if (endIndex >= text.length) return '';

    final afterText = text.substring(endIndex);

    // 如果超过最大长度，截取前面部分
    if (afterText.length > maxLength) {
      return afterText.substring(0, maxLength);
    }

    return afterText;
  }

  /// 获取当前段落
  String getCurrentParagraph() {
    final selection = this.selection;
    if (!selection.isValid) return '';

    final text = this.text;
    final currentPos = selection.baseOffset;

    // 查找段落开始位置
    int paraStart = currentPos;
    while (paraStart > 0 && text[paraStart - 1] != '\n') {
      paraStart--;
    }

    // 查找段落结束位置
    int paraEnd = currentPos;
    while (paraEnd < text.length && text[paraEnd] != '\n') {
      paraEnd++;
    }

    return text.substring(paraStart, paraEnd);
  }

  /// 获取选中文本的完整段落
  String getSelectedParagraph() {
    final selection = this.selection;
    if (!selection.isValid) return '';

    final text = this.text;

    // 查找段落开始位置
    int paraStart = selection.start;
    while (paraStart > 0 && text[paraStart - 1] != '\n') {
      paraStart--;
    }

    // 查找段落结束位置
    int paraEnd = selection.end;
    while (paraEnd < text.length && text[paraEnd] != '\n') {
      paraEnd++;
    }

    return text.substring(paraStart, paraEnd);
  }

  /// 替换选中文本
  void replaceSelection(String newText) {
    final selection = this.selection;
    if (!selection.isValid || selection.isCollapsed) {
      return;
    }

    final text = this.text;
    final before = text.substring(0, selection.start);
    final after = text.substring(selection.end);

    value = TextEditingValue(
      text: before + newText + after,
      selection: TextSelection.collapsed(
        offset: before.length + newText.length,
      ),
    );
  }

  /// 在光标位置插入文本
  void insertAtCursor(String textToInsert) {
    final cursorPosition = selection.baseOffset;
    final currentText = text;

    final newText = currentText.substring(0, cursorPosition) +
        textToInsert +
        currentText.substring(cursorPosition);

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: cursorPosition + textToInsert.length,
      ),
    );
  }

  /// 获取选中文本的单词（如果选择的是单词的一部分）
  String expandToWord() {
    final selection = this.selection;
    if (!selection.isValid) return '';

    final text = this.text;

    // 如果已经是完整选择，直接返回
    if (!selection.isCollapsed) {
      return text.substring(selection.start, selection.end);
    }

    // 扩展到完整单词
    final position = selection.baseOffset;
    int wordStart = position;
    int wordEnd = position;

    // 向前查找单词开始
    while (wordStart > 0 && _isWordChar(text[wordStart - 1])) {
      wordStart--;
    }

    // 向后查找单词结束
    while (wordEnd < text.length && _isWordChar(text[wordEnd])) {
      wordEnd++;
    }

    // 更新选择范围
    this.value = TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: wordStart, extentOffset: wordEnd),
    );

    return text.substring(wordStart, wordEnd);
  }

  /// 判断是否是单词字符
  bool _isWordChar(String char) {
    return RegExp(r'\w').hasMatch(char);
  }

  /// 清空历史记录
  void clearHistory() {
    _undoRedoManager.clear();
  }

  /// 开始批量操作
  void beginBatchOperation() {
    _undoRedoManager.beginBatch();
  }

  /// 结束批量操作
  void endBatchOperation() {
    _undoRedoManager.endBatch();
  }

  @override
  void dispose() {
    focusNode.dispose();
    _undoRedoManager.dispose();
    super.dispose();
  }
}

// 文本差异类型
enum DiffType {
  insert,
  delete,
  replace,
}

// 文本差异信息
class _TextDiff {
  final DiffType type;
  final int position;
  final String text;

  _TextDiff({
    required this.type,
    required this.position,
    required this.text,
  });
}

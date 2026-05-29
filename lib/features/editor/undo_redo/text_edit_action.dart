import 'package:flutter/foundation.dart';

/// 文本编辑动作抽象类
/// 定义所有可撤销/重做的编辑操作的基本接口
abstract class TextEditAction {
  /// 动作类型标识
  String get actionType;

  /// 执行动作（用于重做）
  void execute();

  /// 撤销动作
  void undo();

  /// 动作描述（用于显示和历史记录）
  String get description;

  /// 动作是否可以合并（用于连续输入优化）
  bool get canMerge => false;

  /// 合并动作（用于连续输入优化）
  TextEditAction? merge(TextEditAction other) => null;

  /// 动作的时间戳
  final DateTime timestamp = DateTime.now();

  /// 动作的大小（用于内存管理）
  int get size => 0;
}

/// 基础文本编辑动作
class BasicTextEditAction extends TextEditAction {
  final String actionType;
  final String description;
  final VoidCallback onExecute;
  final VoidCallback onUndo;

  BasicTextEditAction({
    required this.actionType,
    required this.description,
    required this.onExecute,
    required this.onUndo,
  });

  @override
  void execute() => onExecute();

  @override
  void undo() => onUndo();

  @override
  int get size => description.length;
}

/// 文本插入动作
class TextInsertAction extends TextEditAction {
  final int position;
  final String insertedText;
  final Function(String) onInsert;
  final Function() onRemove;

  TextInsertAction({
    required this.position,
    required this.insertedText,
    required this.onInsert,
    required this.onRemove,
  });

  @override
  String get actionType => 'insert';

  @override
  String get description => '插入: "${insertedText.length > 20 ? insertedText.substring(0, 20) + '...' : insertedText}"';

  @override
  void execute() {
    onInsert(insertedText);
  }

  @override
  void undo() {
    onRemove();
  }

  @override
  bool get canMerge => true;

  @override
  TextEditAction? merge(TextEditAction other) {
    if (other is! TextInsertAction) return null;

    // 只合并连续的短文本插入（如连续打字）
    if (insertedText.length > 10 || other.insertedText.length > 10) return null;

    // 检查时间间隔（500ms内的合并）
    final timeDiff = other.timestamp.difference(timestamp).inMilliseconds;
    if (timeDiff > 500) return null;

    return TextInsertAction(
      position: position,
      insertedText: insertedText + other.insertedText,
      onInsert: onInsert,
      onRemove: onRemove,
    );
  }

  @override
  int get size => insertedText.length;
}

/// 文本删除动作
class TextDeleteAction extends TextEditAction {
  final int position;
  final String deletedText;
  final Function(String) onRestore;
  final Function() onDelete;

  TextDeleteAction({
    required this.position,
    required this.deletedText,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  String get actionType => 'delete';

  @override
  String get description => '删除: "${deletedText.length > 20 ? deletedText.substring(0, 20) + '...' : deletedText}"';

  @override
  void execute() {
    onDelete();
  }

  @override
  void undo() {
    onRestore(deletedText);
  }

  @override
  int get size => deletedText.length;
}

/// 文本替换动作
class TextReplaceAction extends TextEditAction {
  final int startPosition;
  final int endPosition;
  final String oldText;
  final String newText;
  final Function(String, String) onReplace;

  TextReplaceAction({
    required this.startPosition,
    required this.endPosition,
    required this.oldText,
    required this.newText,
    required this.onReplace,
  });

  @override
  String get actionType => 'replace';

  @override
  String get description {
    final oldPreview = oldText.length > 20 ? oldText.substring(0, 20) + '...' : oldText;
    final newPreview = newText.length > 20 ? newText.substring(0, 20) + '...' : newText;
    return '替换: "$oldPreview" -> "$newPreview"';
  }

  @override
  void execute() {
    onReplace(oldText, newText);
  }

  @override
  void undo() {
    onReplace(newText, oldText);
  }

  @override
  int get size => oldText.length + newText.length;
}

/// 复合动作（多个动作的组合）
class CompositeAction extends TextEditAction {
  final List<TextEditAction> actions;
  final String compositeDescription;

  CompositeAction({
    required this.actions,
    required this.compositeDescription,
  });

  @override
  String get actionType => 'composite';

  @override
  String get description => compositeDescription;

  @override
  void execute() {
    for (final action in actions) {
      action.execute();
    }
  }

  @override
  void undo() {
    // 反向撤销
    for (int i = actions.length - 1; i >= 0; i--) {
      actions[i].undo();
    }
  }

  @override
  int get size => actions.fold(0, (sum, action) => sum + action.size);
}

/// 格式化动作
class FormatAction extends TextEditAction {
  final String formatType;
  final String oldText;
  final String newText;
  final Function(String) onApply;

  FormatAction({
    required this.formatType,
    required this.oldText,
    required this.newText,
    required this.onApply,
  });

  @override
  String get actionType => 'format';

  @override
  String get description => '格式化: $formatType';

  @override
  void execute() {
    onApply(newText);
  }

  @override
  void undo() {
    onApply(oldText);
  }

  @override
  int get size => oldText.length + newText.length;
}
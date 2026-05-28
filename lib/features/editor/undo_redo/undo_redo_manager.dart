import '../utils/logger.dart';
import '../config/app_constants.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'text_edit_action.dart';

/// 撤销/重做管理器
/// 提供完整的撤销重做功能，支持历史记录管理和内存优化
class UndoRedoManager extends ChangeNotifier {
  // 历史记录栈
  final List<TextEditAction> _undoStack = [];
  final List<TextEditAction> _redoStack = [];

  // 配置
  final int maxHistoryLength;
  final int maxMemoryUsage;
  final bool enableMerge;

  // 当前内存使用量（字节）
  int _currentMemoryUsage = 0;

  // 是否正在执行撤销/重做操作
  bool _isExecutingAction = false;

  UndoRedoManager({
    this.maxHistoryLength = 50,
    this.maxMemoryUsage = 10 * 1024 * 1024, // 10MB
    this.enableMerge = true,
  });

  /// 执行动作并添加到历史记录
  void executeAction(TextEditAction action) {
    if (_isExecutingAction) return;

    try {
      // 执行动作
      action.execute();

      // 添加到撤销栈
      _addToUndoStack(action);

      // 清空重做栈
      _redoStack.clear();

      // 通知状态变化
      notifyListeners();
    } catch (e) {
      Logger.debug('执行动作失败: $e');
      rethrow;
    }
  }

  /// 添加动作到撤销栈
  void _addToUndoStack(TextEditAction action) {
    // 尝试合并动作（如果启用）
    if (enableMerge && _undoStack.isNotEmpty) {
      final lastAction = _undoStack.last;
      if (lastAction.canMerge) {
        final merged = lastAction.merge(action);
        if (merged != null) {
          // 替换最后一个动作
          final removedSize = lastAction.size;
          _undoStack[_undoStack.length - 1] = merged;
          _updateMemoryUsage(removedSize, merged.size);
          return;
        }
      }
    }

    // 添加新动作
    _undoStack.add(action);
    _currentMemoryUsage += action.size;

    // 限制历史记录长度
    _enforceLimits();
  }

  /// 撤销操作
  void undo() {
    if (_isExecutingAction) return;
    if (!canUndo) return;

    _isExecutingAction = true;
    TextEditAction? action;

    try {
      action = _undoStack.removeLast();
      _currentMemoryUsage -= action.size;

      action.undo();
      _redoStack.add(action);

      notifyListeners();
    } catch (e) {
      Logger.debug('撤销失败: $e');
      // 恢复动作到撤销栈
      if (action != null) {
        _undoStack.add(action);
        _currentMemoryUsage += action.size;
      }
      rethrow;
    } finally {
      _isExecutingAction = false;
    }
  }

  /// 重做操作
  void redo() {
    if (_isExecutingAction) return;
    if (!canRedo) return;

    _isExecutingAction = true;

    try {
      final action = _redoStack.removeLast();
      action.execute();

      _undoStack.add(action);
      _currentMemoryUsage += action.size;

      // 重新限制历史记录
      _enforceLimits();

      notifyListeners();
    } catch (e) {
      Logger.debug('重做失败: $e');
      rethrow;
    } finally {
      _isExecutingAction = false;
    }
  }

  /// 是否可以撤销
  bool get canUndo => _undoStack.isNotEmpty;

  /// 是否可以重做
  bool get canRedo => _redoStack.isNotEmpty;

  /// 获取撤销历史描述
  String get undoDescription {
    if (!canUndo) return '';
    return _undoStack.last.description;
  }

  /// 获取重做历史描述
  String get redoDescription {
    if (!canRedo) return '';
    return _redoStack.last.description;
  }

  /// 获取历史记录列表（用于显示历史面板）
  List<HistoryItem> get historyItems {
    final items = <HistoryItem>[];

    // 添加可撤销的项目
    for (int i = 0; i < _undoStack.length; i++) {
      items.add(HistoryItem(
        action: _undoStack[i],
        isCurrentState: i == _undoStack.length - 1,
        canReach: true,
      ));
    }

    return items;
  }

  /// 清空所有历史记录
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _currentMemoryUsage = 0;
    notifyListeners();
  }

  /// 限制历史记录长度和内存使用
  void _enforceLimits() {
    // 限制历史记录长度
    while (_undoStack.length > maxHistoryLength) {
      final removed = _undoStack.removeAt(0);
      _currentMemoryUsage -= removed.size;
    }

    // 限制内存使用
    while (_currentMemoryUsage > maxMemoryUsage && _undoStack.isNotEmpty) {
      final removed = _undoStack.removeAt(0);
      _currentMemoryUsage -= removed.size;
    }
  }

  /// 更新内存使用量
  void _updateMemoryUsage(int removedSize, int addedSize) {
    _currentMemoryUsage = _currentMemoryUsage - removedSize + addedSize;
  }

  /// 获取当前内存使用量（KB）
  int get memoryUsageKB => _currentMemoryUsage ~/ 1024;

  /// 获取内存使用百分比
  double get memoryUsagePercent => min(1.0, _currentMemoryUsage / maxMemoryUsage);

  /// 压缩历史记录（删除较老的、较大的动作）
  void compressHistory() {
    if (_undoStack.length <= maxHistoryLength ~/ 2) return;

    // 计算需要删除的数量
    final removeCount = (_undoStack.length * 0.3).ceil();

    // 找出最大的动作
    final sorted = List<TextEditAction>.from(_undoStack)
      ..sort((a, b) => b.size.compareTo(a.size));

    final toRemove = sorted.take(removeCount).toSet();

    // 删除大动作
    _undoStack.removeWhere((action) {
      if (toRemove.contains(action)) {
        _currentMemoryUsage -= action.size;
        return true;
      }
      return false;
    });

    notifyListeners();
  }

  /// 创建检查点（标记当前状态）
  String createCheckpoint() {
    final checkpointId = DateTime.now().millisecondsSinceEpoch.toString();
    return checkpointId;
  }

  /// 批量操作开始
  void beginBatch() {
    _isExecutingAction = true;
  }

  /// 批量操作结束
  void endBatch() {
    _isExecutingAction = false;
    notifyListeners();
  }

  /// 执行复合动作
  void executeComposite(String description, List<TextEditAction> actions) {
    if (actions.isEmpty) return;

    if (actions.length == 1) {
      executeAction(actions.first);
      return;
    }

    final composite = CompositeAction(
      actions: actions,
      compositeDescription: description,
    );

    executeAction(composite);
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}

/// 历史记录项
class HistoryItem {
  final TextEditAction action;
  final bool isCurrentState;
  final bool canReach;

  HistoryItem({
    required this.action,
    required this.isCurrentState,
    required this.canReach,
  });

  String get description => action.description;
  DateTime get timestamp => action.timestamp;
  String get actionType => action.actionType;
}

/// 历史记录统计信息
class HistoryStatistics {
  final int undoCount;
  final int redoCount;
  final int memoryUsageKB;
  final double memoryUsagePercent;
  final int totalActions;
  final List<ActionTypeCount> actionTypeCounts;

  HistoryStatistics({
    required this.undoCount,
    required this.redoCount,
    required this.memoryUsageKB,
    required this.memoryUsagePercent,
    required this.totalActions,
    required this.actionTypeCounts,
  });
}

/// 动作类型计数
class ActionTypeCount {
  final String actionType;
  final int count;

  ActionTypeCount({
    required this.actionType,
    required this.count,
  });
}
import 'package:flutter/material.dart';
import 'undo_redo_manager.dart';

/// 历史记录面板
/// 显示编辑历史并支持快速跳转
class HistoryPanel extends StatelessWidget {
  final UndoRedoManager undoRedoManager;
  final VoidCallback onClose;
  final VoidCallback onClear;

  const HistoryPanel({
    super.key,
    required this.undoRedoManager,
    required this.onClose,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: undoRedoManager,
      builder: (context, child) {
        return Container(
          width: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              left: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // 标题栏
              _buildHeader(context),
              // 内存使用指示器
              _buildMemoryIndicator(),
              // 历史记录列表
              Expanded(
                child: _buildHistoryList(context),
              ),
              // 底部操作栏
              _buildFooter(context),
            ],
          ),
        );
      },
    );
  }

  // 构建标题栏
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, size: 20),
          const SizedBox(width: 8),
          const Text(
            '编辑历史',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onClose,
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  // 构建内存指示器
  Widget _buildMemoryIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '内存使用',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${undoRedoManager.memoryUsageKB} KB',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: undoRedoManager.memoryUsagePercent,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              undoRedoManager.memoryUsagePercent > 0.8
                  ? Colors.red
                  : undoRedoManager.memoryUsagePercent > 0.5
                      ? Colors.orange
                      : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // 构建历史记录列表
  Widget _buildHistoryList(BuildContext context) {
    final historyItems = undoRedoManager.historyItems;

    if (historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无编辑历史',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: historyItems.length,
      reverse: true, // 最新的在上面
      itemBuilder: (context, index) {
        final item = historyItems[historyItems.length - 1 - index];
        return _buildHistoryItem(context, item, index);
      },
    );
  }

  // 构建历史记录项
  Widget _buildHistoryItem(BuildContext context, HistoryItem item, int index) {
    final isSelected = item.isCurrentState;
    final timeAgo = _formatTimeAgo(item.timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(_getActionIcon(item.actionType)),
        title: Text(
          item.description,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          timeAgo,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        dense: true,
        onTap: () {
          // TODO: 实现跳转到历史状态
        },
      ),
    );
  }

  // 获取动作图标
  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'insert':
        return Icons.add_circle_outline;
      case 'delete':
        return Icons.remove_circle_outline;
      case 'replace':
        return Icons.swap_horiz;
      case 'composite':
        return Icons.layers;
      case 'format':
        return Icons.format_paint;
      default:
        return Icons.edit;
    }
  }

  // 构建底部操作栏
  Widget _buildFooter(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () {
              _showClearConfirmation(context);
            },
            tooltip: '清空历史',
          ),
          const SizedBox(width: 8),
          Text(
            '清空历史',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            '共 ${undoRedoManager.historyItems.length} 条记录',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // 显示清空确认对话框
  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史记录'),
        content: const Text('确定要清空所有编辑历史吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onClear();
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  // 格式化时间显示
  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    } else {
      return '${difference.inDays} 天前';
    }
  }
}

/// 快速操作按钮栏
/// 提供撤销/重做/清空的快速操作
class QuickActionBar extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onShowHistory;
  final bool canUndo;
  final bool canRedo;

  const QuickActionBar({
    super.key,
    required this.onUndo,
    required this.onRedo,
    required this.onShowHistory,
    required this.canUndo,
    required this.canRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.undo, size: 18),
            onPressed: canUndo ? onUndo : null,
            tooltip: '撤销 (Ctrl+Z)',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.redo, size: 18),
            onPressed: canRedo ? onRedo : null,
            tooltip: '重做 (Ctrl+Y)',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.history, size: 18),
            onPressed: onShowHistory,
            tooltip: '查看历史',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
}

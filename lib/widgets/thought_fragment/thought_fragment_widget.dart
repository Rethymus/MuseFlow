import 'package:flutter/material.dart';

/// 思维碎片数据模型
class ThoughtFragmentData {
  final String id;
  final String content;
  final DateTime createdAt;
  final List<String> tags;

  ThoughtFragmentData({
    required this.id,
    required this.content,
    required this.createdAt,
    this.tags = const [],
  });

  ThoughtFragmentData copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return ThoughtFragmentData(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }
}

/// 思维碎片组件
/// 用于显示和管理思维碎片列表
class ThoughtFragmentWidget extends StatelessWidget {
  final ThoughtFragmentData fragment;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isSelected;

  const ThoughtFragmentWidget({
    super.key,
    required this.fragment,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onEdit,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部操作栏
              Row(
                children: [
                  // 创建时间
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(fragment.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  // 编辑按钮
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  // 删除按钮
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 16),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // 碎片内容
              Text(
                fragment.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                ),
              ),

              // 标签
              if (fragment.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: fragment.tags.take(3).map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(fontSize: 10),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 格式化时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }
}

/// 思维碎片添加对话框
class ThoughtFragmentDialog extends StatefulWidget {
  final Function(String content, List<String> tags) onAdd;

  const ThoughtFragmentDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<ThoughtFragmentDialog> createState() =>
      _ThoughtFragmentDialogState();
}

class _ThoughtFragmentDialogState extends State<ThoughtFragmentDialog> {
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('添加思维碎片'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 内容输入
            TextField(
              controller: _contentController,
              autofocus: true,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '输入你的想法...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // 标签输入
            TextField(
              controller: _tagController,
              decoration: InputDecoration(
                hintText: '添加标签（按回车确认）',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ),
              onSubmitted: (_) => _addTag(),
            ),

            // 已添加标签
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _handleAdd,
          child: const Text('添加'),
        ),
      ],
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _handleAdd() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入内容'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onAdd(content, _tags);
    Navigator.pop(context);
  }
}

/// 思维碎片编辑对话框
class ThoughtFragmentEditDialog extends StatefulWidget {
  final ThoughtFragmentData fragment;
  final Function(String content, List<String> tags) onUpdate;

  const ThoughtFragmentEditDialog({
    super.key,
    required this.fragment,
    required this.onUpdate,
  });

  @override
  State<ThoughtFragmentEditDialog> createState() =>
      _ThoughtFragmentEditDialogState();
}

class _ThoughtFragmentEditDialogState extends State<ThoughtFragmentEditDialog> {
  late final TextEditingController _contentController;
  late final List<String> _tags;
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.fragment.content);
    _tags = List.from(widget.fragment.tags);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑思维碎片'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 内容编辑
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '编辑内容...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // 标签管理
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: '添加标签',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ],
            ),

            // 已添加标签
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _handleUpdate,
          child: const Text('更新'),
        ),
      ],
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _handleUpdate() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('内容不能为空'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onUpdate(content, _tags);
    Navigator.pop(context);
  }
}

/// 思维碎片列表视图
class ThoughtFragmentListView extends StatelessWidget {
  final List<ThoughtFragmentData> fragments;
  final Function(String id) onTap;
  final Function(String id) onDelete;
  final Function(String id) onEdit;
  final String? selectedId;

  const ThoughtFragmentListView({
    super.key,
    required this.fragments,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    if (fragments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无思维碎片',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: fragments.length,
      itemBuilder: (context, index) {
        final fragment = fragments[index];
        return ThoughtFragmentWidget(
          fragment: fragment,
          isSelected: fragment.id == selectedId,
          onTap: () => onTap(fragment.id),
          onDelete: () => _showDeleteConfirm(context, fragment),
          onEdit: () => _showEditDialog(context, fragment),
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, ThoughtFragmentData fragment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除这个思维碎片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete(fragment.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ThoughtFragmentData fragment) {
    showDialog(
      context: context,
      builder: (context) => ThoughtFragmentEditDialog(
        fragment: fragment,
        onUpdate: (content, tags) {
          onEdit(fragment.id);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'context_anchor_indicator.dart';

/// 上下文锚点组件使用示例
///
/// 此文件展示了如何使用 ContextAnchorIndicator 组件及其相关功能
class ContextAnchorExample extends StatefulWidget {
  const ContextAnchorExample({super.key});

  @override
  State<ContextAnchorExample> createState() => _ContextAnchorExampleState();
}

class _ContextAnchorExampleState extends State<ContextAnchorExample> {
  final ValueNotifier<String> _contextAnchor = ValueNotifier('');
  final ValueNotifier<String> _selectedText = ValueNotifier('');

  @override
  void dispose() {
    _contextAnchor.dispose();
    _selectedText.dispose();
    super.dispose();
  }

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
                duration: Duration(milliseconds: 800),
              ),
            );
          } else {
            _contextAnchor.value = content;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ 上下文锚点已设置'),
                backgroundColor: Colors.blue.shade700,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(milliseconds: 1200),
              ),
            );
          }
        },
      ),
    );
  }

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
                    Icon(Icons.text_fields, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text('${anchor.length} 字符'),
                    const SizedBox(width: 16),
                    Icon(Icons.format_size, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text('${anchor.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length} 词'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('上下文锚点组件示例'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          // 工具栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
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
                              anchor.isEmpty ? Icons.anchor_outline : Icons.anchor,
                              color: anchor.isNotEmpty ? Colors.blue.shade700 : null,
                            ),
                            if (anchor.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          ),

          // 主要内容区
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 说明文本
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              '功能说明',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '此示例展示了上下文锚点组件的完整功能：\n'
                          '• 丰富的视觉反馈和动画效果\n'
                          '• 内容预览和统计信息\n'
                          '• 编辑、清除、查看等快捷操作\n'
                          '• 空状态提示和设置引导',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade900,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 上下文锚点显示区
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

                  const SizedBox(height: 24),

                  // 操作示例
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '快速操作示例',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('设置示例锚点'),
                              onPressed: () {
                                _contextAnchor.value = '这是一个示例上下文锚点内容。\n\nAI将基于此内容进行理解和回复，确保上下文的连贯性和准确性。';
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.clear),
                              label: const Text('清除锚点'),
                              onPressed: () => _contextAnchor.value = '',
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 使用示例入口
void runContextAnchorExample() {
  // 在应用中运行此示例：
  // Navigator.push(context, MaterialPageRoute(builder: (context) => const ContextAnchorExample()));
}
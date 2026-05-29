import 'package:flutter/material.dart';
import '../config/app_constants.dart';

/// 上下文锚点指示器组件
/// 提供清晰的视觉反馈和交互功能
class ContextAnchorIndicator extends StatefulWidget {
  final String anchorContent;
  final VoidCallback? onClear;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  final bool isExpanded;

  const ContextAnchorIndicator({
    super.key,
    required this.anchorContent,
    this.onClear,
    this.onEdit,
    this.onTap,
    this.isExpanded = false,
  });

  @override
  State<ContextAnchorIndicator> createState() => _ContextAnchorIndicatorState();
}

class _ContextAnchorIndicatorState extends State<ContextAnchorIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.mediumDelay,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ContextAnchorIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anchorContent != widget.anchorContent) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  List<String> _getContentPreview() {
    final lines = widget.anchorContent.split('\n');
    if (lines.length <= 2) return lines;
    return [lines[0], lines[1], '...'];
  }

  int _getCharacterCount() {
    return widget.anchorContent.length;
  }

  int _getWordCount() {
    return widget.anchorContent
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade50,
                        Colors.blue.shade100,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 头部：图标和操作按钮
                              Row(
                                children: [
                                  // 动画图标
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade400,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.anchor,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // 标题和状态
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '上下文锚点已设置',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                        Text(
                                          'AI将基于此内容进行理解',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 统计信息
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_getCharacterCount()}字符',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  // 操作按钮
                                  if (_isHovered || widget.isExpanded) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 16),
                                      onPressed: widget.onEdit,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      tooltip: '编辑锚点',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: widget.onClear,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      tooltip: '清除锚点',
                                    ),
                                  ] else ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: widget.onClear,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      tooltip: '清除锚点',
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 12),

                              // 内容预览
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 内容预览标题
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          size: 14,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '内容预览',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${_getWordCount()}词',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // 预览内容
                                    ..._getContentPreview()
                                        .map((line) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 4),
                                              child: Text(
                                                line,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.blue.shade900,
                                                  height: 1.4,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )),
                                  ],
                                ),
                              ),

                              // 提示信息
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '此上下文将用于AI操作的参考依据',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 上下文锚点设置对话框
class ContextAnchorDialog extends StatefulWidget {
  final String initialContent;
  final Function(String content) onConfirm;

  const ContextAnchorDialog({
    super.key,
    required this.initialContent,
    required this.onConfirm,
  });

  @override
  State<ContextAnchorDialog> createState() => _ContextAnchorDialogState();
}

class _ContextAnchorDialogState extends State<ContextAnchorDialog> {
  late final TextEditingController _controller;
  bool _isEmpty = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _controller.addListener(_validateInput);
  }

  void _validateInput() {
    setState(() {
      _isEmpty = _controller.text.trim().isEmpty;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.anchor,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          const Text('设置上下文锚点'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明文本
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '上下文锚点将为AI操作提供参考背景',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 内容输入框
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: '输入要作为上下文的文本内容...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
                ),
                filled: true,
                fillColor: Colors.blue.shade50,
                errorText: _isEmpty ? '内容不能为空' : null,
              ),
              autofocus: true,
            ),

            const SizedBox(height: 8),

            // 统计信息
            Row(
              children: [
                Icon(
                  Icons.text_fields,
                  size: 14,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_controller.text.length} 字符',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.format_size,
                  size: 14,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_controller.text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length} 词',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.clear),
          label: const Text('清除'),
          onPressed: () {
            widget.onConfirm('');
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red.shade700,
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.cancel),
          label: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('确认'),
          onPressed: _isEmpty ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _handleConfirm() {
    final content = _controller.text.trim();
    if (content.isNotEmpty) {
      widget.onConfirm(content);
      Navigator.pop(context);
    }
  }
}

/// 上下文锚点空状态组件
class ContextAnchorEmptyState extends StatelessWidget {
  final VoidCallback onSetAnchor;

  const ContextAnchorEmptyState({
    super.key,
    required this.onSetAnchor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onSetAnchor,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(
              Icons.anchor_outlined,
              size: 24,
              color: Colors.blue.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '未设置上下文锚点',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  Text(
                    '选择文本后点击工具栏中的锚点图标',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              size: 20,
              color: Colors.blue.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

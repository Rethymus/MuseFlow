import 'package:flutter/material.dart';
import '../../models/intent_confirmation.dart';

/// 意图确认对话框
/// 在执行AI操作前，显示AI对用户意图的理解，让用户确认或调整
class IntentConfirmationDialog extends StatefulWidget {
  final IntentConfirmation intent;
  final Function(IntentConfirmation) onConfirm;
  final Function() onCancel;

  const IntentConfirmationDialog({
    super.key,
    required this.intent,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<IntentConfirmationDialog> createState() =>
      _IntentConfirmationDialogState();
}

class _IntentConfirmationDialogState extends State<IntentConfirmationDialog> {
  late IntentConfirmation _currentIntent;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentIntent = widget.intent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.psychology_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('确认AI操作意图'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 操作类型和描述
            _buildActionSection(theme),

            const SizedBox(height: 16),

            // 原文预览
            _buildOriginalTextSection(theme),

            const SizedBox(height: 16),

            // 参数调整
            _buildParametersSection(theme),

            const SizedBox(height: 16),

            // AI解释
            _buildExplanationSection(theme),

            const SizedBox(height: 16),

            // 预期效果
            if (_currentIntent.expectedOutcome.isNotEmpty)
              _buildExpectedOutcomeSection(theme),
          ],
        ),
      ),
      actions: [
        // 取消按钮
        TextButton.icon(
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('取消'),
          onPressed: widget.onCancel,
        ),

        // 调整按钮
        TextButton.icon(
          icon: const Icon(Icons.tune_outlined),
          label: const Text('调整'),
          onPressed: _showAdjustmentDialog,
        ),

        // 确认按钮
        FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('确认执行'),
          onPressed: () => widget.onConfirm(_currentIntent),
        ),
      ],
    );
  }

  /// 构建操作类型和描述部分
  Widget _buildActionSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getActionIcon(),
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _getActionTitle(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentIntent.description,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// 构建原文预览部分
  Widget _buildOriginalTextSection(ThemeData theme) {
    final previewText = _currentIntent.originalText.length > 100
        ? '${_currentIntent.originalText.substring(0, 100)}...'
        : _currentIntent.originalText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.text_snippet_outlined, size: 16),
            const SizedBox(width: 8),
            Text(
              '原文内容',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Text(
            previewText,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  /// 构建参数调整部分
  Widget _buildParametersSection(ThemeData theme) {
    if (_currentIntent.parameters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tune_outlined, size: 16),
            const SizedBox(width: 8),
            Text(
              '操作参数',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._currentIntent.parameters.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(
                  '${entry.key}: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  entry.value.toString(),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// 构建AI解释部分
  Widget _buildExplanationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline, size: 16),
            const SizedBox(width: 8),
            Text(
              'AI理解说明',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _currentIntent.explanation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建预期效果部分
  Widget _buildExpectedOutcomeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.preview_outlined, size: 16),
            const SizedBox(width: 8),
            Text(
              '预期效果',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _currentIntent.expectedOutcome,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  /// 显示调整对话框
  void _showAdjustmentDialog() {
    showDialog(
      context: context,
      builder: (context) => _IntentAdjustmentDialog(
        intent: _currentIntent,
        onAdjust: (adjustedIntent) {
          setState(() {
            _currentIntent = adjustedIntent;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  /// 获取操作类型图标
  IconData _getActionIcon() {
    switch (_currentIntent.actionType) {
      case AIActionType.polish:
        return Icons.auto_fix_high;
      case AIActionType.expand:
        return Icons.expand;
      case AIActionType.outline:
        return Icons.view_agenda;
      case AIActionType.summarize:
        return Icons.short_text;
      case AIActionType.changeStyle:
        return Icons.style;
      case AIActionType.smartReplace:
        return Icons.find_replace;
      default:
        return Icons.psychology;
    }
  }

  /// 获取操作类型标题
  String _getActionTitle() {
    switch (_currentIntent.actionType) {
      case AIActionType.polish:
        return 'AI润色';
      case AIActionType.expand:
        return 'AI扩写';
      case AIActionType.outline:
        return '生成大纲';
      case AIActionType.summarize:
        return '摘要生成';
      case AIActionType.changeStyle:
        return '风格转换';
      case AIActionType.smartReplace:
        return '智能替换';
      default:
        return 'AI操作';
    }
  }
}

/// 意图调整对话框
class _IntentAdjustmentDialog extends StatefulWidget {
  final IntentConfirmation intent;
  final Function(IntentConfirmation) onAdjust;

  const _IntentAdjustmentDialog({
    required this.intent,
    required this.onAdjust,
  });

  @override
  State<_IntentAdjustmentDialog> createState() =>
      _IntentAdjustmentDialogState();
}

class _IntentAdjustmentDialogState extends State<_IntentAdjustmentDialog> {
  late TextEditingController _descriptionController;
  late Map<String, TextEditingController> _parameterControllers;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.intent.description);
    _parameterControllers = {};

    for (final entry in widget.intent.parameters.entries) {
      _parameterControllers[entry.key] = TextEditingController(
        text: entry.value.toString(),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    for (final controller in _parameterControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('调整AI操作意图'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 描述调整
            Text(
              '操作描述',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: '描述你希望AI如何处理这段文本',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // 参数调整
            ..._parameterControllers.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: entry.value,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _applyAdjustments,
          child: const Text('应用调整'),
        ),
      ],
    );
  }

  void _applyAdjustments() {
    final adjustedParameters = <String, dynamic>{};

    for (final entry in _parameterControllers.entries) {
      adjustedParameters[entry.key] = entry.value.text;
    }

    final adjustedIntent = widget.intent.copyWith(
      description: _descriptionController.text,
      parameters: adjustedParameters,
    );

    widget.onAdjust(adjustedIntent);
  }
}

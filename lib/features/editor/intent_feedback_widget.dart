import 'package:flutter/material.dart';
import '../models/intent_confirmation.dart';
import '../../config/app_constants.dart';

/// 意图反馈收集Widget
/// 在AI操作完成后，收集用户对意图理解的反馈
class IntentFeedbackWidget extends StatefulWidget {
  final String intentId;
  final String operationType;
  final Function(String feedback, int rating) onSubmit;

  const IntentFeedbackWidget({
    super.key,
    required this.intentId,
    required this.operationType,
    required this.onSubmit,
  });

  @override
  State<IntentFeedbackWidget> createState() => _IntentFeedbackWidgetState();
}

class _IntentFeedbackWidgetState extends State<IntentFeedbackWidget> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.feedback_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppConstants.smallSpacing),
              Text(
                'AI操作反馈',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.mediumSpacing),

          // 操作类型显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getOperationTypeLabel(widget.operationType),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),

          const SizedBox(height: AppConstants.standardSpacing),

          // 评分部分
          Text(
            '意图理解准确性',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          _buildRatingStars(theme),

          const SizedBox(height: AppConstants.standardSpacing),

          // 文本反馈部分
          Text(
            '详细反馈（可选）',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '请描述AI是否正确理解了您的意图...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.standardSpacing),

          // 提交按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _submitFeedback(false),
                  child: const Text('跳过'),
                ),
              ),
              const SizedBox(width: AppConstants.mediumSpacing),
              Expanded(
                child: FilledButton(
                  onPressed: _rating > 0 ? () => _submitFeedback(true) : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: AppConstants.mediumIconSize,
                          height: AppConstants.mediumIconSize,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('提交反馈'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建评分星星
  Widget _buildRatingStars(ThemeData theme) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          icon: Icon(
            starValue <= _rating ? Icons.star : Icons.star_border,
            color: starValue <= _rating
                ? Colors.amber
                : theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          onPressed: () {
            setState(() {
              _rating = starValue;
            });
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
        );
      }),
    );
  }

  /// 提交反馈
  void _submitFeedback(bool hasFeedback) {
    if (!hasFeedback) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final feedbackText = _feedbackController.text.trim();

    widget.onSubmit(
      feedbackText.isEmpty ? '无详细反馈' : feedbackText,
      _rating,
    );

    // 延迟关闭以显示提交状态
    Future.delayed(AppConstants.longDelay, () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('感谢您的反馈！'),
            behavior: SnackBarBehavior.floating,
            duration: AppConstants.extraLongDelay,
          ),
        );
      }
    });
  }

  /// 获取操作类型标签
  String _getOperationTypeLabel(String operationType) {
    switch (operationType) {
      case 'polish':
        return 'AI润色';
      case 'expand':
        return 'AI扩写';
      case 'outline':
        return '生成大纲';
      case 'summarize':
        return '摘要生成';
      case 'changeStyle':
        return '风格转换';
      case 'smartReplace':
        return '智能替换';
      default:
        return 'AI操作';
    }
  }
}

/// 意图反馈对话框
class IntentFeedbackDialog extends StatelessWidget {
  final String intentId;
  final String operationType;
  final Function(String feedback, int rating) onSubmit;

  const IntentFeedbackDialog({
    super.key,
    required this.intentId,
    required this.operationType,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI操作反馈'),
      content: SizedBox(
        width: AppConstants.defaultDialogWidth,
        child: IntentFeedbackWidget(
          intentId: intentId,
          operationType: operationType,
          onSubmit: onSubmit,
        ),
      ),
      actions: const [],
    );
  }
}

/// 意图历史统计Widget
class IntentStatisticsWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const IntentStatisticsWidget({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppConstants.smallSpacing),
              Text(
                '意图确认统计',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.standardSpacing),
          _buildStatItem('总操作数', '${statistics['total'] ?? 0}'),
          _buildStatItem('确认次数', '${statistics['confirmed'] ?? 0}'),
          _buildStatItem('调整次数', '${statistics['adjusted'] ?? 0}'),
          _buildStatItem('拒绝次数', '${statistics['rejected'] ?? 0}'),
          const SizedBox(height: 8),
          _buildStatItem(
            '确认率',
            '${((statistics['confirmation_rate'] as double?) * 100).toStringAsFixed(1)}%',
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}

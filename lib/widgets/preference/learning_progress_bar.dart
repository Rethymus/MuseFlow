import 'package:flutter/material.dart';

/// 学习进度条
/// 显示AI学习用户偏好的进度
class LearningProgressBar extends StatelessWidget {
  final double progress;
  final int dataPoints;
  final double confidence;

  const LearningProgressBar({
    Key? key,
    required this.progress,
    required this.dataPoints,
    required this.confidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '学习进度',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progress),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '数据点: $dataPoints',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '置信度: ${(confidence * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) {
      return Colors.red;
    } else if (progress < 0.7) {
      return Colors.orange;
    } else if (progress < 1.0) {
      return Colors.lightGreen;
    } else {
      return Colors.green;
    }
  }
}
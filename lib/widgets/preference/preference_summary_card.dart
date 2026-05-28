import 'package:flutter/material.dart';
import '../../models/user_preference.dart';

/// 偏好摘要卡片
/// 显示用户偏好学习的关键指标
class PreferenceSummaryCard extends StatelessWidget {
  final int learningDataPoints;
  final double confidenceScore;
  final double learningProgress;
  final double overallAcceptanceRate;
  final bool hasSufficientConfidence;

  const PreferenceSummaryCard({
    Key? key,
    required this.learningDataPoints,
    required this.confidenceScore,
    required this.learningProgress,
    required this.overallAcceptanceRate,
    required this.hasSufficientConfidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasSufficientConfidence
                      ? Icons.check_circle
                      : Icons.info,
                  color: hasSufficientConfidence
                      ? Colors.green
                      : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasSufficientConfidence
                        ? 'AI已充分了解您的写作偏好'
                        : 'AI正在学习您的写作偏好',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              context,
              Icons.data_usage,
              '学习数据点',
              learningDataPoints.toString(),
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              context,
              Icons.psychology,
              '置信度',
              '${(confidenceScore * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              context,
              Icons.trending_up,
              '学习进度',
              '${(learningProgress * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              context,
              Icons.thumb_up,
              '总体接受率',
              '${(overallAcceptanceRate * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
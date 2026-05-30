import 'package:flutter/material.dart';

/// 主题兴趣云
/// 显示用户关注的主题和兴趣程度
class TopicInterestCloud extends StatelessWidget {
  final Map<String, double> topicInterests;

  const TopicInterestCloud({
    super.key,
    required this.topicInterests,
  });

  @override
  Widget build(BuildContext context) {
    if (topicInterests.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedTopics = topicInterests.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '关注的主题',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sortedTopics.take(15).map((entry) {
            return _buildTopicChip(
              context,
              entry.key,
              entry.value,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTopicChip(
    BuildContext context,
    String topic,
    double interest,
  ) {
    return Chip(
      label: Text(
        topic,
        style: TextStyle(
          fontSize: _getFontSize(interest),
          color: _getTextColor(interest),
        ),
      ),
      backgroundColor: _getBackgroundColor(interest),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  double _getFontSize(double interest) {
    if (interest >= 0.8) {
      return 16;
    } else if (interest >= 0.6) {
      return 15;
    } else if (interest >= 0.4) {
      return 14;
    } else {
      return 13;
    }
  }

  Color _getTextColor(double interest) {
    if (interest >= 0.6) {
      return Colors.white;
    } else {
      return Colors.black87;
    }
  }

  Color _getBackgroundColor(double interest) {
    if (interest >= 0.8) {
      return Colors.deepPurple;
    } else if (interest >= 0.6) {
      return Colors.purple;
    } else if (interest >= 0.4) {
      return Colors.purple.withOpacity(0.7);
    } else {
      return Colors.purple.withOpacity(0.3);
    }
  }
}

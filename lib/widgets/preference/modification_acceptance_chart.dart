import 'package:flutter/material.dart';
import '../../models/user_preference.dart';

/// 修改接受率图表
/// 显示用户对不同类型修改的接受率
class ModificationAcceptanceChart extends StatelessWidget {
  final Map<ModificationType, double> acceptanceRates;

  const ModificationAcceptanceChart({
    Key? key,
    required this.acceptanceRates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedEntries = acceptanceRates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '修改接受率',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        ...sortedEntries.map((entry) => _buildBar(
              context,
              _getModificationTypeLabel(entry.key),
              entry.value,
            )),
      ],
    );
  }

  Widget _buildBar(
    BuildContext context,
    String label,
    double value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                '${(value * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getAcceptanceColor(value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAcceptanceColor(double value) {
    if (value >= 0.7) {
      return Colors.green;
    } else if (value >= 0.4) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getModificationTypeLabel(ModificationType type) {
    switch (type) {
      case ModificationType.grammar:
        return '语法修正';
      case ModificationType.spelling:
        return '拼写修正';
      case ModificationType.style:
        return '风格改进';
      case ModificationType.expansion:
        return '内容扩展';
      case ModificationType.simplification:
        return '内容精简';
      case ModificationType.structure:
        return '结构调整';
      case ModificationType.vocabulary:
        return '词汇替换';
      case ModificationType.other:
        return '其他修改';
    }
  }
}
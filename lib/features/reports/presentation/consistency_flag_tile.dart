import 'package:flutter/material.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/reports/domain/consistency_report.dart';
import 'package:museflow/features/reports/presentation/severity_indicator.dart';

class ConsistencyFlagTile extends StatelessWidget {
  const ConsistencyFlagTile({super.key, required this.flag});

  final ConsistencyFlag flag;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: SeverityIndicator(severity: _severityLabel(flag.severity)),
        title: Text(flag.field),
        subtitle: Text('${flag.expectedValue} -> ${flag.observedText}'),
        trailing: Text('Ch${flag.chapterIndex + 1}'),
      ),
    );
  }

  String _severityLabel(DeviationSeverity severity) {
    return switch (severity) {
      DeviationSeverity.clear => '高',
      DeviationSeverity.medium => '中',
      DeviationSeverity.low => '低',
    };
  }
}

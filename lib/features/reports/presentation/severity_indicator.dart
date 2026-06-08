import 'package:flutter/material.dart';

class SeverityIndicator extends StatelessWidget {
  const SeverityIndicator({super.key, required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (severity) {
      '高' => colorScheme.error,
      '中' => colorScheme.tertiary,
      '低' => colorScheme.onSurfaceVariant,
      _ => colorScheme.outline,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(severity),
      ],
    );
  }
}

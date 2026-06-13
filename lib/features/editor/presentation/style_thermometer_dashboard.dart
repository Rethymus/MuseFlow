/// Style thermometer widget — visual AI-scent score dashboard.
///
/// Per Phase 19 (AISC-02, AISC-03): Displays a 0-100 AI-scent score
/// with color-coded gauge, per-dimension breakdown bars, and a
/// human-readable summary of detected deviations.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:museflow/features/editor/application/style_deviation_detector.dart';
import 'package:museflow/features/editor/domain/style_dimension.dart';

/// A visual dashboard showing the AI-scent score and dimension breakdown.
///
/// Designed to be embedded in the editor sidebar or the style profile page.
class StyleThermometerDashboard extends StatelessWidget {
  const StyleThermometerDashboard({
    super.key,
    required this.result,
    this.onDimensionTap,
  });

  /// The deviation analysis result to display.
  final StyleDeviationResult result;

  /// Optional callback when a dimension card is tapped.
  final void Function(StyleDimension dimension)? onDimensionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScoreGauge(score: result.aiScentScore),
        const SizedBox(height: 8),
        _ScoreLabel(score: result.aiScentScore, theme: theme),
        const SizedBox(height: 4),
        Text(
          result.summary,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...result.deviations.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DimensionBar(deviation: d, onTap: onDimensionTap),
          ),
        ),
      ],
    );
  }
}

/// Circular gauge displaying the AI-scent score.
class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(score);

    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _GaugePainter(
          score: score.toDouble(),
          color: color,
          trackColor: theme.colorScheme.surfaceContainerHighest,
          backgroundColor: theme.colorScheme.surface,
        ),
      ),
    );
  }
}

/// Text label beneath the gauge.
class _ScoreLabel extends StatelessWidget {
  const _ScoreLabel({required this.score, required this.theme});

  final int score;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    return Center(
      child: Text(
        _scoreDescription(score),
        style: theme.textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A horizontal bar showing one dimension's deviation.
class _DimensionBar extends StatelessWidget {
  const _DimensionBar({required this.deviation, this.onTap});

  final DimensionDeviation deviation;
  final void Function(StyleDimension)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (deviation.deviationScore * 100).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null ? () => onTap!(deviation.dimension) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    deviation.dimension.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _barColor(deviation.deviationScore),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: deviation.deviationScore.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    _barColor(deviation.deviationScore),
                  ),
                ),
              ),
              if (deviation.deviationScore >= 0.3) ...[
                const SizedBox(height: 2),
                Text(
                  deviation.explanation,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the circular gauge.
class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.score,
    required this.color,
    required this.trackColor,
    required this.backgroundColor,
  });

  final double score;
  final Color color;
  final Color trackColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Track (background ring)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Score arc
    const startAngle = -math.pi / 2; // top
    final sweepAngle = 2 * math.pi * (score / 100);
    final scorePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      scorePaint,
    );

    // Score text
    final textSpan = TextSpan(
      text: '$score',
      style: TextStyle(
        color: color,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.0,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}

/// Returns the color for a given AI-scent score.
Color _scoreColor(int score) {
  if (score < 25) return const Color(0xFF4CAF50); // green
  if (score < 50) return const Color(0xFFFFC107); // amber
  if (score < 75) return const Color(0xFFFF9800); // orange
  return const Color(0xFFF44336); // red
}

/// Returns the description text for a given AI-scent score.
String _scoreDescription(int score) {
  if (score < 15) return 'AI痕迹极低';
  if (score < 30) return 'AI痕迹较低';
  if (score < 50) return 'AI痕迹中等';
  if (score < 70) return 'AI痕迹较高';
  if (score < 85) return 'AI痕迹明显';
  return 'AI痕迹极强';
}

/// Returns the bar color for a deviation score.
Color _barColor(double deviation) {
  if (deviation < 0.2) return const Color(0xFF4CAF50);
  if (deviation < 0.4) return const Color(0xFFFFC107);
  if (deviation < 0.6) return const Color(0xFFFF9800);
  return const Color(0xFFF44336);
}

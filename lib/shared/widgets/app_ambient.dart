/// AppAmbientCanvas — the ambient layer every glass surface samples.
///
/// Apple's frosted materials read as "deep" because there is always
/// *something* behind them: on iOS it is the wallpaper + scrolling content,
/// on macOS the desktop behind a translucent window. In MuseFlow the
/// equivalent backdrop is this full-viewport canvas: a neutral base wash
/// plus a few very soft accent-tinted radial "blobs" (think macOS Sonoma
/// wallpaper at ~5% strength). Chrome glass (sidebar, tab bar, dialogs,
/// floating toolbar) samples it through [BackdropFilter], so translucency
/// finally has luminance variation to reveal — the layer the roadmap calls
/// "毛玻璃随背后的界面内容产生层次".
///
/// The canvas is deliberately **static**: HIG warns against decorative
/// motion, and a repaint-cheap backdrop keeps the blur cost isolated to
/// the glass surfaces themselves. It paints exactly once per size/theme
/// change (`RepaintBoundary` + `isComplex`), so it cannot jitter 60fps.
///
/// When "reduce transparency" is on, callers paint the plain opaque base
/// instead ([AppAmbient.baseColor]) — Apple's accessibility fallback.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One soft radial wash on the ambient canvas.
class AmbientBlob {
  const AmbientBlob({
    required this.color,
    required this.center,
    required this.radiusFactor,
  });

  /// Full blob color; the painter fades its alpha to 0 at the rim.
  final Color color;

  /// Center in 0..1 viewport fractions (may be < 0 or > 1 — blobs bleed
  /// off-canvas like a real wallpaper crop).
  final Alignment center;

  /// Blob radius as a fraction of the viewport's long side.
  final double radiusFactor;
}

/// Ambient backdrop specifications, one per brightness.
///
/// Alphas are intentionally whisper-quiet: after a σ24–30 blur *and* a
/// 60–80% tint wash, anything louder would read as decoration rather
/// than depth. Light mode uses cool pastels on grouped gray; dark mode
/// keeps the pure-black base and lets slightly stronger blobs glow the
/// way macOS dark wallpapers do.
abstract final class AppAmbient {
  /// Opaque fallback when translucency is reduced (accessibility).
  static Color baseColor(AppPalette p) => p.groupedBackground;

  static List<AmbientBlob> blobs(AppPalette p) => p.isDark
      ? const [
          AmbientBlob(
            color: Color(0x305E5CE6), // systemIndigo @ 19%
            center: Alignment(-0.82, -0.62),
            radiusFactor: 0.62,
          ),
          AmbientBlob(
            color: Color(0x1E40C8E0), // systemTeal @ 12%
            center: Alignment(0.88, 0.78),
            radiusFactor: 0.55,
          ),
          AmbientBlob(
            color: Color(0x17BF5AF2), // systemPurple @ 9%
            center: Alignment(0.44, -1.05),
            radiusFactor: 0.48,
          ),
        ]
      : const [
          AmbientBlob(
            color: Color(0x175856D7), // systemIndigo @ 9%
            center: Alignment(-0.86, -0.68),
            radiusFactor: 0.58,
          ),
          AmbientBlob(
            color: Color(0x1130B0C7), // systemTeal @ 7%
            center: Alignment(0.90, 0.82),
            radiusFactor: 0.52,
          ),
          AmbientBlob(
            color: Color(0x0CFF2D55), // systemPink @ 5%
            center: Alignment(0.40, -1.08),
            radiusFactor: 0.45,
          ),
        ];
}

/// Full-viewport ambient backdrop: base wash + accent blobs.
///
/// Sits at the bottom of the app's root [Stack]; the shell scaffold above
/// it is transparent, so glass chrome samples this canvas wherever no page
/// content covers it.
class AppAmbientCanvas extends StatelessWidget {
  const AppAmbientCanvas({super.key, this.enabled = true});

  /// False paints only the opaque base (reduce-transparency fallback).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    if (!enabled) {
      return ColoredBox(color: AppAmbient.baseColor(p));
    }
    return RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _AmbientPainter(p: p),
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({required this.p});

  final AppPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppAmbient.baseColor(p),
    );
    final longSide = size.longestSide;
    for (final blob in AppAmbient.blobs(p)) {
      final center = Offset(
        size.width * (blob.center.x + 1) / 2,
        size.height * (blob.center.y + 1) / 2,
      );
      final rect = Rect.fromCircle(
        center: center,
        radius: blob.radiusFactor * longSide,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [blob.color, blob.color.withValues(alpha: 0)],
          ).createShader(rect),
        // Squaring the circle's bounding rect is fine: the rim alpha is 0
        // well before the corners.
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) => oldDelegate.p != p;
}

/// Apple scrolling physics for MuseFlow (research doc §3).
///
/// iOS hand-feel comes from BouncingScrollPhysics — the rubber-band
/// boundary (offset = (1 − 1/(0.55·x/d + 1))·d), the 0.998 deceleration
/// rate, and a spring (not a curve) for boundary snap-back. Touch pointer
/// platforms get the full Apple feel; desktop mice drive scrolling via
/// pointer-scroll deltas, which the physics layer doesn't affect, so
/// Windows keeps its native wheel behavior while touchscreens (the
/// Android target) feel iOS-grade.
library;

import 'package:flutter/material.dart';

class AppleScrollBehavior extends MaterialScrollBehavior {
  const AppleScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return switch (getPlatform(context)) {
      // macOS is clamped-and-wheeled natively; every other target uses the
      // iOS bouncing feel.
      TargetPlatform.macOS => const ClampingScrollPhysics(),
      _ => const BouncingScrollPhysics(
        decelerationRate: ScrollDecelerationRate.normal,
      ),
    };
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Thin overlay scrollbars on desktop (Apple never reserves gutter
    // space); none on touch.
    switch (axisDirectionToAxis(details.direction)) {
      case Axis.horizontal:
        return child;
      case Axis.vertical:
        switch (getPlatform(context)) {
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            return Scrollbar(child: child);
          default:
            return child;
        }
    }
  }
}

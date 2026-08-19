/// Apple-style motion tokens for MuseFlow.
///
/// Apple interfaces animate with soft decelerating curves and short
/// durations. These constants replace default Material easing so every
/// transition in the app shares the same gentle, purposeful feel.
library;

import 'package:flutter/animation.dart';

/// The standard iOS ease-out curve (a smooth spring-like deceleration).
const Cubic appleEase = Curves.easeOutCubic;

/// Slightly snappier variant for small controls (switches, toggles).
const Cubic appleEaseEmphasized = Curves.easeOutQuint;

/// Standard iOS animation durations.
abstract final class AppDurations {
  /// Micro interactions: opacity fades, hairline reveals.
  static const Duration fast = Duration(milliseconds: 180);

  /// Default for panels, sheets, segmented control slides.
  static const Duration medium = Duration(milliseconds: 250);

  /// Full-screen transitions and large layout changes.
  static const Duration slow = Duration(milliseconds: 350);
}

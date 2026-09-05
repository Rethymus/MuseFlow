/// Apple-style motion tokens for MuseFlow — springs, damping, durations.
///
/// Built on the research in `docs/design/apple-motion-research.md`:
/// Apple's entire motion system is spring-based, parameterized by
/// (response, dampingFraction) — NOT fixed-duration curves. Flutter's
/// [SpringSimulation] maps 1:1 via:
///
///     ω = 2π / response
///     stiffness = m·ω²            (m = 1)
///     damping    = 2·ζ·m·ω        (ζ = dampingFraction)
///
/// so `AppleSprings.simulation(response, dampingFraction)` reproduces the
/// exact SwiftUI feel when driven with `AnimationController.animateWith`.
///
/// Key hand-feel rules encoded here:
/// - ζ = 1.0 (smooth): no overshoot — large moves, layout changes.
/// - ζ ≈ 0.825 (Apple default): one barely-perceptible overshoot.
/// - ζ ≈ 0.6 with 0.3s response (snappy): small controls, press release.
/// - Springs are for *trigger* animations; during a drag, track the finger
///   directly (velocity-preserving retargeting is what "silky" means).
library;

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// The standard iOS ease-out curve for non-spring (fade/color) transitions.
const Cubic appleEase = Curves.easeOutCubic;

/// Slightly snappier variant for small controls (switches, toggles).
const Cubic appleEaseEmphasized = Curves.easeOutQuint;

/// Apple spring presets, values from SwiftUI documentation and WWDC23.
abstract final class AppleMotion {
  /// SwiftUI `.spring()` defaults — the general-purpose feel.
  static const double defaultResponse = 0.5;
  static const double defaultDampingFraction = 0.825;

  /// `.smooth` — duration 0.5, no bounce (ζ=1.0, critically damped).
  /// Large displacements, sheet/layout changes: glides in, never wobbles.
  static const double smoothResponse = 0.5;
  static const double smoothDampingFraction = 1.0;

  /// `.snappy` — duration 0.3, extraBounce 0.15. Small controls, press
  /// release, toggles: crisp with a visible-but-tiny rebound.
  static const double snappyResponse = 0.3;
  static const double snappyDampingFraction = 0.65;

  /// `.bouncy` — duration 0.3, extraBounce 0.3. Playful emphasis only.
  static const double bouncyResponse = 0.3;
  static const double bouncyDampingFraction = 0.5;

  /// `interactiveSpring` — very stiff (0.15s), near-critically damped:
  /// retargeting during gestures without lag.
  static const double interactiveDampingFraction = 0.86;
  static const double interactiveResponse = 0.15;

  /// Slot snap (research doc §7): a thumb/row snapping between discrete
  /// slots (segmented control, reorder drop). 0.3s with ζ 0.85 — the
  /// overshoot (~1.7%) reads as a "click into place", never a wobble.
  static const double slotSnapResponse = 0.3;
  static const double slotSnapDampingFraction = 0.85;
}

/// Builds [SpringSimulation]s from Apple's (response, dampingFraction)
/// parameterization — the Flutter equivalent of
/// `UIViewPropertyAnimator(springTiming:)` / SwiftUI `.spring(response:)`.
abstract final class AppleSprings {
  /// Mass is normalized to 1; Apple's parameters don't expose it.
  static const double _mass = 1.0;

  /// The raw spring constants for (response, dampingFraction) — exposed so
  /// tests can pin the conversion math.
  static SpringDescription description(
    double response,
    double dampingFraction,
  ) {
    final omega = 2 * 3.141592653589793 / response;
    return SpringDescription(
      mass: _mass,
      stiffness: _mass * omega * omega,
      damping: 2 * dampingFraction * _mass * omega,
    );
  }

  /// A spring from rest toward [end], Apple-parameterized.
  ///
  /// [response] is the approximate settling duration in seconds (0 =
  /// infinitely stiff — do not pass literally). [dampingFraction] is ζ:
  /// 1.0 critical, 0.825 Apple default, lower = bouncier.
  static SpringSimulation simulation(
    double end, {
    double response = AppleMotion.defaultResponse,
    double dampingFraction = AppleMotion.defaultDampingFraction,
    double velocity = 0.0,
    double start = 0.0,
  }) {
    return SpringSimulation(
      description(response, dampingFraction),
      start,
      end,
      velocity,
    );
  }

  /// The `.smooth` preset: no overshoot, for large moves.
  static SpringSimulation smooth(double end, {double velocity = 0.0}) =>
      simulation(
        end,
        response: AppleMotion.smoothResponse,
        dampingFraction: AppleMotion.smoothDampingFraction,
        velocity: velocity,
      );

  /// The `.snappy` preset: small controls, press release.
  static SpringSimulation snappy(double end, {double velocity = 0.0}) =>
      simulation(
        end,
        response: AppleMotion.snappyResponse,
        dampingFraction: AppleMotion.snappyDampingFraction,
        velocity: velocity,
      );

  /// Slot snap: a thumb snapping between discrete slots.
  static SpringSimulation slotSnap(double end, {double velocity = 0.0}) =>
      simulation(
        end,
        response: AppleMotion.slotSnapResponse,
        dampingFraction: AppleMotion.slotSnapDampingFraction,
        velocity: velocity,
      );
}

/// The damped-oscillation used for error shakes ("pushing a boulder" —
/// research doc §9.1). NOT a spring: starts at full amplitude with zero
/// velocity (the moment of refusal) and decays fast enough to feel like
/// enormous friction.
///
///     x(t) = A · e^(−λ·t) · sin(2π·f·t)
class AppShakeSimulation extends Simulation {
  AppShakeSimulation({
    this.amplitude = 9.0,
    this.frequency = 10.0,
    this.decay = 9.0,
    this.duration = const Duration(milliseconds: 400),
  }) : _omega = 2 * 3.141592653589793 * frequency;

  /// Peak horizontal offset in logical pixels.
  final double amplitude;

  /// Oscillation frequency in Hz — fast, never nauseating.
  final double frequency;

  /// Exponential decay rate (1/s); 9 ≈ three visible swings.
  final double decay;

  /// Total shake duration.
  final Duration duration;

  final double _omega;

  @override
  double x(double timeInSeconds) {
    return amplitude *
        _exp(-decay * timeInSeconds) *
        _sin(_omega * timeInSeconds);
  }

  @override
  double dx(double timeInSeconds) {
    final e = _exp(-decay * timeInSeconds);
    return amplitude * e * (_omega * _cos(_omega * timeInSeconds)) -
        amplitude * decay * e * _sin(_omega * timeInSeconds);
  }

  @override
  bool isDone(double timeInSeconds) =>
      timeInSeconds >= duration.inMicroseconds / 1e6;

  // Thin wrappers so this file stays import-light next to theme code.
  static double _exp(double x) {
    // e^x via dart:math would be direct; keep the math explicit here for
    // readability and testability.
    return math.exp(x);
  }

  static double _sin(double x) => math.sin(x);
  static double _cos(double x) => math.cos(x);
}

/// Standard iOS animation durations for non-spring transitions
/// (fades, color-only changes — springs carry displacement).
abstract final class AppDurations {
  /// Micro interactions: opacity fades, hairline reveals, press-in.
  static const Duration fast = Duration(milliseconds: 100);

  /// Default for color cross-fades and segmented-control slides.
  static const Duration medium = Duration(milliseconds: 250);

  /// Full-screen fades and large layout changes.
  static const Duration slow = Duration(milliseconds: 350);
}

/// Press-feedback specs (UIKit behavior, see research doc §2).
abstract final class AppPressSpec {
  /// Touch press-down scale (UIKit buttons ~0.96–0.97).
  static const double touchScale = 0.97;

  /// Pointer/mouse presses are subtler (Liquid Glass: subdued for indirect
  /// input).
  static const double pointerScale = 0.98;

  /// Press-down is fast and damped by the finger itself: no spring back.
  static const Duration pressIn = Duration(milliseconds: 90);

  /// Release springs back with a snappy feel.
  static const double releaseResponse = AppleMotion.snappyResponse;
  static const double releaseDamping = AppleMotion.snappyDampingFraction;
}

/// AppShake — the "pushing a boulder" error shake (research doc §9.1).
///
/// A damped oscillation, NOT a spring: starts at full amplitude with zero
/// velocity (the instant of refusal) and decays with enormous friction —
/// x(t) = A·e^(−λt)·sin(2πft). Attach a [GlobalKey<AppShakeState>] and
/// call `shake()` when validation fails; the subtree slides horizontally.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';

class AppShake extends StatefulWidget {
  const AppShake({super.key, required this.child});

  final Widget child;

  @override
  State<AppShake> createState() => AppShakeState();
}

class AppShakeState extends State<AppShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Runs one shake cycle. Safe to call repeatedly (restarts).
  void shake() {
    // HIG: motion must not be the only feedback channel — pair the visual
    // refusal with a heavy impact on platforms that support haptics
    // (no-op on desktop).
    HapticFeedback.heavyImpact();
    _controller.animateWith(AppShakeSimulation());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dx = _controller.value;
        if (dx == 0) return child!;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

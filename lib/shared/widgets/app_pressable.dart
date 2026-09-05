/// AppPressable — the iOS press-feedback feel for MuseFlow.
///
/// Implements the smallest unit of Apple's tactile detail (research doc §2):
/// on press-down the child quickly scales to 0.97 (touch) / 0.98 (mouse —
/// Liquid Glass guidance: subdued for indirect input); on release it
/// springs back with the snappy preset (0.3s, small bounce) instead of a
/// fixed curve. Press-in is fast and non-springy — the finger is the
/// damper. Use around any tappable card/row/chip that isn't already a
/// Material button.
///
/// The controller is unbounded so the spring's overshoot (the signature
/// of ζ<1 damping) is not clamped away.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Wraps [child] with Apple-style press-down scale feedback while
/// delegating the actual tap to [onTap].
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.touchScale = AppPressSpec.touchScale,
    this.pointerScale = AppPressSpec.pointerScale,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Disables both the callback and the scale feedback when false.
  final bool enabled;

  /// Scale while pressed with a touch pointer.
  final double touchScale;

  /// Scale while pressed with a mouse/trackpad (subtler).
  final double pointerScale;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this, value: 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pressIn(PointerDownEvent event) {
    if (!widget.enabled) return;
    final scale = event.kind == PointerDeviceKind.touch
        ? widget.touchScale
        : widget.pointerScale;
    // Fast, non-springy press-in — the finger is the damper.
    _controller.animateTo(
      scale,
      duration: AppPressSpec.pressIn,
      curve: appleEase,
    );
  }

  void _release() {
    if (!widget.enabled) return;
    // Snappy spring back to full size, from wherever the press got to.
    _controller.animateWith(
      AppleSprings.simulation(
        1.0,
        response: AppPressSpec.releaseResponse,
        dampingFraction: AppPressSpec.releaseDamping,
        start: _controller.value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _pressIn,
      onPointerUp: (_) {
        _release();
        if (widget.enabled) widget.onTap?.call();
      },
      onPointerCancel: (_) => _release(),
      child: GestureDetector(
        onLongPress: widget.enabled ? widget.onLongPress : null,
        child: ScaleTransition(scale: _controller, child: widget.child),
      ),
    );
  }
}

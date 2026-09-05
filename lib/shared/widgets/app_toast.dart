/// AppToast — iOS-style floating toast with a spring entrance
/// (research doc §9.2).
///
/// Entrance: y +14px and scale 0.96 → 1.0 on spring(response 0.4, ζ 0.85)
/// — half a notch slower than snappy, because information doesn't need a
/// button's crispness. Exit: a fast 120ms fade with no elasticity ("leaving
/// shouldn't be theatrical"). Sits above the tab bar and inside safe areas.
/// Only one toast at a time: a new call replaces the current one.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_motion.dart';

/// Shows an iOS-style toast above the bottom chrome. Falls back to a
/// SnackBar when no Overlay exists (bare widget tests).
Future<void> showAppToast(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(milliseconds: 2400),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
    return Future.value();
  }
  _currentEntry?._dismissAndRemove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AppToastView(
      message: message,
      duration: duration,
      onRemove: () => entry.remove(),
    ),
  );
  _currentEntry = null; // the new view registers itself below
  overlay.insert(entry);
  return Future.value();
}

/// The live toast's handle — a new [showAppToast] dismisses it first.
_AppToastViewState? _currentEntry;

class _AppToastView extends StatefulWidget {
  const _AppToastView({
    required this.message,
    required this.duration,
    required this.onRemove,
  });

  final String message;
  final Duration duration;
  final VoidCallback onRemove;

  @override
  State<_AppToastView> createState() => _AppToastViewState();
}

class _AppToastViewState extends State<_AppToastView>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _exit;

  /// The hold delay is frame-scheduled (not a Timer) so tests can
  /// fast-forward it with pumpAndSettle, and so it composes with the
  /// exit animation without pending-timer teardown failures.
  late final AnimationController _hold;
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    _currentEntry = this;
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    // Unbounded so the spring's slight overshoot isn't clamped.
    _entrance = AnimationController.unbounded(vsync: this, value: 0.0);
    _entrance.animateWith(
      AppleSprings.simulation(
        1.0,
        response: 0.4,
        dampingFraction: 0.85,
        start: 0.0,
      ),
    );
    _hold = AnimationController(vsync: this, duration: widget.duration)
      ..forward().whenComplete(_dismissAndRemove);
  }

  void _dismissAndRemove() {
    if (!mounted) {
      _currentEntry = null;
      return;
    }
    if (_removing) return;
    _removing = true;
    _exit.forward().whenComplete(widget.onRemove);
  }

  @override
  void dispose() {
    // Clear the process-wide handle if it still points here, so a toast
    // left mounted across a tree teardown can't poison the next one.
    if (_currentEntry == this) _currentEntry = null;
    _entrance.dispose();
    _hold.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          // 34pt above the bottom edge: clears the frosted tab bar.
          minimum: const EdgeInsets.only(bottom: AppSpacing.lg + 34),
          child: AnimatedBuilder(
            animation: Listenable.merge([_entrance, _exit]),
            builder: (context, child) {
              final t = _entrance.value.clamp(0.0, 1.0);
              final fade = _removing ? 1 - _exit.value : 1.0;
              return Opacity(
                opacity: fade.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - t)),
                  child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: p.isDark ? p.gray5 : const Color(0xE62C2C2E),
                borderRadius: AppRadius.pill,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: textTheme.bodyMedium?.copyWith(
                  color: p.isDark ? p.label : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

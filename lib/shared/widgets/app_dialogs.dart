/// iOS-style alerts and action sheets for MuseFlow.
///
/// Apple alerts: small rounded card, centered bold title + secondary message,
/// buttons stacked with hairline separators — destructive action in red,
/// default action in the app accent. Action sheets: grouped bottom sheet
/// with 21pt actions and a separate cancel group.
library;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_materials.dart';
import '../theme/app_motion.dart';

/// One alert button. [isDefault] renders in the accent tint and bold;
/// [isDestructive] renders in system red.
class AppDialogAction {
  const AppDialogAction(
    this.label, {
    this.onPressed,
    this.isDefault = false,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isDefault;
  final bool isDestructive;
}

/// Shows an iOS-style alert dialog.
///
/// Returns the result of [Navigator.pop] from the pressed action's handler
/// context, mirroring [showDialog].
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  required List<AppDialogAction> actions,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: title,
    // iOS alert entrance: scale 0.95→1.0 on a light spring (ζ≈0.8) plus a
    // synchronized fade; the barrier only fades (research doc §9.3).
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
      );
      final scale = Tween<double>(begin: 0.95, end: 1.0).animate(
        // Unbounded-style spring on the same controller via
        // animateWith is not available here; approximate the spring with
        // easeOutBack, whose overshoot (~2%) matches ζ≈0.8's signature.
        CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
    pageBuilder: (_, _, _) => AppAlertDialog(
      title: title,
      message: message,
      content: content,
      actions: actions,
    ),
  );
}

/// The iOS alert widget — centered bold title, secondary message, stacked
/// hairline-separated buttons (2 short actions sit side by side).
class AppAlertDialog extends StatelessWidget {
  const AppAlertDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    required this.actions,
  });

  final String title;
  final String? message;
  final Widget? content;
  final List<AppDialogAction> actions;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sideBySide =
        actions.length == 2 &&
        actions.every((a) => a.label.characters.length <= 6);

    final buttons = [
      for (final a in actions)
        // Expanded only in the horizontal row (bounded width); the stacked
        // variant lives in an unbounded-height shrink-wrap column.
        sideBySide
            ? Expanded(child: _AlertButton(action: a, dividerSide: true))
            : _AlertButton(action: a, dividerSide: false),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rMedium),
      child: AppMaterial(
        tier: AppMaterialTier.thick,
        radius: AppRadius.rMedium,
        shadow: true,
        child: ClipRRect(
          borderRadius: AppRadius.rMedium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: p.secondaryLabel,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (content != null) ...[
                      const SizedBox(height: 12),
                      content!,
                    ],
                  ],
                ),
              ),
              Divider(height: 0.5, thickness: 0.5, color: p.separator),
              if (sideBySide)
                Row(
                  children: [
                    buttons[0],
                    VerticalDivider(
                      width: 0.5,
                      thickness: 0.5,
                      color: p.separator,
                    ),
                    buttons[1],
                  ],
                )
              else
                Column(children: buttons),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertButton extends StatelessWidget {
  const _AlertButton({required this.action, required this.dividerSide});

  final AppDialogAction action;
  final bool dividerSide;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final color = action.isDestructive
        ? p.systemRed
        : action.isDefault
        ? p.accent
        : p.accent;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        action.onPressed?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: dividerSide
            ? null
            : BoxDecoration(
                border: Border(top: BorderSide(color: p.separator, width: 0.5)),
              ),
        child: Text(
          action.label,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: action.isDefault ? FontWeight.w600 : FontWeight.w400,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}

/// One action-sheet entry.
class AppSheetAction {
  const AppSheetAction(
    this.label, {
    this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;
}

/// Shows an iOS-style action sheet: one grouped card of actions above a
/// separate cancel button, over a dimmed scrim.
Future<void> showAppActionSheet(
  BuildContext context, {
  String? title,
  required List<AppSheetAction> actions,
  String cancelLabel = '取消',
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    // No overlay (bare tests): keep the framework sheet as a fallback.
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ActionSheetContent(
        title: title,
        actions: actions,
        cancelLabel: cancelLabel,
        onDismiss: () => Navigator.of(sheetContext).pop(),
        dismissThenRun: (callback) {
          Navigator.of(sheetContext).pop();
          callback?.call();
        },
      ),
    );
  }

  late final OverlayEntry entry;
  final hostKey = GlobalKey<_SpringSheetHostState>();
  entry = OverlayEntry(
    builder: (_) => _SpringSheetHost(
      key: hostKey,
      onDismissed: () => entry.remove(),
      child: _ActionSheetContent(
        title: title,
        actions: actions,
        cancelLabel: cancelLabel,
        onDismiss: () => hostKey.currentState?.dismiss(),
        dismissThenRun: (callback) {
          hostKey.currentState?.dismiss();
          callback?.call();
        },
      ),
    ),
  );
  overlay.insert(entry);
  return Future<void>.value();
}

/// The grouped iOS action-sheet card + cancel group.
class _ActionSheetContent extends StatelessWidget {
  const _ActionSheetContent({
    required this.title,
    required this.actions,
    required this.cancelLabel,
    required this.onDismiss,
    required this.dismissThenRun,
  });

  final String? title;
  final List<AppSheetAction> actions;
  final String cancelLabel;
  final VoidCallback onDismiss;
  final void Function(VoidCallback?) dismissThenRun;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    Widget actionButton(AppSheetAction a) => GestureDetector(
      onTap: () => dismissThenRun(a.onPressed),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Text(
          a.label,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            fontSize: 17,
            color: a.isDestructive ? p.systemRed : p.accent,
          ),
        ),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppMaterial(
              tier: AppMaterialTier.regular,
              radius: AppRadius.rMedium,
              shadow: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: p.secondaryLabel,
                        ),
                      ),
                    ),
                    Divider(height: 0.5, thickness: 0.5, color: p.separator),
                  ],
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: p.separator,
                        indent: 12,
                        endIndent: 12,
                      ),
                    actionButton(actions[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppMaterial(
              tier: AppMaterialTier.regular,
              radius: AppRadius.rMedium,
              child: GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    cancelLabel,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: p.accent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spring-driven full-height sheet entrance (research doc §9.3):
/// slides in on the smooth spring (0.5s, ζ1.0 — large displacement, no
/// overshoot), supports velocity-preserving drag-to-dismiss, and exits
/// fast with no elasticity (160ms ease-out).
class _SpringSheetHost extends StatefulWidget {
  const _SpringSheetHost({
    super.key,
    required this.child,
    required this.onDismissed,
  });

  final Widget child;
  final VoidCallback onDismissed;

  @override
  State<_SpringSheetHost> createState() => _SpringSheetHostState();
}

class _SpringSheetHostState extends State<_SpringSheetHost>
    with TickerProviderStateMixin {
  /// 0 = fully below screen, 1 = seated; springs may overshoot slightly.
  late final AnimationController _t;

  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _t = AnimationController.unbounded(vsync: this, value: 0.0);
    _t.animateWith(
      AppleSprings.simulation(
        1.0,
        response: AppleMotion.smoothResponse,
        dampingFraction: AppleMotion.smoothDampingFraction,
      ),
    );
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    // Exit: fast, non-elastic ("leaving shouldn't be theatrical").
    _t
        .animateTo(0.0, duration: const Duration(milliseconds: 160))
        .whenComplete(widget.onDismissed);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dismissing) return;
    final height = context.size?.height;
    if (height == null || height <= 0) return;
    // Finger tracking: the sheet follows the finger 1:1; the release
    // spring inherits the position (which encodes the drag velocity).
    _t.stop();
    _t.value = (_t.value - details.primaryDelta! / height).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dismissing) return;
    final height = context.size?.height;
    if (height == null || height <= 0) return;
    final velocity = (details.primaryVelocity ?? 0) / height; // units/s
    final flungDown =
        details.primaryVelocity != null && details.primaryVelocity! > 600;
    if (flungDown || _t.value < 0.72) {
      _dismissing = true;
      _t
          .animateTo(
            0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(widget.onDismissed);
      return;
    }
    // Released near seated: spring back carrying the finger's velocity.
    _t.animateWith(
      AppleSprings.simulation(
        1.0,
        response: AppleMotion.smoothResponse,
        dampingFraction: AppleMotion.smoothDampingFraction,
        velocity: velocity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dismiss,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) {
          final t = _t.value;
          final barrierOpacity = t.clamp(0.0, 1.0) * 0.4;
          return ColoredBox(
            color: Colors.black.withValues(alpha: barrierOpacity),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionalTranslation(
                translation: Offset(0, 1 - t),
                child: child,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Convenience icon-only close affordance used in sheets and panels.
class AppSheetCloseButton extends StatelessWidget {
  const AppSheetCloseButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(CupertinoIcons.xmark, size: 18),
    );
  }
}

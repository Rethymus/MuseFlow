/// The MuseFlow material system — Apple's layered translucency as
/// verifiable parameters, not ad-hoc colors.
///
/// Every glass surface in the app composes the same four ingredients:
///
/// 1. **Screen-sampling blur** — a real [BackdropFilter] sampling whatever
///    renders behind the surface (scrolling text, wallpaper, cards), with a
///    per-tier sigma.
/// 2. **Semi-transparent tint** — a white-based wash (light mode) or
///    near-black wash (dark mode) layered over the blur, at a per-tier
///    opacity; the blur shows through, creating depth from real content.
/// 3. **Inner highlight** — a brighter-than-tint hairline on the top edge
///    (the signature iOS glass rim).
/// 4. **Hairline border** — [AppPalette.separator] on the remaining edges.
///
/// Tiers mirror UIKit's blur materials (`ultraThin`…`thick`); the neutral
/// elevation ramp ([AppElevation]) mirrors Apple's rule that light surfaces
/// raise toward white while dark surfaces raise toward lighter gray.
/// `test/shared/theme/app_materials_test.dart` pins these parameters, so
/// the system is enforced, not described.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// Neutral elevation ramp for opaque surfaces (no blur needed).
///
/// Apple's rule, made explicit:
/// - light: grouped gray → white (raising brightens)
/// - dark:  black → #1C1C1E → #2C2C2E → #3A3A3C (raising lightens)
enum AppElevation {
  /// Page background (grouped gray / pure black).
  base,

  /// Inset-group cards, sheets (white / #1C1C1E).
  raised,

  /// Menus, popovers (white / #2C2C2E).
  floating,

  /// Alerts and top-most chrome (white / #3A3A3C).
  modal;

  /// Resolves the surface color for this step on [p].
  Color on(AppPalette p) {
    return switch (this) {
      AppElevation.base => p.groupedBackground,
      AppElevation.raised => p.secondaryGroupedBackground,
      AppElevation.floating => p.tertiaryGroupedBackground,
      AppElevation.modal => p.isDark ? p.gray4 : Colors.white,
    };
  }
}

/// Blur material tiers (UIBlurEffect analogs).
///
/// [sigma] is the gaussian blur radius; [tintOpacity] how much tint hides
/// the sampled content. Light tints are white-based, dark tints
/// #1C1C1E-based, per Apple's vibrancy defaults.
enum AppMaterialTier {
  /// Chrome floating over dense content: nav/tab bars, floating toolbars.
  ultraThin,

  /// Navigation columns: sidebars, drawers.
  thin,

  /// Popovers and sheets that need stronger separation.
  regular,

  /// Alerts — nearly opaque, the blur is just texture.
  thick;

  double get sigma => switch (this) {
    AppMaterialTier.ultraThin => 30,
    AppMaterialTier.thin => 24,
    AppMaterialTier.regular => 18,
    AppMaterialTier.thick => 10,
  };

  double tintOpacityOn(AppPalette p) => p.isDark
      ? switch (this) {
          AppMaterialTier.ultraThin => 0.62,
          AppMaterialTier.thin => 0.70,
          AppMaterialTier.regular => 0.80,
          AppMaterialTier.thick => 0.92,
        }
      : switch (this) {
          AppMaterialTier.ultraThin => 0.60,
          AppMaterialTier.thin => 0.70,
          AppMaterialTier.regular => 0.80,
          AppMaterialTier.thick => 0.93,
        };

  /// Tint wash color base: white-dominant in light, near-black in dark.
  Color tintBaseOn(AppPalette p) => p.isDark ? p.gray6 : Colors.white;

  /// Top-edge inner highlight alpha (bright rim).
  double highlightAlphaOn(AppPalette p) => p.isDark ? 0.16 : 0.45;
}

/// A frosted-glass surface: blur + tint + inner highlight + hairline edge.
///
/// Wrap any panel in [AppMaterial] to give it the app's glass treatment.
/// The blur samples real content behind the widget (requires the surface
/// to actually overlap content — e.g. `extendBody`, drawers, overlays).
class AppMaterial extends StatelessWidget {
  const AppMaterial({
    super.key,
    required this.child,
    this.tier = AppMaterialTier.regular,
    this.radius = AppRadius.cMedium,
    this.borderEdges = const {},
    this.shadow = false,
  });

  /// Which edges carry the separator hairline (e.g. right edge of a
  /// sidebar, top edge of a bottom bar). An edge NOT in this set gets the
  /// inner-highlight rim instead — the top edge by default.
  final Set<LogicalEdge> borderEdges;

  /// Adds the soft floating shadow (popovers/alerts only).
  final bool shadow;

  final AppMaterialTier tier;
  final BorderRadiusGeometry radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final tint = tier.tintBaseOn(p).withValues(alpha: tier.tintOpacityOn(p));

    // Hairlines are painted as overlay layers (not a Border) because
    // BoxDecoration cannot combine a borderRadius with per-side colors —
    // the top rim is white while separator edges are gray.
    final rimAlpha = tier.highlightAlphaOn(p);
    final rim = Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: AppRadius.hairline,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: rimAlpha * 0.35),
                Colors.white.withValues(alpha: rimAlpha),
                Colors.white.withValues(alpha: rimAlpha * 0.35),
              ],
            ),
          ),
        ),
      ),
    );

    Widget edge(LogicalEdge edge) {
      final hairline = Container(
        color: p.separator,
        width: edge == LogicalEdge.left || edge == LogicalEdge.right
            ? AppRadius.hairline
            : null,
        height: edge == LogicalEdge.top || edge == LogicalEdge.bottom
            ? AppRadius.hairline
            : null,
      );
      return switch (edge) {
        LogicalEdge.top => Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: hairline,
        ),
        LogicalEdge.bottom => Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: hairline,
        ),
        LogicalEdge.left => Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: hairline,
        ),
        LogicalEdge.right => Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          child: hairline,
        ),
      };
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: p.isDark ? 0.35 : 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: tier.sigma, sigmaY: tier.sigma),
          child: DecoratedBox(
            decoration: BoxDecoration(color: tint, borderRadius: radius),
            // Transparent Material so ink-based children (InkWell,
            // ListTile) work without relying on a Scaffold ancestor.
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  child,
                  if (borderEdges.contains(LogicalEdge.top))
                    edge(LogicalEdge.top)
                  else
                    rim,
                  for (final e in borderEdges.where(
                    (e) => e != LogicalEdge.top,
                  ))
                    edge(e),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logical edges for [AppMaterial.borderEdges].
enum LogicalEdge { top, left, right, bottom }

/// Focus ring: the accent-tinted ring shown around the focused control,
/// Apple-style — 3pt soft outer glow plus a crisp 1.5pt accent outline.
///
/// Observes focus on any descendant (scope-style, does not grab focus
/// itself), so wrapping a button/tile/chip is enough.
class AppFocusRing extends StatefulWidget {
  const AppFocusRing({
    super.key,
    required this.child,
    this.radius,
    this.enabled = true,
  });

  final Widget child;
  final BorderRadius? radius;
  final bool enabled;

  @override
  State<AppFocusRing> createState() => _AppFocusRingState();
}

class _AppFocusRingState extends State<AppFocusRing> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'AppFocusRing');
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    final focused = _focusNode.hasFocus;
    if (focused != _focused) setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final p = AppColors.of(context);
    final r = widget.radius ?? AppRadius.rSmall;

    return Focus(
      focusNode: _focusNode,
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      child: Stack(
        children: [
          widget.child,
          if (_focused)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: r,
                  border: Border.all(color: p.accent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.35),
                      blurRadius: 5,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Theme hook: focus/overlay tint for buttons and chips so keyboard focus
/// reads as an accent wash everywhere, not per-widget colors.
Color appFocusTint(AppPalette p) => p.accent.withValues(alpha: 0.18);

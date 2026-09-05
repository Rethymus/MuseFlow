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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// Scroll-edge state shared between a scrolling content area and the
/// chrome floating above it (HIG Materials "scroll edge effect": the
/// floating surface gains opacity as content scrolls beneath it, keeping
/// text legible while staying translucent at rest).
///
/// 0.0 = content at its top boundary (fully translucent chrome);
/// ramps to 1.0 within the first ~100px of scroll.
class AppScrollEdge extends ValueNotifier<double> {
  AppScrollEdge() : super(0.0);

  /// Maps a scroll offset to the 0..1 edge intensity.
  void updateFromOffset(double pixels) {
    value = (pixels / 100).clamp(0.0, 1.0);
  }
}

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
    this.scrollEdge,
  });

  /// Which edges carry the separator hairline (e.g. right edge of a
  /// sidebar, top edge of a bottom bar). An edge NOT in this set gets the
  /// inner-highlight rim instead — the top edge by default.
  final Set<LogicalEdge> borderEdges;

  /// Adds the soft floating shadow (popovers/alerts only).
  final bool shadow;

  /// When provided, the tint opacity strengthens by up to +25% as the
  /// edge value goes 0→1 (content scrolled beneath the surface) — the
  /// HIG scroll edge effect that keeps floating chrome legible.
  final ValueListenable<double>? scrollEdge;

  final AppMaterialTier tier;
  final BorderRadiusGeometry radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final baseOpacity = tier.tintOpacityOn(p);
    final tint = scrollEdge == null
        ? tier.tintBaseOn(p).withValues(alpha: baseOpacity)
        : null; // built per-frame in the ValueListenableBuilder below

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
          child: _TintLayer(
            p: p,
            tier: tier,
            baseOpacity: baseOpacity,
            tint: tint,
            radius: radius,
            scrollEdge: scrollEdge,
            child: Material(
              // Transparent Material so ink-based children (InkWell,
              // ListTile) work without relying on a Scaffold ancestor.
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

/// The translucent tint layer; rebuilds only when the scroll edge value
/// changes (scroll-linked chrome opacity, HIG Materials).
class _TintLayer extends StatelessWidget {
  const _TintLayer({
    required this.p,
    required this.tier,
    required this.baseOpacity,
    required this.tint,
    required this.radius,
    required this.scrollEdge,
    required this.child,
  });

  final AppPalette p;
  final AppMaterialTier tier;
  final double baseOpacity;

  /// Prebuilt tint when no scroll edge is wired; null otherwise.
  final Color? tint;
  final BorderRadiusGeometry radius;
  final ValueListenable<double>? scrollEdge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (scrollEdge == null) {
      return DecoratedBox(
        decoration: BoxDecoration(color: tint, borderRadius: radius),
        child: child,
      );
    }
    return ValueListenableBuilder<double>(
      valueListenable: scrollEdge!,
      builder: (context, edge, _) {
        // Up to +25% opacity as content scrolls beneath: legibility while
        // scrolling, full translucency at rest.
        final opacity = (baseOpacity + 0.25 * edge).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: tier.tintBaseOn(p).withValues(alpha: opacity),
            borderRadius: radius,
          ),
          child: child,
        );
      },
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

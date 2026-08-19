/// Apple system color palette for MuseFlow.
///
/// Mirrors UIKit's semantic system colors (light/dark pairs) so the app can
/// speak Apple's visual language: layered labels, fills, separators and
/// grouped backgrounds instead of Material tonal palettes.
///
/// Use [AppColors.of] to resolve the palette for the current brightness, or
/// [buildColorScheme] to get a Material [ColorScheme] fully mapped onto these
/// values (so existing `colorScheme.*` call sites inherit the Apple palette).
library;

import 'package:flutter/material.dart';

/// Resolved Apple system colors for one brightness.
///
/// Field names follow UIKit (e.g. `secondarySystemGroupedBackground`) so the
/// mapping to HIG is explicit. All values are opaque or Apple's documented
/// alpha-blended defaults.
class AppPalette {
  const AppPalette._(this.brightness);

  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  // --- Accents & semantics (light / dark) ------------------------------
  Color get accent =>
      isDark ? const Color(0xFF5E5CE6) : const Color(0xFF5856D7);
  Color get systemBlue =>
      isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
  Color get systemGreen =>
      isDark ? const Color(0xFF30D158) : const Color(0xFF34C759);
  Color get systemIndigo =>
      isDark ? const Color(0xFF5E5CE6) : const Color(0xFF5856D7);
  Color get systemOrange =>
      isDark ? const Color(0xFFFF9F0A) : const Color(0xFFFF9500);
  Color get systemPink =>
      isDark ? const Color(0xFFFF375F) : const Color(0xFFFF2D55);
  Color get systemPurple =>
      isDark ? const Color(0xFFBF5AF2) : const Color(0xFFAF52DE);
  Color get systemRed =>
      isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);
  Color get systemTeal =>
      isDark ? const Color(0xFF40C8E0) : const Color(0xFF30B0C7);
  Color get systemYellow =>
      isDark ? const Color(0xFFFFD60A) : const Color(0xFFFFCC00);
  Color get systemMint =>
      isDark ? const Color(0xFF63DAD2) : const Color(0xFF00C7BE);
  Color get systemBrown =>
      isDark ? const Color(0xFFAC8E68) : const Color(0xFFA2845E);

  // --- Gray scale (gray1..gray6) ---------------------------------------
  Color get gray => const Color(0xFF8E8E93);
  Color get gray2 => isDark ? const Color(0xFF636366) : const Color(0xFFAEAEB2);
  Color get gray3 => isDark ? const Color(0xFF48484A) : const Color(0xFFC7C7CC);
  Color get gray4 => isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6);
  Color get gray5 => isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
  Color get gray6 => isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);

  // --- Labels ------------------------------------------------------------
  Color get label => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  Color get secondaryLabel =>
      isDark ? const Color(0x99EBEBF5) : const Color(0x993C3C43);
  Color get tertiaryLabel =>
      isDark ? const Color(0x4DEBEBF5) : const Color(0x4D3C3C43);
  Color get quaternaryLabel =>
      isDark ? const Color(0x28EBEBF5) : const Color(0x2E3C3C43);

  // --- Separators & fills -------------------------------------------------
  Color get separator =>
      isDark ? const Color(0xA6545458) : const Color(0x4A3C3C43);
  Color get opaqueSeparator =>
      isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8);
  Color get fill => isDark ? const Color(0x5C787880) : const Color(0x33787880);
  Color get secondaryFill =>
      isDark ? const Color(0x52787880) : const Color(0x29787880);
  Color get tertiaryFill =>
      isDark ? const Color(0x3D767680) : const Color(0x1F767680);
  Color get quaternaryFill =>
      isDark ? const Color(0x2E747480) : const Color(0x14747480);

  // --- Backgrounds ---------------------------------------------------------
  Color get systemBackground => isDark ? const Color(0xFF000000) : Colors.white;
  Color get secondarySystemBackground => isDark ? gray6 : gray6;
  Color get tertiarySystemBackground => isDark ? gray5 : Colors.white;
  Color get groupedBackground => isDark ? const Color(0xFF000000) : gray6;
  Color get secondaryGroupedBackground =>
      isDark ? const Color(0xFF1C1C1E) : Colors.white;
  Color get tertiaryGroupedBackground => isDark ? gray5 : gray6;

  // --- Derived helpers -----------------------------------------------------
  /// Tint at ~15% over the current background — iOS "app accent chip".
  Color get accentFill =>
      isDark ? const Color(0x265E5CE6) : const Color(0x215856D7);

  /// Card/sheet background on a grouped page.
  Color get cardBackground => secondaryGroupedBackground;

  /// Resolves against the opposite brightness (like CupertinoDynamicColor).
  AppPalette resolveFrom(Brightness b) => AppPalette._(b);
}

/// Light and dark singletons.
const AppPalette lightPalette = AppPalette._(Brightness.light);
const AppPalette darkPalette = AppPalette._(Brightness.dark);

/// Namespace for palette resolution helpers.
abstract final class AppColors {
  /// Resolves the Apple palette for [context]'s brightness.
  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkPalette
      : lightPalette;
}

/// Builds a Material [ColorScheme] fully mapped onto the Apple palette.
///
/// The mapping keeps every existing `colorScheme.*` call site working while
/// making them render Apple semantics:
/// - `surface` = inset-group card white (`secondarySystemGroupedBackground`)
/// - `onSurfaceVariant` = `secondaryLabel` (60% label)
/// - `outline` / `outlineVariant` = separator hairline colors
/// - `surfaceContainerHighest` = card white so legacy chips/cards read as
///   iOS surfaces on the grouped gray background.
ColorScheme buildColorScheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? darkPalette : lightPalette;
  final isDark = brightness == Brightness.dark;

  return ColorScheme(
    brightness: brightness,
    // Primary / accent.
    primary: p.accent,
    onPrimary: Colors.white,
    primaryContainer: isDark
        ? const Color(0xFF3A3A8C)
        : const Color(0xFFDEDEFC),
    onPrimaryContainer: isDark ? Colors.white : const Color(0xFF26247D),
    // Secondary — neutral gray family (Apple's secondary controls).
    secondary: p.gray,
    onSecondary: Colors.white,
    secondaryContainer: p.gray5,
    onSecondaryContainer: p.label,
    // Tertiary — used sparingly for charts / structure accents.
    tertiary: p.systemPurple,
    onTertiary: Colors.white,
    tertiaryContainer: isDark
        ? const Color(0xFF4A2354)
        : const Color(0xFFF3E3FB),
    onTertiaryContainer: p.label,
    // Error.
    error: p.systemRed,
    onError: Colors.white,
    errorContainer: isDark ? const Color(0xFF5C1D18) : const Color(0xFFFFE1DE),
    onErrorContainer: isDark ? Colors.white : const Color(0xFF8E2019),
    // Surfaces: cards are white-on-gray (light) / elevated gray-on-black (dark).
    surface: p.secondaryGroupedBackground,
    onSurface: p.label,
    onSurfaceVariant: p.secondaryLabel,
    surfaceContainerLowest: isDark ? Colors.black : Colors.white,
    surfaceContainerLow: p.secondaryGroupedBackground,
    surfaceContainer: p.secondaryGroupedBackground,
    surfaceContainerHigh: isDark ? p.gray5 : p.gray6,
    surfaceContainerHighest: p.secondaryGroupedBackground,
    surfaceDim: p.groupedBackground,
    surfaceBright: isDark ? p.gray5 : Colors.white,
    // Lines.
    outline: p.gray3,
    outlineVariant: p.opaqueSeparator,
    // Misc.
    shadow: isDark ? Colors.black : const Color(0xFF1C1C1E),
    scrim: isDark ? Colors.black54 : Colors.black45,
    inverseSurface: isDark ? p.gray5 : const Color(0xFF2C2C2E),
    onInverseSurface: isDark ? p.label : Colors.white,
    inversePrimary: p.accent,
    surfaceTint: Colors.transparent,
  );
}

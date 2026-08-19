/// Apple-style type scale for MuseFlow.
///
/// Maps the iOS text styles (largeTitle … caption2) onto Material's
/// [TextTheme] roles so existing `textTheme.*` call sites render the Apple
/// hierarchy. Sizes sit on Apple's compact desktop scale: body text is 15pt
/// (subheadline) with 17pt for emphasis — comfortable for dense CJK
/// writing-app UI at desktop distances.
///
/// CJK glyphs render via the bundled `Noto Sans CJK SC` family; large sizes
/// get slight negative tracking, the signature Apple display look.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's bundled CJK font family (see pubspec assets).
const String kAppFontFamily = 'Noto Sans CJK SC';

/// Apple text styles, font-independent (apply via [TextStyle.fontFamily]).
abstract final class AppTextStyles {
  // Display / titles.
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.12,
  );
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.35,
    height: 1.15,
  );
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.2,
  );
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.25,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.3,
  );
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.4,
  );
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );
}

/// Builds the app [TextTheme] for a brightness, on [kAppFontFamily].
///
/// Material role → iOS style mapping:
/// - display*   → largeTitle / title1 / 24pt display
/// - headline*  → title2 / title3 / 18pt headline
/// - titleLarge → headline (17 semibold)
/// - titleMedium → subhead semibold (15)
/// - titleSmall → footnote medium (13)
/// - bodyLarge  → body (17)
/// - bodyMedium → subhead (15) — the app's default body
/// - bodySmall  → footnote (13)
/// - labelLarge → button label (15 semibold)
/// - labelMedium → caption1 (12)
/// - labelSmall → caption2 (11)
TextTheme buildTextTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? darkPalette : lightPalette;

  return TextTheme(
    displayLarge: AppTextStyles.largeTitle,
    displayMedium: AppTextStyles.title1,
    displaySmall: AppTextStyles.title1.copyWith(fontSize: 24),
    headlineLarge: AppTextStyles.title2,
    headlineMedium: AppTextStyles.title3,
    headlineSmall: AppTextStyles.headline.copyWith(fontSize: 18),
    titleLarge: AppTextStyles.headline,
    titleMedium: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w600),
    titleSmall: AppTextStyles.footnote.copyWith(fontWeight: FontWeight.w500),
    bodyLarge: AppTextStyles.body,
    bodyMedium: AppTextStyles.subhead,
    bodySmall: AppTextStyles.footnote,
    labelLarge: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w600),
    labelMedium: AppTextStyles.caption1,
    labelSmall: AppTextStyles.caption2,
  ).apply(
    fontFamily: kAppFontFamily,
    bodyColor: p.label,
    displayColor: p.label,
  );
}

/// Section header/footer style for inset grouped lists — iOS footnote in
/// secondaryLabel color.
TextStyle groupedSectionHeader(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 13,
    height: 1.35,
    color: dark ? const Color(0x99EBEBF5) : const Color(0x993C3C43),
  );
}

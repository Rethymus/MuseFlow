import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Brand seed — kept from the original single-dark theme so MuseFlow's
/// indigo identity survives the move to paired light/dark schemes.
const Color kSeedColor = Color(0xFF3F51B5);

/// Creates the application theme for either brightness.
///
/// Built with FlexColorScheme on top of the same Material 3 seed engine the
/// app has always used (`ColorScheme.fromSeed`), so the indigo identity is
/// unchanged while gaining what a bare `ThemeData` could not provide:
/// - Paired light/dark schemes from one seed — day writing (high ambient
///   light) and night writing (dark, low-glare) from a single brand color.
/// - Component sub-themes (12dp radius, filled inputs, navigation styling)
///   that give cards, forms and charts distinguishable visual hierarchy.
///
/// CJK text renders via the bundled `Noto Sans CJK SC` font declared in
/// pubspec.yaml (GB2312 subset, ~2.9MB) — no runtime font fetching. Rare
/// characters outside GB2312 fall back to the system font.
///
/// Typography follows UI-SPEC: body 14px w400, label 12px w500,
/// heading 20px w600, display 28px w700.
ThemeData appTheme(Brightness brightness) {
  const subThemes = FlexSubThemesData(
    defaultRadius: 12,
    inputDecoratorIsFilled: true,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    navigationRailSelectedIconSize: 26,
    navigationRailLabelType: NavigationRailLabelType.all,
  );

  final flex = brightness == Brightness.light
      ? FlexColorScheme.light(
          colorScheme: ColorScheme.fromSeed(
            seedColor: kSeedColor,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          subThemesData: subThemes,
        )
      : FlexColorScheme.dark(
          colorScheme: ColorScheme.fromSeed(
            seedColor: kSeedColor,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          darkIsTrueBlack: false,
          subThemesData: subThemes,
        );

  final colorScheme = flex.toScheme;
  final baseTextTheme =
      (brightness == Brightness.dark
              ? Typography.material2021().white
              : Typography.material2021().black)
          .apply(fontFamily: 'Noto Sans CJK SC');

  return flex.toTheme.copyWith(
    textTheme: baseTextTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
  );
}

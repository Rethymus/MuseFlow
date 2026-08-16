import 'package:flutter/material.dart';

/// Creates the application theme with Material 3 dark indigo scheme.
///
/// CJK text renders via the bundled `Noto Sans CJK SC` font declared in
/// pubspec.yaml (GB2312 subset, ~2.9MB) — no runtime font fetching. The
/// previous default of `GoogleFonts.notoSansScTextTheme()` downloaded fonts
/// from fonts.gstatic.com on end-user machines at first launch, which failed
/// on networks without Google access and left the app without Chinese glyphs.
/// Rare characters outside GB2312 fall back to the system font.
///
/// Typography follows UI-SPEC: body 14px w400, label 12px w500,
/// heading 20px w600, display 28px w700.
ThemeData appTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  );

  final baseTextTheme = Typography.material2021().white.apply(
    fontFamily: 'Noto Sans CJK SC',
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    textTheme: baseTextTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
  );
}

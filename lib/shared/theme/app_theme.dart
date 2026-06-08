import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Creates the application theme with Material 3 dark indigo scheme.
///
/// Uses Noto Sans SC for CJK text via google_fonts.
/// Typography follows UI-SPEC: body 14px w400, label 12px w500,
/// heading 20px w600, display 28px w700.
ThemeData appTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  );

  const disableGoogleFonts = bool.fromEnvironment(
    'MUSEFLOW_DISABLE_GOOGLE_FONTS',
  );
  final baseTextTheme = disableGoogleFonts
      ? Typography.material2021().white.apply(fontFamily: 'Noto Sans CJK SC')
      : GoogleFonts.notoSansScTextTheme();

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    textTheme: baseTextTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
  );
}

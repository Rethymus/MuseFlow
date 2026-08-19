/// MuseFlow theme — Apple Human Interface Guidelines on a Material base.
///
/// Rebuilt from scratch on the app's own token layer ([AppColors],
/// [AppTypography], [AppRadius]) instead of FlexColorScheme/Material tonal
/// palettes. The Material foundation stays (super_editor, fl_chart and the
/// widget tree rely on it), but every component theme is re-tuned to Apple
/// semantics:
///
/// - **Deference**: flat surfaces, hairline separators, content-forward.
///   Cards are inset-group white on grouped gray; elevation is near zero.
/// - **Clarity**: the Apple type scale (`buildTextTheme`) with the bundled
///   Noto Sans CJK SC; layered label colors instead of flat grays.
/// - **Depth**: Cupertino slide transitions, blurred chrome (sidebar, tab
///   bar, floating toolbar — built on these tokens in `shared/widgets`).
///
/// The public API is unchanged: `appTheme(brightness)` returns the paired
/// light/dark [ThemeData], so every existing `colorScheme.*` / `textTheme.*`
/// call site inherits the Apple palette without modification.
library;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_materials.dart' show appFocusTint;
import 'app_typography.dart';

/// Creates the application theme for either brightness.
ThemeData appTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? darkPalette : lightPalette;
  final isDark = brightness == Brightness.dark;
  final scheme = buildColorScheme(brightness);
  final textTheme = buildTextTheme(brightness);

  final buttonMinimum = const Size(44, 44);
  // Keyboard focus reads as an accent wash on every button family.
  final focusOverlay = WidgetStateProperty.resolveWith<Color>(
    (states) => states.contains(WidgetState.focused)
        ? appFocusTint(p)
        : Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: kAppFontFamily,
    textTheme: textTheme,
    scaffoldBackgroundColor: p.groupedBackground,
    // Apple controls have no ripple — taps dim briefly instead.
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
    // --- Chrome -----------------------------------------------------------
    appBarTheme: AppBarTheme(
      backgroundColor: p.groupedBackground,
      foregroundColor: p.label,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      titleTextStyle: textTheme.titleLarge,
      toolbarTextStyle: textTheme.titleMedium,
      iconTheme: IconThemeData(color: p.accent, size: 22),
      actionsIconTheme: IconThemeData(color: p.accent, size: 22),
      shape: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
    ),
    dividerTheme: DividerThemeData(
      color: p.separator,
      thickness: AppRadius.hairline,
      space: 16,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 56,
      backgroundColor: p.groupedBackground,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.accentFill,
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.small)),
      ),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelMedium?.copyWith(
          color: states.contains(WidgetState.selected)
              ? p.accent
              : p.secondaryLabel,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? p.accent
              : p.secondaryLabel,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.groupedBackground,
      elevation: 0,
      indicatorColor: p.accentFill,
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.small)),
      ),
      selectedIconTheme: IconThemeData(color: p.accent, size: 24),
      unselectedIconTheme: IconThemeData(color: p.secondaryLabel, size: 24),
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: p.accent,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: p.secondaryLabel,
      ),
      labelType: NavigationRailLabelType.all,
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: p.accent,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: p.accent,
      labelStyle: textTheme.titleMedium,
      unselectedLabelColor: p.secondaryLabel,
      unselectedLabelStyle: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w400,
      ),
      dividerColor: Colors.transparent,
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
    ),
    // --- Buttons ------------------------------------------------------------
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: p.quaternaryFill,
        disabledForegroundColor: p.tertiaryLabel,
        minimumSize: buttonMinimum,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ).copyWith(overlayColor: focusOverlay),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: p.quaternaryFill,
        disabledForegroundColor: p.tertiaryLabel,
        elevation: 0,
        minimumSize: buttonMinimum,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ).copyWith(overlayColor: focusOverlay),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        minimumSize: buttonMinimum,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ).copyWith(overlayColor: focusOverlay),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.label,
        side: BorderSide(color: p.gray4),
        minimumSize: buttonMinimum,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ).copyWith(overlayColor: focusOverlay),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: p.accent,
        minimumSize: buttonMinimum,
        shape: const StadiumBorder(),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: Colors.white,
      elevation: 1.5,
      focusElevation: 2,
      hoverElevation: 2,
      highlightElevation: 2,
      shape: const StadiumBorder(),
      extendedTextStyle: textTheme.labelLarge,
    ),
    // --- Surfaces -----------------------------------------------------------
    cardTheme: CardThemeData(
      color: p.cardBackground,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rMedium),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.secondaryGroupedBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rLarge),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.secondaryLabel),
      actionsPadding: const EdgeInsets.fromLTRB(0, 12, 16, 16),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.secondaryGroupedBackground,
      modalBackgroundColor: p.secondaryGroupedBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: p.gray3,
      dragHandleSize: const Size(36, 5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xLarge),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.tertiaryGroupedBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rMedium),
      textStyle: textTheme.bodyMedium,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium?.copyWith(color: p.secondaryLabel),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(p.tertiaryGroupedBackground),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(2),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: 0.25),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.rMedium),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: AppRadius.rSmall,
      ),
      textStyle: textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      waitDuration: const Duration(milliseconds: 500),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      actionTextColor: scheme.inversePrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rMedium),
    ),
    // --- Inputs & controls -----------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? p.gray5 : p.gray6,
      hintStyle: textTheme.bodyMedium?.copyWith(color: p.tertiaryLabel),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: AppRadius.rSmall,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.rSmall,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.rSmall,
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.rSmall,
        borderSide: BorderSide(color: p.systemRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.rSmall,
        borderSide: BorderSide(color: p.systemRed, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accentFill,
      selectionHandleColor: p.accent,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.gray5,
      side: BorderSide.none,
      labelStyle: textTheme.bodySmall,
      shape: const StadiumBorder(side: BorderSide(style: BorderStyle.none)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.accent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rSmall),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? p.systemGreen : p.gray4,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? p.accent
            : Colors.transparent,
      ),
      side: BorderSide(color: p.gray3, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small / 2),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.accent : p.gray,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.accent,
      inactiveTrackColor: p.gray5,
      thumbColor: Colors.white,
      overlayColor: p.accentFill,
      trackHeight: 4,
      valueIndicatorColor: scheme.inverseSurface,
      valueIndicatorTextStyle: textTheme.bodySmall?.copyWith(
        color: scheme.onInverseSurface,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.accent,
      linearTrackColor: p.gray5,
      circularTrackColor: p.gray5,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(2.5),
      radius: const Radius.circular(999),
      thumbColor: WidgetStatePropertyAll(p.separator),
      mainAxisMargin: 2,
    ),
  );
}

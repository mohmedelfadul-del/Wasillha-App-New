import 'package:flutter/material.dart';

/// Design tokens. ASSUMED values for the brief's [HEX]/[FONT] placeholders;
/// each is one edit away. Contrast checked for WCAG 2.2 AA:
///  white on action #6F00B8 = 8.9:1 · ink on surface = 19:1 · muted text = 5.3:1
///  white on success #146C43 ≥ 6:1 · white on error #B91C1C = 6.5:1
class WColors {
  const WColors._();
  static const brand = Color(0xFF9D00FF);
  static const action = Color(0xFF6F00B8);
  static const ink = Color(0xFF0A0908);
  static const surface = Color(0xFFFBFAF6);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFF6B6862);
  static const line = Color(0xFFE5E2DB);

  static const success = Color(0xFF146C43);
  static const successBg = Color(0xFFE3F3EA);
  static const error = Color(0xFFB91C1C);
  static const errorBg = Color(0xFFFDE8E8);
  static const warning = Color(0xFF8A5A00);
  static const warningBg = Color(0xFFFFF4DB);

  // Dark theme
  static const darkSurface = Color(0xFF121014);
  static const darkCard = Color(0xFF1C1A1F);
  static const darkInk = Color(0xFFEDEBE6);
  static const darkMuted = Color(0xFFA6A29A);
  static const darkAction = Color(0xFFC9A2FF); // with ink text
  static const darkLine = Color(0xFF2E2B33);
}

/// Map semantics — independent of the brand color (brief).
class MapColors {
  const MapColors._();
  static const route = Color(0xFF1A73E8);
  static const routeTraveled = Color(0xFF9AA0A6);
  static const pickup = Color(0xFF0F9D58);
  static const dropoff = Color(0xFFD93025);
  static const driver = Color(0xFF0A0908);
}

class WSpace {
  const WSpace._();
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;

  /// Minimum touch target (brief: ≥ 48 dp).
  static const touch = 48.0;

  /// Driver app primary actions are larger (used while parked).
  static const touchLarge = 64.0;
}

const _font = 'IBMPlexSansArabic';
const _pkg = 'wa3_core';

ThemeData wasilhaTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme(
    brightness: b,
    primary: dark ? WColors.darkAction : WColors.action,
    onPrimary: dark ? WColors.ink : Colors.white,
    secondary: WColors.brand,
    onSecondary: Colors.white,
    error: WColors.error,
    onError: Colors.white,
    surface: dark ? WColors.darkSurface : WColors.surface,
    onSurface: dark ? WColors.darkInk : WColors.ink,
    surfaceContainerHighest: dark ? WColors.darkCard : WColors.card,
    onSurfaceVariant: dark ? WColors.darkMuted : WColors.muted,
    outline: dark ? WColors.darkLine : WColors.line,
  );
  final text = Typography.material2021(platform: TargetPlatform.android).black.apply(
        fontFamily: 'packages/$_pkg/$_font',
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      );
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'packages/$_pkg/$_font',
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.5),
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerHighest,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outline)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(WSpace.touch, 56),
        textStyle: const TextStyle(fontFamily: 'packages/$_pkg/$_font', fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(WSpace.touch, 52),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(WSpace.touch, WSpace.touch))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.outline)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dividerTheme: DividerThemeData(color: scheme.outline, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Honors the OS "reduce motion" setting.
Duration motion(BuildContext context, Duration d) => MediaQuery.of(context).disableAnimations ? Duration.zero : d;

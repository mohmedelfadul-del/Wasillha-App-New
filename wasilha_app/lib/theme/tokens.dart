import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens ported from project/styles.css.
class W {
  W._();

  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFAFAFA);
  static const surface2 = Color(0xFFF5F4F1);
  static const surface3 = Color(0xFFEFEEEA);
  static const border = Color(0xFFE8E6E1);
  static const border2 = Color(0xFFDDDAD3);
  static const text = Color(0xFF0A0908);
  static const text2 = Color(0xFF6B6862);
  static const text3 = Color(0xFFA6A29A);
  static const paper = Color(0xFFECE8E0);
  static const ink = Color(0xFF1A1815);
  static const screenBg = Color(0xFFFBFAF6);
  static const success = Color(0xFF1F8A5B);
  static const danger = Color(0xFFE4572E);
  static const gold = Color(0xFFE4B73B);

  static const defaultAccent = Color(0xFF9D00FF);
  static const accentOptions = [
    Color(0xFF9D00FF),
    Color(0xFFE4572E),
    Color(0xFF1F8A5B),
    Color(0xFF2A6FDB),
    Color(0xFFE4B73B),
  ];

  static const rSm = 10.0;
  static const rMd = 16.0;
  static const rLg = 22.0;
  static const rXl = 28.0;

  static const cardShadow = [
    BoxShadow(color: Color(0x0F140F1E), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const softShadow = [
    BoxShadow(color: Color(0x14140F1E), blurRadius: 28, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A140F1E), blurRadius: 6, offset: Offset(0, 2)),
  ];

  // ── Typography ──────────────────────────────────────────────
  /// Geist — UI sans.
  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = text,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.geist(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing ?? -0.01 * size,
        height: height,
      );

  /// Instrument Serif italic — display headlines.
  static TextStyle serif({
    double size = 32,
    Color color = text,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.instrumentSerif(
        fontSize: size,
        fontStyle: FontStyle.italic,
        color: color,
        height: height ?? 1.0,
        letterSpacing: letterSpacing ?? -0.02 * size,
      );

  /// Geist Mono — tabular, uppercase micro-labels.
  static TextStyle mono({
    double size = 10,
    Color color = text3,
    double letterSpacing = 0.16,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.geistMono(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing * size,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// IBM Plex Sans Arabic.
  static TextStyle ar({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = text,
    double? height,
  }) =>
      GoogleFonts.ibmPlexSansArabic(
          fontSize: size, fontWeight: weight, color: color, height: height);

  /// Amiri — Arabic display.
  static TextStyle arSerif({double size = 28, Color color = text, double? height}) =>
      GoogleFonts.amiri(fontSize: size, color: color, height: height ?? 1.1);

  static ThemeData theme(Color accent, {bool arabic = false}) {
    final family = (arabic ? GoogleFonts.ibmPlexSansArabic() : GoogleFonts.geist()).fontFamily;
    return ThemeData(
      useMaterial3: true,
      fontFamily: family,
      colorScheme: ColorScheme.fromSeed(seedColor: accent, primary: accent, surface: bg),
      scaffoldBackgroundColor: screenBg,
      splashFactory: InkSparkle.splashFactory,
    );
  }
}

/// Hex helper used by the SVG icon renderer.
String colorHex(Color c) {
  final v = c.toARGB32();
  return '#${(v & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

/// Format Sudanese pound amounts: 1850 → "1,850".
String sdg(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Global notifier — toggled from the dashboard header
final appThemeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

// Legacy dark-only constants kept for pages that haven't been theme-ified yet
class NeoColors {
  static const Color background = Color(0xFF000000);
  static const Color cardBg = Color(0xFF0B0B0C);
  static const Color cardBorder = Color(0xFF1F1F23);
  static const Color accentGreen = Color(0xFF800000);
  static const Color accentGreenGlow = Color(0x33800000);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF4B5563);
  static const Color errorRed = Color(0xFFFF4D4D);
  static const Color warningOrange = Color(0xFFFFAD33);
}

// Theme-aware color palette — AppColors.of(context) returns the right set
class AppColors {
  final Color background;
  final Color cardBg;
  final Color cardBorder;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color errorRed;
  final Color surfaceAlt;

  const AppColors._({
    required this.background,
    required this.cardBg,
    required this.cardBorder,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.errorRed,
    required this.surfaceAlt,
  });

  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _dark : _light;
  }

  static const _dark = AppColors._(
    background: Color(0xFF000000),
    cardBg: Color(0xFF0B0B0C),
    cardBorder: Color(0xFF1F1F23),
    accent: Color(0xFF800000),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF9CA3AF),
    textMuted: Color(0xFF4B5563),
    errorRed: Color(0xFFFF4D4D),
    surfaceAlt: Color(0xFF1C1C1E),
  );

  static const _light = AppColors._(
    background: Color(0xFFF2F2F7),
    cardBg: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE5E5EA),
    accent: Color(0xFF800000),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF6E6E73),
    textMuted: Color(0xFFAEAEB2),
    errorRed: Color(0xFFFF3B30),
    surfaceAlt: Color(0xFFF0F0F2),
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NeoColors.background,
      cardColor: NeoColors.cardBg,
      primaryColor: NeoColors.accentGreen,
      colorScheme: const ColorScheme.dark(
        primary: NeoColors.accentGreen,
        background: NeoColors.background,
        surface: NeoColors.cardBg,
        onBackground: NeoColors.textPrimary,
        onSurface: NeoColors.textPrimary,
        error: NeoColors.errorRed,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.bold,
          color: NeoColors.textPrimary, letterSpacing: -1.0,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.bold,
          color: NeoColors.textPrimary, letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: NeoColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.normal, color: NeoColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: NeoColors.textSecondary),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: NeoColors.accentGreen,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    const bg = Color(0xFFF2F2F7);
    const textPri = Color(0xFF1C1C1E);
    const textSec = Color(0xFF6E6E73);
    const accent = NeoColors.accentGreen;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      cardColor: Colors.white,
      primaryColor: accent,
      colorScheme: const ColorScheme.light(
        primary: accent,
        background: bg,
        surface: Colors.white,
        onBackground: textPri,
        onSurface: textPri,
        error: Color(0xFFFF3B30),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.bold,
          color: textPri, letterSpacing: -1.0,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.bold,
          color: textPri, letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPri,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.normal, color: textPri,
        ),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSec),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: accent,
        ),
      ),
    );
  }
}

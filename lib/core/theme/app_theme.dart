import 'package:flutter/material.dart';
import 'package:luxury_app/core/theme/app_colors.dart';

/// Identidad visual Luxury: carbón, cacao, naranja tostado y marfil.
ThemeData buildLuxuryTheme() {
  const canvas = Color(0xFFF8F5F0);
  const border = Color(0xFFE9DED3);
  const ink = Color(0xFF211C1A);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: luxuryGold, brightness: Brightness.light,
      primary: luxuryBrown, onPrimary: Colors.white,
      secondary: luxuryGold, error: luxuryRed, surface: Colors.white,
    ),
    scaffoldBackgroundColor: canvas,
    dividerColor: border,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: ink, fontWeight: FontWeight.w900, letterSpacing: -.9),
      headlineMedium: TextStyle(color: ink, fontWeight: FontWeight.w800, letterSpacing: -.65),
      titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(color: ink, height: 1.35),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: canvas, foregroundColor: ink,
      elevation: 0, centerTitle: false, scrolledUnderElevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 20),
    ),
    cardTheme: CardThemeData(
      color: Colors.white, elevation: 0, margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: luxuryGold, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      backgroundColor: luxuryGold, foregroundColor: const Color(0xFF23150D),
      minimumSize: const Size(50, 49),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    )),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      foregroundColor: luxuryBrown,
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    )),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: luxuryGold.withValues(alpha: .16),
      selectedIconTheme: const IconThemeData(color: luxuryBrown),
      selectedLabelTextStyle: const TextStyle(color: luxuryBrown, fontWeight: FontWeight.w800),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: luxuryGold.withValues(alpha: .16),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF33251F),
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

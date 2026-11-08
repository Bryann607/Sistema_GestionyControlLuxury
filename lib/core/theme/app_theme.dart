import 'package:flutter/material.dart';

import 'package:luxury_app/core/theme/app_colors.dart';

ThemeData buildLuxuryTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: luxuryBrown,
    primary: luxuryBrown,
    secondary: luxuryGold,
    error: luxuryRed,
    surface: luxuryBone,
  ),
  scaffoldBackgroundColor: luxuryBone,
  dividerColor: const Color(0xFFEADBD0),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.5),
    titleLarge: TextStyle(fontWeight: FontWeight.w800),
    titleMedium: TextStyle(fontWeight: FontWeight.w700),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: luxuryBrown,
    foregroundColor: Colors.white,
    centerTitle: false,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(19),
      side: const BorderSide(color: Color(0xFFE8DED6)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE8DED6)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: luxuryGold,
      foregroundColor: const Color(0xFF241010),
      minimumSize: const Size(44, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
      ),
    ),
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Colors.white,
    selectedIconTheme: IconThemeData(color: luxuryBrown),
    selectedLabelTextStyle: TextStyle(
      color: luxuryBrown,
      fontWeight: FontWeight.w700,
    ),
  ),
);

// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary:   AppColors.primary,
      secondary: AppColors.secondary,
    ),
    scaffoldBackgroundColor: AppColors.bgSecondary,
    fontFamily: 'Inter',

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor:  AppColors.primary,
      foregroundColor:  Colors.white,
      elevation:        0,
      centerTitle:      true,
      titleTextStyle: TextStyle(
        fontFamily:  'Inter',
        fontSize:    18,
        fontWeight:  FontWeight.w600,
        color:       Colors.white,
      ),
    ),

    // Elevated button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize:     const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily:  'Inter',
          fontSize:    16,
          fontWeight:  FontWeight.w600,
        ),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled:      true,
      fillColor:   AppColors.bgPrimary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical:   14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      color:     AppColors.bgPrimary,
      elevation: 0,
      shape:     RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    ),
  );
}//combine colours, font, and border raduis in one flutter theme data object
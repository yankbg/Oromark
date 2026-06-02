import 'package:flutter/material.dart';

//every color OROmark uses
class AppColors {
  // Primary colors
  static const primary = Color(0xFF0F6E56);      // Teal
  static const secondary = Color(0xFFBA7517);    // Amber
  static const tertiary = Color(0xFF3A4D48);     //
  static const accent = Color(0xFF378ADD);       // Blue

  // Status colors
  static const success = Color(0xFF639922);      // Green (Present)
  static const warning = Color(0xFFBA7517);      // Orange (Late)
  static const error = Color(0xFFE24B4A);        // Red (Absent)

  // Background colors
  static const bgPrimary = Color(0xFFFFFFFF);    // White
  static const bgSecondary = Color(0xFFF9FAFB);  // Light gray
  static const bgTertiary = Color(0xFFF1F3F4);   // Lighter gray

  // Text colors
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);

  // Status badge backgrounds
  static const presentBg = Color(0xFFEAF3DE);
  static const presentText = Color(0xFF639922);
  static const lateBg = Color(0xFFFAEEDA);
  static const lateText = Color(0xFF854F0B);
  static const absentBg = Color(0xFFFCEBEB);
  static const absentText = Color(0xFFA32D2D);
  static const liveBg = Color(0xFFE6F1FB);
  static const liveText = Color(0xFF185FA5);
}
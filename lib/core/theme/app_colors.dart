import 'package:flutter/material.dart';

/// Color tokens defined in Phase 1's design system. Referenced by
/// [AppTheme] to build the light/dark `ThemeData`, and usable directly
/// wherever a widget needs a brand color that has no direct Material 3
/// role (e.g. rating stars, offer badges).
class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFFD4AF37); // Gold
  static const Color primaryDark = Color(0xFFB08D24);
  static const Color secondary = Color(0xFF111827); // Charcoal
  static const Color accent = Color(0xFF4C2A85); // Deep purple

  // Surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color surfaceDark = Color(0xFF1B1725);
  static const Color backgroundDark = Color(0xFF0F0D14);

  // Semantic
  static const Color success = Color(0xFF1E8E5A);
  static const Color error = Color(0xFFD64545);
  static const Color warning = Color(0xFFE6A23C);

  // Outlines / dividers
  static const Color outlineLight = Color(0xFFE5E7EB);
  static const Color outlineDark = Color(0xFF2E2A3A);

  // Text (light theme)
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Text (dark theme)
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Fixed-role colors (identical in both themes)
  static const Color ratingStar = Color(0xFFD4AF37);
  static const Color openStatus = success;
  static const Color closedStatus = error;
  static const Color verifiedBadge = accent;
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aina/core/theme/app_colors.dart';

/// Typography scale defined in Phase 1 ("Poppins", sizes/weights per the
/// design system table). Exposes both a light- and dark-theme variant of
/// each style since text color is theme-dependent.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // ---------------------------------------------------------------
  // Light theme
  // ---------------------------------------------------------------
  static TextStyle display(Color color) =>
      _base(fontSize: 32, fontWeight: FontWeight.w600, color: color, height: 1.2);

  static TextStyle h1(Color color) =>
      _base(fontSize: 24, fontWeight: FontWeight.w600, color: color, height: 1.25);

  static TextStyle h2(Color color) =>
      _base(fontSize: 20, fontWeight: FontWeight.w600, color: color, height: 1.3);

  static TextStyle h3(Color color) =>
      _base(fontSize: 16, fontWeight: FontWeight.w500, color: color, height: 1.35);

  static TextStyle bodyLarge(Color color) =>
      _base(fontSize: 15, fontWeight: FontWeight.w400, color: color, height: 1.5);

  static TextStyle body(Color color) =>
      _base(fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.5);

  static TextStyle caption(Color color) =>
      _base(fontSize: 12, fontWeight: FontWeight.w400, color: color, height: 1.4);

  static TextStyle button(Color color) => _base(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );

  // ---------------------------------------------------------------
  // Convenience: pre-bound to the standard light/dark primary text color.
  // Used as the default TextTheme; screens needing a different color
  // (e.g. text on a colored surface) call the raw methods above.
  // ---------------------------------------------------------------
  static TextTheme lightTextTheme() => TextTheme(
        displayLarge: display(AppColors.textPrimaryLight),
        headlineLarge: h1(AppColors.textPrimaryLight),
        headlineMedium: h2(AppColors.textPrimaryLight),
        titleMedium: h3(AppColors.textPrimaryLight),
        bodyLarge: bodyLarge(AppColors.textPrimaryLight),
        bodyMedium: body(AppColors.textPrimaryLight),
        bodySmall: caption(AppColors.textSecondaryLight),
        labelLarge: button(AppColors.textPrimaryLight),
      );

  static TextTheme darkTextTheme() => TextTheme(
        displayLarge: display(AppColors.textPrimaryDark),
        headlineLarge: h1(AppColors.textPrimaryDark),
        headlineMedium: h2(AppColors.textPrimaryDark),
        titleMedium: h3(AppColors.textPrimaryDark),
        bodyLarge: bodyLarge(AppColors.textPrimaryDark),
        bodyMedium: body(AppColors.textPrimaryDark),
        bodySmall: caption(AppColors.textSecondaryDark),
        labelLarge: button(AppColors.textPrimaryDark),
      );
}

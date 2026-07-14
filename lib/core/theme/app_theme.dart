import 'package:flutter/material.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/app_spacing.dart';
import 'package:aina/core/theme/app_text_styles.dart';

/// Assembles the light and dark [ThemeData] for the app from the tokens
/// in [AppColors], [AppTextStyles], and [AppSpacing]. This is the single
/// place that turns "design system" into "Flutter ThemeData" — screens
/// should always pull from `Theme.of(context)`, never hard-code a color
/// or text style inline.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.secondary,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.outlineLight,
    );

    return _base(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.backgroundLight,
      textTheme: AppTextStyles.lightTextTheme(),
      cardColor: AppColors.surfaceLight,
      dividerColor: AppColors.outlineLight,
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.secondary,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.outlineDark,
    );

    return _base(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.backgroundDark,
      textTheme: AppTextStyles.darkTextTheme(),
      cardColor: AppColors.surfaceDark,
      dividerColor: AppColors.outlineDark,
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required TextTheme textTheme,
    required Color cardColor,
    required Color dividerColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      cardColor: cardColor,
      dividerColor: dividerColor,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.headlineMedium,
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: dividerColor, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: AppTextStyles.button(colorScheme.onPrimary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: dividerColor),
          textStyle: AppTextStyles.button(colorScheme.onSurface),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: AppTextStyles.button(colorScheme.primary),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        hintStyle: AppTextStyles.body(colorScheme.onSurface.withValues(alpha: 0.5)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
        labelStyle: AppTextStyles.caption(colorScheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        shape: StadiumBorder(side: BorderSide(color: dividerColor)),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      dividerTheme: DividerThemeData(color: dividerColor, thickness: 1, space: 1),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.onSurface,
        contentTextStyle: AppTextStyles.body(scaffoldBackground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

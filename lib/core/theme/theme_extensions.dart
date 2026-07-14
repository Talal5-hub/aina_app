import 'package:flutter/material.dart';

/// Shorthand for pulling brightness-correct colors out of the active
/// [ThemeData] (built by [AppTheme]) instead of reaching for a specific
/// `AppColors.xLight`/`xDark` constant directly. Screens should use
/// these getters rather than hardcoding a light-only color, or dark
/// mode silently breaks (text/backgrounds stop responding to the
/// theme toggle even though it's set correctly).
extension ThemeColors on BuildContext {
  ThemeData get _theme => Theme.of(this);

  /// Scaffold/page background. Was `AppColors.backgroundLight`.
  Color get bgColor => _theme.scaffoldBackgroundColor;

  /// Card/surface background. Was `AppColors.surfaceLight`.
  Color get surfaceColor => _theme.cardColor;

  /// Primary text. Was `AppColors.textPrimaryLight`.
  Color get textPrimary => _theme.colorScheme.onSurface;

  /// Secondary/muted text. Was `AppColors.textSecondaryLight`.
  Color get textSecondary => _theme.colorScheme.onSurfaceVariant;

  /// Card/divider borders. Was `AppColors.outlineLight`.
  Color get outlineColor => _theme.colorScheme.outline;

  bool get isDarkMode => _theme.brightness == Brightness.dark;
}

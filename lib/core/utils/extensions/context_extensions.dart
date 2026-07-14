import 'package:flutter/material.dart';

/// Shorthand accessors used throughout the presentation layer so widgets
/// read `context.colors.primary` / `context.textTheme.h2` instead of the
/// more verbose `Theme.of(context).colorScheme.primary`.
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Shows a themed snackbar without repeating the ScaffoldMessenger
  /// boilerplate at every call site.
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colors.error : null,
        ),
      );
  }

  void hideKeyboard() => FocusScope.of(this).unfocus();
}

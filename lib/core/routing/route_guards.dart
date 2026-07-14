import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/services/supabase_service.dart';

/// Centralizes the "should this navigation be redirected?" decision so
/// [AppRouter]'s `redirect` callback stays a one-line delegate to this
/// class, and the actual auth rules are unit-testable in isolation.
class RouteGuards {
  const RouteGuards._();

  /// Paths reachable without an authenticated session.
  static const Set<String> _publicPaths = {
    RouteNames.splashPath,
    RouteNames.loginPath,
    RouteNames.signupPath,
    RouteNames.roleSelectionPath,
    RouteNames.forgotPasswordPath,
  };

  static bool isPublicPath(String path) {
    return _publicPaths.any((publicPath) => path == publicPath);
  }

  /// Returns the path to redirect to, or `null` to allow navigation to
  /// proceed as requested.
  ///
  /// [isPasswordRecovery] reflects whether the most recent Supabase auth
  /// event was `AuthChangeEvent.passwordRecovery` (the app was opened via
  /// the reset-password deep link). While true, every navigation attempt
  /// is redirected to the reset-password screen until the screen itself
  /// clears the flag after a successful password update — this prevents
  /// someone mid-recovery from wandering into the app with a recovery
  /// session instead of finishing the reset.
  static String? redirect(String currentPath, {bool isPasswordRecovery = false}) {
    if (isPasswordRecovery && currentPath != RouteNames.resetPasswordPath) {
      return RouteNames.resetPasswordPath;
    }

    if (currentPath == RouteNames.splashPath) {
      // Splash screen handles its own redirect once bootstrapping
      // (session restore, remote config, etc.) completes.
      return null;
    }

    if (currentPath == RouteNames.resetPasswordPath) {
      // Already where it needs to be; avoid fighting with the block above.
      return null;
    }

    final isAuthenticated = SupabaseService.isAuthenticated;
    final isGoingToPublicPath = isPublicPath(currentPath);

    if (!isAuthenticated && !isGoingToPublicPath) {
      return RouteNames.loginPath;
    }

    if (isAuthenticated && isGoingToPublicPath && currentPath != RouteNames.splashPath) {
      return RouteNames.homePath;
    }

    return null;
  }
}

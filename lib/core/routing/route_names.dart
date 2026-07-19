/// Centralized route paths and names for GoRouter.
///
/// Only the splash route is wired to a real screen in this phase — every
/// other path is declared here now (so route *names* are stable and
/// feature modules can reference them via `context.goNamed(...)` without
/// import cycles) and gets its actual `GoRoute`/screen added to
/// [AppRouter] in the phase that builds that feature:
///   auth        -> Phase 4
///   home/salon  -> Phase 5 / 6
///   search      -> Phase 7
///   favorites   -> Phase 8
///   profile     -> Phase 9
///   settings    -> Phase 10
class RouteNames {
  const RouteNames._();

  // Bootstrapping (implemented in this phase)
  static const String splash = 'splash';
  static const String splashPath = '/';

  // Auth (Phase 4)
  static const String login = 'login';
  static const String loginPath = '/login';
  static const String signup = 'signup';
  static const String signupPath = '/signup';
  static const String roleSelection = 'roleSelection';
  static const String roleSelectionPath = '/role-selection';
  static const String forgotPassword = 'forgotPassword';
  static const String forgotPasswordPath = '/forgot-password';

  /// Landing screen for the Supabase password-recovery deep link.
  /// Not in [RouteGuards]'s public-path allow list on purpose — reaching
  /// it is gated by an active recovery session/event, not by being
  /// logged-out, so it needs its own redirect rule rather than treating
  /// it like login/signup.
  static const String resetPassword = 'resetPassword';
  static const String resetPasswordPath = '/reset-password';

  // Shell / Home (Phase 5)
  static const String home = 'home';
  static const String homePath = '/home';

  // Salon (Phase 6)
  static const String salonDetails = 'salonDetails';
  static const String salonDetailsPath = '/salon/:salonId';

  // Booking (Phase 6b)
  static const String booking = 'booking';
  static const String bookingPath = '/salon/:salonId/book/:serviceId';
  static const String myBookings = 'myBookings';
  static const String myBookingsPath = '/my-bookings';

  // Search (Phase 7)
  static const String search = 'search';
  static const String searchPath = '/search';

  // Favorites (Phase 8)
  static const String favorites = 'favorites';
  static const String favoritesPath = '/favorites';

  // Profile (Phase 9)
  static const String profile = 'profile';
  static const String profilePath = '/profile';

  // Settings (Phase 10)
  static const String settings = 'settings';
  static const String settingsPath = '/settings';

  // Salon owner features
  static const String myBusiness = 'myBusiness';
  static const String myBusinessPath = '/my-business';
  static const String salonManagement = 'salonManagement';
  static const String salonManagementPath = '/my-business/:salonId';
  static const String claimSalon = 'claimSalon';
  static const String claimSalonPath = '/find-my-salon';
  static const String createSalon = 'createSalon';
  static const String createSalonPath = '/register-my-salon';
}

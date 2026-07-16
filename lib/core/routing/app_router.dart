import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aina/core/routing/app_splash_screen.dart';
import 'package:aina/core/routing/route_guards.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/services/supabase_service.dart';
import 'package:aina/features/auth/presentation/screens/login_screen.dart';
import 'package:aina/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:aina/features/auth/presentation/screens/signup_screen.dart';
import 'package:aina/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:aina/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:aina/features/auth/providers/auth_providers.dart';
import 'package:aina/features/home/presentation/screens/role_gate.dart';
import 'package:aina/features/salon/presentation/screens/salon_details_screen.dart';
import 'package:aina/features/booking/presentation/screens/booking_screen.dart';
import 'package:aina/features/booking/presentation/screens/my_bookings_screen.dart';
import 'package:aina/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:aina/features/owner/presentation/screens/claim_salon_screen.dart';
import 'package:aina/features/owner/presentation/screens/my_business_screen.dart';
import 'package:aina/features/owner/presentation/screens/salon_management_screen.dart';
import 'package:aina/features/profile/presentation/screens/profile_screen.dart';
import 'package:aina/features/search/presentation/screens/search_screen.dart';
import 'package:aina/features/settings/presentation/screens/settings_screen.dart';

/// Bridges a `Stream` (Supabase's auth state stream) to a `Listenable`,
/// which is what GoRouter's `refreshListenable` expects. Without this,
/// signing out wouldn't re-trigger the `redirect` callback until the
/// next manual navigation.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provided once at the app root; feature modules append their own
/// `GoRoute`s to the `routes` list below as each phase builds them,
/// rather than each feature owning a separate router instance.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = GoRouterRefreshStream(SupabaseService.onAuthStateChange);
  ref.onDispose(refreshListenable.dispose);

  // Separate subscription (independent of the refresh-triggering one
  // above) purely to flag when the app was opened via the password
  // recovery deep link. RouteGuards reads this flag on every redirect
  // check and force-routes to /reset-password until that screen clears it.
  final recoverySubscription = SupabaseService.onAuthStateChange.listen((state) {
    if (state.event == AuthChangeEvent.passwordRecovery) {
      ref.read(passwordRecoveryProvider.notifier).state = true;
    }
  });
  ref.onDispose(recoverySubscription.cancel);

  return GoRouter(
    initialLocation: RouteNames.splashPath,
    debugLogDiagnostics: true,
    refreshListenable: refreshListenable,
    redirect: (context, state) => RouteGuards.redirect(
      state.matchedLocation,
      isPasswordRecovery: ref.read(passwordRecoveryProvider),
    ),
    routes: [
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splash,
        builder: (context, state) => const AppSplashScreen(),
      ),

      // -----------------------------------------------------------
      // Phase 4: Auth
      // -----------------------------------------------------------
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.roleSelectionPath,
        name: RouteNames.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.signupPath,
        name: RouteNames.signup,
        // Defaults to 'customer' if reached without a role (e.g. a
        // stale deep link) rather than crashing on a null cast.
        builder: (context, state) => SignupScreen(role: (state.extra as String?) ?? 'customer'),
      ),
      GoRoute(
        path: RouteNames.forgotPasswordPath,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.resetPasswordPath,
        name: RouteNames.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // -----------------------------------------------------------
      // Phase 5: Home
      // -----------------------------------------------------------
      GoRoute(
        path: RouteNames.homePath,
        name: RouteNames.home,
        builder: (context, state) => const RoleGate(),
      ),

      // -----------------------------------------------------------
      // Phase 6: Salon details
      // -----------------------------------------------------------
      GoRoute(
        path: RouteNames.salonDetailsPath,
        name: RouteNames.salonDetails,
        builder: (context, state) => SalonDetailsScreen(
          salonId: state.pathParameters['salonId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.bookingPath,
        name: RouteNames.booking,
        builder: (context, state) => BookingScreen(
          salonId: state.pathParameters['salonId']!,
          args: state.extra as BookingScreenArgs?,
        ),
      ),
      GoRoute(
        path: RouteNames.myBookingsPath,
        name: RouteNames.myBookings,
        builder: (context, state) => const MyBookingsScreen(),
      ),

      GoRoute(
        path: RouteNames.searchPath,
        name: RouteNames.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: RouteNames.favoritesPath,
        name: RouteNames.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: RouteNames.profilePath,
        name: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.settingsPath,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.myBusinessPath,
        name: RouteNames.myBusiness,
        builder: (context, state) => const MyBusinessScreen(),
      ),
      GoRoute(
        path: RouteNames.claimSalonPath,
        name: RouteNames.claimSalon,
        builder: (context, state) => const ClaimSalonScreen(),
      ),
      GoRoute(
        path: RouteNames.salonManagementPath,
        name: RouteNames.salonManagement,
        builder: (context, state) => SalonManagementScreen(
          salonId: state.pathParameters['salonId']!,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Route "${state.matchedLocation}" isn\'t available yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'This screen is built in a later development phase.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

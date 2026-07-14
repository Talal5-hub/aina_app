import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:aina/core/constants/asset_paths.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/services/supabase_service.dart';
import 'package:aina/core/theme/app_colors.dart';

/// The app's single bootstrapping screen. By the time this widget builds,
/// `main_*.dart` has already awaited Supabase/Hive/SharedPreferences
/// initialization — this screen's only remaining job is a short branded
/// pause (so the logo doesn't flash for 40ms) before routing to the
/// correct destination based on session state.
///
/// The destination routes (`/login`, `/home`) are registered starting in
/// Phase 4 and Phase 5 respectively; until then, navigating past this
/// screen will hit [AppRouter]'s error builder, which is expected at
/// this stage of module-by-module development.
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen> {
  static const _minimumDisplayDuration = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final stopwatch = Stopwatch()..start();

    // Supabase's own persisted-session restore already ran during
    // `SupabaseService.initialize()` in main_*.dart, so checking
    // `isAuthenticated` here reflects the restored session, not a
    // network round-trip.
    final isAuthenticated = SupabaseService.isAuthenticated;

    final elapsed = stopwatch.elapsed;
    if (elapsed < _minimumDisplayDuration) {
      await Future.delayed(_minimumDisplayDuration - elapsed);
    }

    if (!mounted) return;

    context.go(isAuthenticated ? RouteNames.homePath : RouteNames.loginPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Center(
        child: SvgPicture.asset(
          AssetPaths.logoMark,
          width: 96,
          height: 96,
          colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
        ),
      ),
    );
  }
}

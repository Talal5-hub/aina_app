import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/home/presentation/screens/home_screen.dart';
import 'package:aina/features/owner/presentation/screens/my_business_screen.dart';
import 'package:aina/features/owner/providers/owner_providers.dart';
import 'package:aina/features/profile/providers/profile_providers.dart';

/// Sits at the `/home` route and decides what "home" actually means for
/// this account:
///  - customer role -> the normal salon-browsing HomeScreen
///  - owner role, no claimed salon yet -> also HomeScreen, so they can
///    find their listing and tap "Claim it" on its details page
///  - owner role, already owns a salon -> straight to MyBusinessScreen,
///    skipping the customer browsing experience entirely
///
/// This intentionally does NOT block an owner from ever reaching
/// HomeScreen (e.g. via deep link or back navigation) - only the
/// landing decision is role-aware. Blocking it outright would trap a
/// brand-new owner account with nothing to manage yet and no way to
/// find their listing.
class RoleGate extends ConsumerWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (!profile.isOwner) return const HomeScreen();

        final ownedSalonsAsync = ref.watch(myOwnedSalonsProvider);
        return ownedSalonsAsync.when(
          data: (salons) => salons.isEmpty ? const HomeScreen() : const MyBusinessScreen(),
          loading: () => Scaffold(
            backgroundColor: context.bgColor,
            body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          // If we can't tell whether they own a salon, fail open to the
          // normal browsing screen rather than a blank/stuck loading state.
          error: (e, _) => const HomeScreen(),
        );
      },
      loading: () => Scaffold(
        backgroundColor: context.bgColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => const HomeScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/home/presentation/screens/home_screen.dart';
import 'package:aina/features/owner/presentation/screens/my_business_screen.dart';
import 'package:aina/features/profile/providers/profile_providers.dart';

/// Sits at the `/home` route and decides what "home" actually means for
/// this account:
///  - customer role -> the normal salon-browsing HomeScreen
///  - owner role -> always MyBusinessScreen, whether or not they've
///    claimed a salon yet. An owner never sees the customer browsing
///    experience (search/favorites/booking-as-customer) - if they
///    haven't claimed a salon yet, MyBusinessScreen's empty state sends
///    them to the owner-only ClaimSalonScreen to find their listing,
///    not to the full customer app.
class RoleGate extends ConsumerWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return profileAsync.when(
      data: (profile) => profile.isOwner ? const MyBusinessScreen() : const HomeScreen(),
      loading: () => Scaffold(
        backgroundColor: context.bgColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      // If we can't tell the role, fail open to the customer screen
      // rather than a blank/stuck loading state.
      error: (e, _) => const HomeScreen(),
    );
  }
}

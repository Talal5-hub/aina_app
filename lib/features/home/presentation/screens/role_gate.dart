import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/core/view_mode/active_view_provider.dart';
import 'package:aina/features/home/presentation/screens/home_screen.dart';
import 'package:aina/features/owner/presentation/screens/my_business_screen.dart';

/// Sits at the `/home` route and shows whichever experience
/// [activeViewProvider] currently points to - Customer (browse/book) or
/// Business (manage a claimed/registered salon). Anyone can switch
/// between the two at any time (see the switcher in HomeScreen's and
/// MyBusinessScreen's AppBars, and in ProfileScreen).
///
/// The value itself lives server-side on `profiles.active_view`, so it
/// stays in sync across devices. Claiming or creating a salon
/// auto-switches it to 'business' server-side (see claim_salon /
/// create_owner_salon), which is what gives a brand-new owner a
/// sensible first landing screen without any special-casing here.
class RoleGate extends ConsumerWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeViewAsync = ref.watch(activeViewProvider);

    return activeViewAsync.when(
      data: (view) => view == ActiveView.business ? const MyBusinessScreen() : const HomeScreen(),
      loading: () => Scaffold(
        backgroundColor: context.bgColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      // Fail open to the customer screen rather than a stuck loading
      // state if the profile fetch that backs this fails.
      error: (e, _) => const HomeScreen(),
    );
  }
}

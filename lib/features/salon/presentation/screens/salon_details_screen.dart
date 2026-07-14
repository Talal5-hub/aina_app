import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/booking/presentation/screens/booking_screen.dart';
import 'package:aina/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:aina/features/owner/providers/owner_providers.dart';
import 'package:aina/features/profile/providers/profile_providers.dart';
import 'package:aina/features/salon/data/models/salon.dart';
import 'package:aina/features/salon/data/models/service.dart';
import 'package:aina/features/salon/presentation/widgets/salon_cover_image.dart';
import 'package:aina/features/salon/providers/salon_providers.dart';

class SalonDetailsScreen extends ConsumerWidget {
  final String salonId;

  const SalonDetailsScreen({super.key, required this.salonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonAsync = ref.watch(salonDetailsProvider(salonId));

    return Scaffold(
      backgroundColor: context.bgColor,
      body: salonAsync.when(
        data: (salon) => _SalonDetailsContent(salon: salon),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(backgroundColor: context.bgColor, elevation: 0),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    "Couldn't load this salon",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(salonDetailsProvider(salonId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SalonDetailsContent extends ConsumerWidget {
  final Salon salon;

  const _SalonDetailsContent({required this.salon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(salonServicesProvider(salon.id));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: AppColors.secondary,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FavoriteButton(salonId: salon.id, size: 22),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: SalonCoverImage(
              name: salon.name,
              imageUrl: salon.coverImageUrl,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        salon.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    if (salon.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.verified, color: AppColors.accent),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (!salon.isClaimed) _ClaimBanner(salon: salon),
                if (!salon.isClaimed) const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: AppColors.ratingStar),
                    const SizedBox(width: 4),
                    Text(
                      salon.ratingCount > 0
                          ? '${salon.ratingAvg.toStringAsFixed(1)} (${salon.ratingCount} reviews)'
                          : 'No ratings yet',
                      style: TextStyle(color: context.textSecondary),
                    ),
                  ],
                ),

                if (salon.address != null || salon.city != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 18, color: context.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [salon.address, salon.city].where((e) => e != null).join(', '),
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],

                if (salon.phone != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 18, color: context.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        salon.phone!,
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ],
                  ),
                ],

                if (salon.description != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    salon.description!,
                    style: TextStyle(color: context.textSecondary, height: 1.4),
                  ),
                ],

                const SizedBox(height: 24),
                Text(
                  'Services',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        servicesAsync.when(
          data: (services) => services.isEmpty
              ? SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'No services listed yet.',
                style: TextStyle(color: context.textSecondary),
              ),
            ),
          )
              : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: services.length,
              separatorBuilder: (_, __) => Divider(
                height: 24,
                color: context.outlineColor,
              ),
              itemBuilder: (context, index) => _ServiceRow(
                salon: salon,
                service: services[index],
              ),
            ),
          ),
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
          error: (error, _) {
            // Debug-only: surfaces the real Postgrest/RLS error in the
            // console instead of only ever showing the generic message
            // below, so issues like a missing SELECT policy are visible
            // immediately rather than looking like "no services exist".
            assert(() {
              debugPrint('salonServicesProvider(${salon.id}) failed: $error');
              return true;
            }());
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Couldn't load services.",
                  style: TextStyle(color: context.textSecondary),
                ),
              ),
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final Salon salon;
  final Service service;

  const _ServiceRow({required this.salon, required this.service});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed(
        RouteNames.booking,
        pathParameters: {'salonId': salon.id, 'serviceId': service.id},
        extra: BookingScreenArgs(service: service, salonName: salon.name),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.durationMinutes} min',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
                if (service.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    service.description!,
                    style: TextStyle(fontSize: 13, color: context.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs ${service.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Icon(Icons.chevron_right, size: 18, color: context.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown on salons imported from Google Maps that haven't been claimed
/// by a real owner yet. Lets any signed-in user claim it as their own
/// business - the server (`claim_salon`) re-checks it's still unclaimed
/// before assigning ownership, so this is safe even if two people tap
/// claim around the same time.
class _ClaimBanner extends ConsumerStatefulWidget {
  const _ClaimBanner({required this.salon});

  final Salon salon;

  @override
  ConsumerState<_ClaimBanner> createState() => _ClaimBannerState();
}

class _ClaimBannerState extends ConsumerState<_ClaimBanner> {
  bool _isClaiming = false;

  Future<void> _confirmClaim() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim this business?'),
        content: Text(
          "This will list ${widget.salon.name} under your account, so you can manage its "
          "services and bookings. Only do this if it's actually your business.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, this is mine'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isClaiming = true);

    try {
      await ref.read(ownerRepositoryProvider).claimSalon(widget.salon.id);
      if (!mounted) return;
      ref.invalidate(salonDetailsProvider(widget.salon.id));
      ref.invalidate(myOwnedSalonsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're now the owner of this listing.")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isClaiming = false);
      final message = e.toString().contains('already been claimed')
          ? 'This salon was just claimed by someone else.'
          : "Couldn't claim this business. Please try again.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwnerAccount = ref.watch(myProfileProvider).valueOrNull?.isOwner ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, color: AppColors.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unclaimed listing',
                  style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary, fontSize: 13),
                ),
                Text(
                  isOwnerAccount ? 'Is this your salon?' : 'Not yet claimed by its owner.',
                  style: TextStyle(color: context.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          if (isOwnerAccount)
            TextButton(
              onPressed: _isClaiming ? null : _confirmClaim,
              child: _isClaiming
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Claim it'),
            ),
        ],
      ),
    );
  }
}

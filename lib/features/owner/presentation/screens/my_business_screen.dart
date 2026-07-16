import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/owner/providers/owner_providers.dart';
import 'package:aina/features/salon/data/models/salon.dart';
import 'package:aina/features/salon/presentation/widgets/salon_cover_image.dart';

class MyBusinessScreen extends ConsumerWidget {
  const MyBusinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownedSalonsAsync = ref.watch(myOwnedSalonsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text(
          'My Business',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, color: context.textSecondary),
            tooltip: 'Profile',
            onPressed: () => context.pushNamed(RouteNames.profile),
          ),
        ],
      ),
      body: ownedSalonsAsync.when(
        data: (salons) {
          if (salons.isEmpty) {
            return _EmptyState(onBrowse: () => context.pushNamed(RouteNames.claimSalon));
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(myOwnedSalonsProvider),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: salons.length,
              itemBuilder: (context, index) => _OwnedSalonCard(salon: salons[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text("Couldn't load your businesses.",
                    style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(myOwnedSalonsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnedSalonCard extends StatelessWidget {
  const _OwnedSalonCard({required this.salon});

  final Salon salon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.outlineColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.salonManagement,
          pathParameters: {'salonId': salon.id},
        ),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: SalonCoverImage(name: salon.name, imageUrl: salon.coverImageUrl),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      salon.name,
                      style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      salon.area ?? salon.city ?? '',
                      style: TextStyle(color: context.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.accent),
                        const SizedBox(width: 2),
                        const Text(
                          'Manage bookings & services',
                          style: TextStyle(color: AppColors.accent, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 64, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              "You don't own a listed business yet",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              "Find your salon in the app and tap \"Claim it\" on its page to start "
              "managing its services and bookings.",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onBrowse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: const Text('Find my salon', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

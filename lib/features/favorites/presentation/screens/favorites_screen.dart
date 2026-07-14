import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:aina/core/constants/asset_paths.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:aina/features/favorites/providers/favorites_providers.dart';
import 'package:aina/features/salon/data/models/salon.dart';
import 'package:aina/features/salon/presentation/widgets/salon_cover_image.dart';
import 'package:aina/features/salon/providers/salon_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final salonsAsync = ref.watch(salonListProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text(
          'Favorites',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
        ),
      ),
      body: favoritesAsync.when(
        data: (favoriteIds) => salonsAsync.when(
          data: (allSalons) {
            final favorites =
                allSalons.where((s) => favoriteIds.contains(s.id)).toList();

            if (favorites.isEmpty) {
              return _EmptyState(onBrowse: () => context.goNamed(RouteNames.home));
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(favoritesProvider),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                itemBuilder: (context, index) => _FavoriteCard(salon: favorites[index]),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(salonListProvider)),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(favoritesProvider)),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.salon});

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
          RouteNames.salonDetails,
          pathParameters: {'salonId': salon.id},
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                children: [
                  SalonCoverImage(name: salon.name, imageUrl: salon.coverImageUrl),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: FavoriteButton(salonId: salon.id, size: 16),
                  ),
                ],
              ),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.ratingStar),
                        const SizedBox(width: 4),
                        Text(
                          '${salon.ratingAvg.toStringAsFixed(1)} (${salon.ratingCount})',
                          style: TextStyle(color: context.textSecondary, fontSize: 12.5),
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
            SvgPicture.asset(AssetPaths.emptyStateFavorites, width: 160, height: 160),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the heart on any salon to save it here.',
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
              child: const Text('Browse salons', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(AssetPaths.errorStateOffline, width: 160, height: 160),
            const SizedBox(height: 16),
            Text(
              "Couldn't load favorites",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: context.textPrimary),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.textPrimary,
                side: BorderSide(color: context.outlineColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

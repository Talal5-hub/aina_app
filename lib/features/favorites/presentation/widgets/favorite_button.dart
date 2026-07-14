import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/features/favorites/providers/favorites_providers.dart';

/// A tappable heart icon reflecting and toggling whether [salonId] is in
/// the current user's favorites. Sits on a translucent circular
/// backdrop so it reads clearly over any cover photo.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.salonId, this.size = 20});

  final String salonId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final isFavorited = favoritesAsync.valueOrNull?.contains(salonId) ?? false;

    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          try {
            await ref.read(favoritesProvider.notifier).toggle(salonId);
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Couldn't update favorites. Please try again."),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFavorited ? Icons.favorite : Icons.favorite_border,
            color: isFavorited ? AppColors.error : Colors.white,
            size: size,
          ),
        ),
      ),
    );
  }
}

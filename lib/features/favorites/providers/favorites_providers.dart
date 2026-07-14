import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina/features/favorites/data/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return const FavoritesRepository();
});

/// Holds the current user's favorite salon IDs as an in-memory set,
/// updated optimistically so the heart icon toggles instantly instead
/// of waiting on a round trip. On failure the change is rolled back and
/// the error rethrown so the caller (the heart button) can show a
/// SnackBar.
class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.watch(favoritesRepositoryProvider).fetchFavoriteSalonIds();
  }

  Future<void> toggle(String salonId) async {
    final current = state.valueOrNull ?? <String>{};
    final isFavorited = current.contains(salonId);

    final optimistic = Set<String>.from(current);
    if (isFavorited) {
      optimistic.remove(salonId);
    } else {
      optimistic.add(salonId);
    }
    state = AsyncData(optimistic);

    try {
      final repo = ref.read(favoritesRepositoryProvider);
      if (isFavorited) {
        await repo.removeFavorite(salonId);
      } else {
        await repo.addFavorite(salonId);
      }
    } catch (e) {
      // Roll back on failure.
      state = AsyncData(current);
      rethrow;
    }
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

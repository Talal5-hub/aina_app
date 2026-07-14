import 'package:aina/core/constants/app_constants.dart';
import 'package:aina/core/services/supabase_service.dart';

/// Favorites are stored server-side (per user, syncs across devices) in
/// the `favorites` table — see AppConstants.tableFavorites. The table
/// keys off `customer_id`, matching the same convention as `bookings`,
/// not `user_id`. Supabase is the source of truth; [FavoritesNotifier]
/// layers a small in-memory optimistic update on top so the heart icon
/// responds instantly.
class FavoritesRepository {
  const FavoritesRepository();

  Future<Set<String>> fetchFavoriteSalonIds() async {
    final customerId = SupabaseService.currentUser!.id;

    final response = await SupabaseService.client
        .from(AppConstants.tableFavorites)
        .select('salon_id')
        .eq('customer_id', customerId);

    return (response as List)
        .map((row) => (row as Map<String, dynamic>)['salon_id'] as String)
        .toSet();
  }

  Future<void> addFavorite(String salonId) async {
    final customerId = SupabaseService.currentUser!.id;

    await SupabaseService.client.from(AppConstants.tableFavorites).upsert(
      {'customer_id': customerId, 'salon_id': salonId},
      onConflict: 'customer_id,salon_id',
    );
  }

  Future<void> removeFavorite(String salonId) async {
    final customerId = SupabaseService.currentUser!.id;

    await SupabaseService.client
        .from(AppConstants.tableFavorites)
        .delete()
        .eq('customer_id', customerId)
        .eq('salon_id', salonId);
  }
}
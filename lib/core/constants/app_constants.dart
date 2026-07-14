/// Hive box names, shared preference keys, and other string constants that
/// must stay identical across the whole app (typos here cause silent data
/// loss, so they're centralized rather than inlined at call sites).
class AppConstants {
  const AppConstants._();

  // Hive box names
  static const String favoritesBoxName = 'favorites_box';
  static const String searchHistoryBoxName = 'search_history_box';
  static const String cachedSalonsBoxName = 'cached_salons_box';

  // SharedPreferences keys
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefLocale = 'pref_locale';
  static const String prefHasSeenOnboarding = 'pref_has_seen_onboarding';
  static const String prefLastKnownLat = 'pref_last_known_lat';
  static const String prefLastKnownLng = 'pref_last_known_lng';

  // Secure storage keys
  static const String secureKeySupabaseSession = 'secure_supabase_session';

  // Supabase table names (kept as constants to avoid typo'd string
  // literals scattered across every repository)
  static const String tableUsers = 'users';
  static const String tableSalons = 'salons';
  static const String tableServices = 'services';
  static const String tableCategories = 'categories';
  static const String tableCities = 'cities';
  static const String tableAreas = 'areas';
  static const String tableReviews = 'reviews';
  static const String tableFavorites = 'favorites';
  static const String tableOffers = 'offers';
  static const String tableGalleryImages = 'gallery_images';
  static const String tableFacilityTypes = 'facility_types';
  static const String tableSalonFacilities = 'salon_facilities';
  static const String tableNotifications = 'notifications';
  static const String tableAppointmentRequests = 'appointment_requests';

  // Supabase storage bucket names
  static const String bucketAvatars = 'avatars';
  static const String bucketSalons = 'salons';
  static const String bucketGallery = 'gallery';
  static const String bucketServices = 'services';
  static const String bucketBanners = 'banners';

  // Supabase RPC names
  static const String rpcNearbySalons = 'nearby_salons';
}

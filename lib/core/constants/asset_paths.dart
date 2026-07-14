/// Centralized asset paths so a moved/renamed file is a one-line fix
/// instead of a project-wide find-and-replace.
class AssetPaths {
  const AssetPaths._();

  static const String _imagesBase = 'assets/images';
  static const String _iconsBase = 'assets/icons';
  static const String _lottieBase = 'assets/lottie';

  // Branding
  static const String logoMark = '$_iconsBase/aina_logo_mark.svg';
  static const String logoWordmark = '$_iconsBase/aina_logo_wordmark.svg';
  static const String appIconPng = '$_imagesBase/app_icon.png';

  // Onboarding / empty states
  static const String onboardingDiscover = '$_imagesBase/onboarding_discover.svg';
  static const String onboardingBook = '$_imagesBase/onboarding_book.svg';
  static const String onboardingFavorites = '$_imagesBase/onboarding_favorites.svg';
  static const String emptyStateGeneric = '$_imagesBase/empty_state_generic.svg';
  static const String emptyStateFavorites = '$_imagesBase/empty_state_favorites.svg';
  static const String emptyStateSearch = '$_imagesBase/empty_state_search.svg';
  static const String errorStateOffline = '$_imagesBase/error_state_offline.svg';

  // Lottie animations
  static const String lottieSplashLoading = '$_lottieBase/splash_loading.json';
  static const String lottieBookingSuccess = '$_lottieBase/booking_success.json';

  // Placeholders (used by CachedNetworkImage while remote images load,
  // and as fallbacks on load failure — not "coming soon" content, purely
  // visual placeholders for async image loading)
  static const String placeholderSalonImage = '$_imagesBase/placeholder_salon.png';
  static const String placeholderAvatar = '$_imagesBase/placeholder_avatar.png';
}

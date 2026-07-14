import 'package:shared_preferences/shared_preferences.dart';
import 'package:aina/core/constants/app_constants.dart';

/// Wraps `SharedPreferences` for simple, non-sensitive local settings:
/// theme mode, locale, onboarding-seen flag, and last known coordinates
/// (used to render a map instantly before a fresh GPS fix arrives).
class SharedPrefsService {
  SharedPrefsService(this._prefs);

  final SharedPreferences _prefs;

  // Theme
  String? get themeMode => _prefs.getString(AppConstants.prefThemeMode);
  Future<void> setThemeMode(String mode) => _prefs.setString(AppConstants.prefThemeMode, mode);

  // Locale
  String? get locale => _prefs.getString(AppConstants.prefLocale);
  Future<void> setLocale(String localeCode) =>
      _prefs.setString(AppConstants.prefLocale, localeCode);

  // Onboarding
  bool get hasSeenOnboarding => _prefs.getBool(AppConstants.prefHasSeenOnboarding) ?? false;
  Future<void> setHasSeenOnboarding(bool value) =>
      _prefs.setBool(AppConstants.prefHasSeenOnboarding, value);

  // Last known location (fallback while awaiting a fresh GPS fix)
  double? get lastKnownLat => _prefs.getDouble(AppConstants.prefLastKnownLat);
  double? get lastKnownLng => _prefs.getDouble(AppConstants.prefLastKnownLng);

  Future<void> setLastKnownLocation(double lat, double lng) async {
    await _prefs.setDouble(AppConstants.prefLastKnownLat, lat);
    await _prefs.setDouble(AppConstants.prefLastKnownLng, lng);
  }

  Future<void> clearAll() => _prefs.clear();
}

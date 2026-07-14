/// Static, non-secret configuration values used across the app.
///
/// Anything sensitive belongs in [Env] (dart-define), not here.
class AppConfig {
  const AppConfig._();

  static const String appName = 'Aina';
  static const String supportEmail = 'support@aina.pk';
  static const String supportWhatsapp = '+923001234567';

  /// Default map camera radius (km) used for "nearby" queries when the
  /// user hasn't set a custom search radius.
  static const double defaultSearchRadiusKm = 10.0;
  static const double maxSearchRadiusKm = 50.0;

  /// Pagination defaults — kept centralized so every repository/list
  /// screen paginates consistently.
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  /// Network timeouts.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Cache TTLs.
  static const Duration salonListCacheTtl = Duration(minutes: 5);
  static const Duration staticDataCacheTtl = Duration(hours: 12);

  static const List<String> supportedLocales = ['en', 'ur'];
  static const String defaultLocale = 'en';
}

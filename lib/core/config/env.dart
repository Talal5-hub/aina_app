/// The three deployable environments for the Aina app.
///
/// Selected at build/run time via `--dart-define=ENVIRONMENT=...` and wired
/// up by the `main_development.dart` / `main_staging.dart` /
/// `main_prod.dart` entrypoints.
enum Environment {
  development,
  staging,
  production;

  static Environment fromString(String value) {
    switch (value.toLowerCase()) {
      case 'staging':
        return Environment.staging;
      case 'production':
        return Environment.production;
      case 'development':
      default:
        return Environment.development;
    }
  }

  bool get isProduction => this == Environment.production;
  bool get isDevelopment => this == Environment.development;
  bool get isStaging => this == Environment.staging;
}

/// Thin wrapper around compile-time `--dart-define` values.
///
/// Every secret (Supabase URL/anon key, Maps API key, etc.) must be supplied
/// via `--dart-define-from-file=env/<flavor>.json` at build time — never
/// hard-coded and never committed to source control.
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String googleMapsApiKeyAndroid = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY_ANDROID',
    defaultValue: '',
  );

  static const String googleMapsApiKeyIos = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY_IOS',
    defaultValue: '',
  );

  static const String environmentName = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Fails fast at startup (in debug/profile builds) if a required secret
  /// was not supplied, rather than surfacing a confusing network error
  /// three screens deep into the app.
  static void assertConfigured() {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    ];

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required --dart-define values: ${missing.join(', ')}. '
        'Run via the main_<flavor>.dart entrypoints with '
        '--dart-define-from-file=env/<flavor>.json',
      );
    }
  }
}

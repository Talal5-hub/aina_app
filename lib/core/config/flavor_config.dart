import 'package:aina/core/config/env.dart';

/// Holds the resolved flavor for the running app instance.
///
/// Initialized exactly once, from the flavor-specific `main_*.dart`
/// entrypoint, before `runApp` is called.
class FlavorConfig {
  FlavorConfig._({
    required this.environment,
    required this.appTitle,
    required this.baseApiUrl,
    required this.enableLogging,
  });

  static FlavorConfig? _instance;

  final Environment environment;
  final String appTitle;
  final String baseApiUrl;
  final bool enableLogging;

  static FlavorConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'FlavorConfig.initialize() must be called before FlavorConfig.instance '
        'is accessed. This happens automatically in main_<flavor>.dart.',
      );
    }
    return config;
  }

  static void initialize(Environment environment) {
    _instance = switch (environment) {
      Environment.development => FlavorConfig._(
          environment: environment,
          appTitle: 'Aina (Dev)',
          baseApiUrl: Env.supabaseUrl,
          enableLogging: true,
        ),
      Environment.staging => FlavorConfig._(
          environment: environment,
          appTitle: 'Aina (Staging)',
          baseApiUrl: Env.supabaseUrl,
          enableLogging: true,
        ),
      Environment.production => FlavorConfig._(
          environment: environment,
          appTitle: 'Aina',
          baseApiUrl: Env.supabaseUrl,
          enableLogging: false,
        ),
    };
  }

  bool get isProduction => environment.isProduction;
  bool get isDevelopment => environment.isDevelopment;
  bool get isStaging => environment.isStaging;
}

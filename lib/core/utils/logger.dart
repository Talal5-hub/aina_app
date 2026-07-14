import 'package:logger/logger.dart';
import 'package:aina/core/config/flavor_config.dart';

/// Thin wrapper around the `logger` package so call sites don't
/// instantiate their own `Logger()` (which would each carry separate
/// config) and so production builds can silence everything below
/// warning-level in one place.
class AppLogger {
  const AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.trace,
  );

  static bool get _enabled => FlavorConfig.instance.enableLogging;

  static void debug(String message) {
    if (_enabled) _logger.d(message);
  }

  static void info(String message) {
    if (_enabled) _logger.i(message);
  }

  static void warning(String message) {
    if (_enabled) _logger.w(message);
  }

  /// Errors are always logged, even in production, since they're needed
  /// for crash-reporting pipelines — only debug/info/warning are
  /// suppressed in release builds.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}

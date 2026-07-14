import 'package:dio/dio.dart';
import 'package:aina/core/config/flavor_config.dart';
import 'package:aina/core/utils/logger.dart';

/// Logs outgoing requests and incoming responses/errors through
/// [AppLogger]. Fully disabled in production builds (see
/// [FlavorConfig.enableLogging]) so request/response bodies — which may
/// contain user data — are never written to production device logs.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (FlavorConfig.instance.enableLogging) {
      AppLogger.debug(
        '➡️  ${options.method} ${options.uri}\n'
        'Headers: ${_redactHeaders(options.headers)}\n'
        'Body: ${options.data}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (FlavorConfig.instance.enableLogging) {
      AppLogger.debug(
        '⬅️  ${response.statusCode} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (FlavorConfig.instance.enableLogging) {
      AppLogger.error(
        '❌ ${err.requestOptions.method} ${err.requestOptions.uri}',
        err,
        err.stackTrace,
      );
    }
    handler.next(err);
  }

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    final redacted = Map<String, dynamic>.from(headers);
    for (final key in ['Authorization', 'apikey']) {
      if (redacted.containsKey(key)) redacted[key] = '***REDACTED***';
    }
    return redacted;
  }
}

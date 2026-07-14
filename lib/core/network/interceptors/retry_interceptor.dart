import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:aina/core/network/network_info.dart';
import 'package:aina/core/utils/logger.dart';

/// Retries idempotent (GET) requests that fail due to transient network
/// issues or a 5xx server response, with exponential backoff + jitter.
/// POST/PATCH/DELETE are never auto-retried here, since retrying a
/// non-idempotent request risks duplicate side effects (e.g. double
/// booking) — those failures should surface immediately to the caller.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio,
    this._networkInfo, {
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  final Dio _dio;
  final NetworkInfo _networkInfo;
  final int maxRetries;
  final Duration baseDelay;

  static const String _retryCountKey = 'retry_count';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isIdempotent = options.method.toUpperCase() == 'GET';
    final retryCount = (options.extra[_retryCountKey] as int?) ?? 0;

    final shouldRetry = isIdempotent &&
        retryCount < maxRetries &&
        _isRetryableError(err) &&
        await _networkInfo.isConnected;

    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    final delay = _backoffDelay(retryCount);
    AppLogger.debug(
      'Retrying ${options.method} ${options.uri} '
      '(attempt ${retryCount + 1}/$maxRetries) after ${delay.inMilliseconds}ms',
    );
    await Future.delayed(delay);

    options.extra[_retryCountKey] = retryCount + 1;

    try {
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _isRetryableError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    final statusCode = err.response?.statusCode;
    return statusCode != null && statusCode >= 500;
  }

  Duration _backoffDelay(int retryCount) {
    final exponential = baseDelay.inMilliseconds * pow(2, retryCount);
    final jitter = Random().nextInt(200);
    return Duration(milliseconds: exponential.toInt() + jitter);
  }
}

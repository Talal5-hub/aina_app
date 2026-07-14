/// Exceptions thrown by the data layer (Dio client, Supabase calls).
/// These are caught at the repository boundary and converted to
/// [Failure]s via [ExceptionMapper] — the domain/presentation layers
/// never see raw exceptions.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final dynamic data;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// Named to avoid colliding with dart:async's built-in [TimeoutException].
class RequestTimeoutException implements Exception {
  const RequestTimeoutException([this.message = 'Request timed out']);

  final String message;

  @override
  String toString() => 'RequestTimeoutException: $message';
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class CacheException implements Exception {
  const CacheException([this.message = 'Local cache read/write failed']);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

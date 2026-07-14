import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:aina/core/error/failures.dart';
import 'package:aina/core/network/api_exception.dart';
import 'package:aina/core/utils/logger.dart';

/// Single point of translation from "whatever went wrong at the
/// network/database layer" to a domain [Failure]. Every repository's
/// catch block should route through here rather than hand-rolling its
/// own error message.
class ExceptionMapper {
  const ExceptionMapper._();

  static Failure map(Object error, [StackTrace? stackTrace]) {
    AppLogger.error('Exception mapped to Failure', error, stackTrace);

    return switch (error) {
      DioException e => _mapDioException(e),
      supabase.AuthException e => AuthFailure(e.message),
      supabase.PostgrestException e => _mapPostgrestException(e),
      supabase.StorageException e => ServerFailure(
        e.message,
        statusCode: int.tryParse(e.statusCode ?? ''),
      ),
      NetworkException e => NetworkFailure(e.message),
      RequestTimeoutException e => TimeoutFailure(e.message),
      AuthException e => AuthFailure(e.message),
      CacheException e => CacheFailure(e.message),
      ApiException e => ServerFailure(
        e.message,
        statusCode: e.statusCode,
      ),
      Failure e => e,
      _ => const UnknownFailure(),
    };
  }

  static Failure _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutFailure();

      case DioExceptionType.connectionError:
        return const NetworkFailure();

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final serverMessage = _extractServerMessage(e.response?.data);

        switch (statusCode) {
          case 400:
          case 422:
            return ValidationFailure(
              serverMessage ?? 'Some fields are invalid.',
            );

          case 401:
          case 403:
            return AuthFailure(
              serverMessage ?? 'You are not authorized to perform this action.',
            );

          case 404:
            return ServerFailure(
              serverMessage ?? 'Requested resource was not found.',
              statusCode: statusCode,
            );

          case 500:
          case 502:
          case 503:
          case 504:
            return ServerFailure(
              serverMessage ?? 'Server error. Please try again later.',
              statusCode: statusCode,
            );

          default:
            return ServerFailure(
              serverMessage ?? 'Unexpected server error.',
              statusCode: statusCode,
            );
        }

      case DioExceptionType.cancel:
        return const UnknownFailure(
          'Request was cancelled.',
        );

      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          'A secure connection could not be established.',
        );

      case DioExceptionType.unknown:
        return const UnknownFailure(
          'An unexpected network error occurred.',
        );
    }
  }

  static Failure _mapPostgrestException(supabase.PostgrestException e) {
    switch (e.code) {
      case '23505': // unique_violation
        return const ValidationFailure(
          'This already exists.',
        );

      case '23503': // foreign_key_violation
        return const ValidationFailure(
          'This action references data that no longer exists.',
        );

      case '42501': // insufficient_privilege (RLS denial)
        return const PermissionFailure(
          'You do not have permission to do this.',
        );

      default:
        return DatabaseFailure(e.message);
    }
  }

  static String? _extractServerMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'] ?? responseData['error'];

      if (message is String) {
        return message;
      }
    }

    return null;
  }
}
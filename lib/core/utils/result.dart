import 'package:aina/core/error/failures.dart';

/// A lightweight `Either`-style result type. Repositories return
/// `Future<Result<T>>` instead of throwing, so the presentation layer
/// (via Riverpod AsyncNotifiers) can handle success/failure explicitly
/// and exhaustively, without try/catch scattered through the UI layer.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = Error<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Error<T>;

  /// Returns the success value or `null` if this is a failure.
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Error<T>() => null,
      };

  /// Returns the failure or `null` if this is a success.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Error<T>(:final failure) => failure,
      };

  /// Pattern-match helper for concise call-site handling.
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    return switch (self) {
      Success<T>(:final data) => success(data),
      Error<T>(failure: final f) => failure(f),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}

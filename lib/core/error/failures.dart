/// Domain-layer failure types. Repositories return `Result<T, Failure>`
/// (see `core/utils/result.dart`) rather than throwing, so the
/// presentation layer can exhaustively pattern-match on what went wrong
/// and show the right UI (offline banner vs. generic error vs. auth
/// redirect) without parsing exception messages.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please check your network.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'The request timed out. Please try again.']);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors});

  /// Field name -> error message, for surfacing inline form errors.
  final Map<String, String>? fieldErrors;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not read local data.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong. Please try again.']);
}

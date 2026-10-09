/// Why an operation failed, as the domain and presentation layers see it.
///
/// Pure Dart: repositories convert data-layer exceptions into these.
sealed class Failure {
  const Failure(this.message);

  /// A message that is safe to show to the user.
  final String message;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is Failure &&
      other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$runtimeType($message)';
}

/// The API answered with an error status (4xx/5xx other than 401).
final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;
}

/// The API could not be reached (offline, DNS, timeout).
final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Could not reach the server. Check your connection.',
  ]);
}

/// The credentials or session were rejected.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

/// Reading or writing on-device storage failed.
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not access local storage.']);
}

/// Input broke a business rule before any I/O happened.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

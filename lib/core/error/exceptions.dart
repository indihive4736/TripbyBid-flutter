import 'failures.dart';

/// Thrown by data sources. Repository implementations catch these and return
/// the matching [Failure] via [toFailure]; they never reach the domain layer.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  Failure toFailure();

  @override
  String toString() => '$runtimeType($message)';
}

final class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});

  final int? statusCode;

  @override
  Failure toFailure() => ServerFailure(message, statusCode: statusCode);
}

final class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Could not reach the server. Check your connection.',
  ]);

  @override
  Failure toFailure() => NetworkFailure(message);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Your session has expired. Please sign in again.',
  ]);

  @override
  Failure toFailure() => UnauthorizedFailure(message);
}

final class CacheException extends AppException {
  const CacheException([super.message = 'Could not access local storage.']);

  @override
  Failure toFailure() => CacheFailure(message);
}

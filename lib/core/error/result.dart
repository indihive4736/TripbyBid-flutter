import 'failures.dart';

/// The outcome of a repository call or use case: [Ok] with a value, or [Err]
/// with a [Failure]. Repositories return this instead of throwing.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      other is Ok<Object?> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is Err<Object?> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Err($failure)';
}

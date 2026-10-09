import '../repositories/auth_repository.dart';

/// Stream of "the session ended on its own" events (expired or revoked).
class WatchSessionEndedUseCase {
  const WatchSessionEndedUseCase(this._repository);

  final AuthRepository _repository;

  Stream<void> call() => _repository.sessionEnded;
}

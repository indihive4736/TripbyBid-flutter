import '../../../core/error/failures.dart';
import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import 'onboarding_repository.dart';

/// Remembers that the intro slides were finished or skipped, so the next
/// launch opens the welcome screen instead.
class MarkIntroSeenUseCase implements UseCase<void, NoParams> {
  const MarkIntroSeenUseCase(this._repository);

  final OnboardingRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) async {
    try {
      await _repository.markIntroSeen();
      return const Ok(null);
    } on Object {
      return const Err(CacheFailure());
    }
  }
}

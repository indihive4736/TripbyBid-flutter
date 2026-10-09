import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/core/usecase/usecase.dart';
import 'package:tripbybid/features/onboarding/domain/mark_intro_seen_usecase.dart';

import '../onboarding_fakes.dart';

void main() {
  test('marks the intro as seen', () async {
    final repository = FakeOnboardingRepository();

    final result = await MarkIntroSeenUseCase(repository)(const NoParams());

    expect(result, const Ok<void>(null));
    expect(repository.introSeen, isTrue);
  });

  test('a storage error becomes a CacheFailure', () async {
    final repository = FakeOnboardingRepository()
      ..failWith = Exception('disk full');

    final result = await MarkIntroSeenUseCase(repository)(const NoParams());

    expect(result, const Err<void>(CacheFailure()));
    expect(repository.introSeen, isFalse);
  });
}

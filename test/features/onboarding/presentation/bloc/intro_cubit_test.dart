import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/features/onboarding/domain/mark_intro_seen_usecase.dart';
import 'package:tripbybid/features/onboarding/presentation/bloc/intro_cubit.dart';

import '../../onboarding_fakes.dart';

void main() {
  late FakeOnboardingRepository repository;

  setUp(() => repository = FakeOnboardingRepository());

  IntroCubit build() =>
      IntroCubit(markIntroSeen: MarkIntroSeenUseCase(repository));

  blocTest<IntroCubit, IntroState>(
    'tracks the visible page, clamped to the slides',
    build: build,
    act: (cubit) => cubit
      ..pageChanged(1)
      ..pageChanged(2)
      ..pageChanged(7),
    expect: () => [const IntroState(page: 1), const IntroState(page: 2)],
  );

  blocTest<IntroCubit, IntroState>(
    'finish marks the intro as seen once',
    build: build,
    act: (cubit) async {
      await cubit.finish();
      await cubit.finish();
    },
    expect: () => [const IntroState(finished: true)],
    verify: (_) {
      expect(repository.introSeen, isTrue);
      expect(repository.markCalls, 1);
    },
  );

  blocTest<IntroCubit, IntroState>(
    'still finishes when storage fails',
    setUp: () => repository.failWith = Exception('disk full'),
    build: build,
    act: (cubit) => cubit.finish(),
    expect: () => [const IntroState(finished: true)],
  );

  test('isLastPage on the third slide', () {
    final cubit = build()..pageChanged(2);
    expect(cubit.isLastPage, isTrue);
  });
}

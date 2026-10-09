import 'package:tripbybid/features/onboarding/domain/onboarding_repository.dart';

/// In-memory [OnboardingRepository]. Set [failWith] to make
/// `markIntroSeen` throw.
class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this.introSeen = false});

  @override
  bool introSeen;

  Object? failWith;
  int markCalls = 0;

  @override
  Future<void> markIntroSeen() async {
    markCalls++;
    if (failWith case final error?) throw error;
    introSeen = true;
  }
}

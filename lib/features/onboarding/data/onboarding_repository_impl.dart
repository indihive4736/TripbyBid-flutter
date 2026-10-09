import 'package:shared_preferences/shared_preferences.dart';

import '../domain/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._prefs);

  static const _key = 'intro_seen';

  final SharedPreferences _prefs;

  @override
  bool get introSeen => _prefs.getBool(_key) ?? false;

  @override
  Future<void> markIntroSeen() => _prefs.setBool(_key, true);
}

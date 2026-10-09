/// Whether the traveler has already seen the intro slides on this device.
abstract interface class OnboardingRepository {
  /// Read synchronously: the router needs it to pick the first screen.
  bool get introSeen;

  Future<void> markIntroSeen();
}

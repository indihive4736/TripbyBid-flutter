import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/payments/domain/entities/checkout.dart';
import 'package:tripbybid/features/payments/domain/repositories/payments_repository.dart';
import 'package:tripbybid/features/profile/domain/entities/profile.dart';
import 'package:tripbybid/features/profile/domain/repositories/profile_repository.dart';

const _notScripted = Err<Never>(ServerFailure('not scripted'));

/// In-memory [ProfileRepository]; calls are recorded in [calls].
class FakeProfileRepository implements ProfileRepository {
  Result<UserProfile> profileResult = Ok(ProfileFixtures.profile);
  Result<UserProfile>? updateResult;
  Result<NotificationPreferences> preferencesResult = const Ok(
    NotificationPreferences(),
  );
  Result<NotificationPreferences>? updatePreferencesResult;

  final calls = <String>[];
  NotificationPreferences? lastSavedPreferences;

  @override
  Future<Result<UserProfile>> getProfile() async {
    calls.add('getProfile');
    return profileResult;
  }

  @override
  Future<Result<UserProfile>> updateProfile({
    required String name,
    String? phone,
    String? bio,
  }) async {
    calls.add('updateProfile:$name:$phone:$bio');
    return updateResult ??
        Ok(
          UserProfile(
            id: 'u-1',
            email: 'asha@example.com',
            name: name,
            phone: phone,
            bio: bio,
          ),
        );
  }

  @override
  Future<Result<NotificationPreferences>> getPreferences() async {
    calls.add('getPreferences');
    return preferencesResult;
  }

  @override
  Future<Result<NotificationPreferences>> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    calls.add('updatePreferences');
    lastSavedPreferences = preferences;
    return updatePreferencesResult ?? Ok(preferences);
  }
}

/// In-memory [PaymentsRepository]; only history is scriptable here.
class FakePaymentsRepository implements PaymentsRepository {
  Result<List<PaymentRecord>> historyResult = const Ok([]);

  @override
  Future<Result<List<PaymentRecord>>> getHistory() async => historyResult;

  @override
  Future<Result<PaymentSummary>> getSummary(String bidId) async => _notScripted;

  @override
  Future<Result<CheckoutSession>> startCheckout(String bidId) async =>
      _notScripted;

  @override
  Future<Result<String>> confirmAndBook({
    required String paymentId,
    required String bidId,
  }) async => _notScripted;
}

abstract final class ProfileFixtures {
  static final profile = UserProfile(
    id: 'u-1',
    email: 'asha@example.com',
    name: 'Asha Rao',
    phone: '+919810043210',
    bio: 'Window seat, always.',
    createdAt: DateTime(2025, 3, 2),
    completedTrips: 7,
  );

  static PaymentRecord payment({
    String id = 'pay-1',
    String status = 'completed',
    double amount = 17999,
    String? receiptNumber = 'RCPT-0042',
  }) => PaymentRecord(
    id: id,
    amount: amount,
    status: status,
    createdAt: DateTime(2026, 10, 1, 11, 5),
    tripTitle: 'Mumbai → Dubai',
    agentName: 'AirTrek India',
    receiptNumber: receiptNumber,
  );
}

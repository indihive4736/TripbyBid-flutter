import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/network/parse.dart';
import '../../domain/entities/profile.dart';

/// `/users/me` on the NestJS API. Throws `AppException`s.
abstract interface class ProfileRemoteDataSource {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile({
    required String name,
    String? phone,
    String? bio,
  });
  Future<NotificationPreferences> getPreferences();
  Future<NotificationPreferences> updatePreferences(NotificationPreferences p);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._api);

  final ApiClient _api;

  @override
  Future<UserProfile> getProfile() async {
    final json = await _api.get('/users/me');
    return parseResponse(() => _profile(JsonReader.of(json)));
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
    String? phone,
    String? bio,
  }) async {
    final json = await _api.patch(
      '/users/me',
      body: {'name': name, 'phone': ?phone, 'bio': ?bio},
    );
    return parseResponse(() => _profile(JsonReader.of(json)));
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    final json = await _api.get('/users/me/notification-preferences');
    return parseResponse(() => _preferences(JsonReader.of(json)));
  }

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences p,
  ) async {
    final json = await _api.patch(
      '/users/me/notification-preferences',
      body: {
        'email': {
          'booking_updates': p.emailBookingUpdates,
          'new_bids': p.emailNewBids,
          'messages': p.emailMessages,
          'promotions': p.emailPromotions,
        },
        'push': {
          'booking_alerts': p.pushBookingAlerts,
          'message_alerts': p.pushMessageAlerts,
          'travel_reminders': p.pushTravelReminders,
        },
      },
    );
    return parseResponse(() => _preferences(JsonReader.of(json)));
  }

  static UserProfile _profile(JsonReader u) => UserProfile(
    id: u.string('id'),
    email: u.string('email'),
    name: u.stringOrNull('name') ?? '',
    phone: u.stringOrNull('phone'),
    bio: u.stringOrNull('bio'),
    avatarUrl: u.stringOrNull('avatar_url'),
    createdAt: u.dateOrNull('created_at'),
    completedTrips: u.integer('total_bookings'),
  );

  static NotificationPreferences _preferences(JsonReader p) {
    final email = p.object('email');
    final push = p.object('push');
    return NotificationPreferences(
      emailBookingUpdates: email?.boolean('booking_updates', true) ?? true,
      emailNewBids: email?.boolean('new_bids', true) ?? true,
      emailMessages: email?.boolean('messages', true) ?? true,
      emailPromotions: email?.boolean('promotions') ?? false,
      pushBookingAlerts: push?.boolean('booking_alerts', true) ?? true,
      pushMessageAlerts: push?.boolean('message_alerts', true) ?? true,
      pushTravelReminders: push?.boolean('travel_reminders', true) ?? true,
    );
  }
}

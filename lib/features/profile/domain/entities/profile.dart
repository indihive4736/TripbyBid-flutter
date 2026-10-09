/// The traveler's own profile.
final class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.bio,
    this.avatarUrl,
    this.createdAt,
    this.completedTrips = 0,
  });

  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? bio;
  final String? avatarUrl;
  final DateTime? createdAt;

  /// Completed bookings, as counted by the backend.
  final int completedTrips;

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.id == id &&
      other.email == email &&
      other.name == name &&
      other.phone == phone &&
      other.bio == bio &&
      other.avatarUrl == avatarUrl &&
      other.createdAt == createdAt &&
      other.completedTrips == completedTrips;

  @override
  int get hashCode => Object.hash(
    id,
    email,
    name,
    phone,
    bio,
    avatarUrl,
    createdAt,
    completedTrips,
  );
}

/// Which notifications the traveler wants, by channel.
final class NotificationPreferences {
  const NotificationPreferences({
    this.emailBookingUpdates = true,
    this.emailNewBids = true,
    this.emailMessages = true,
    this.emailPromotions = false,
    this.pushBookingAlerts = true,
    this.pushMessageAlerts = true,
    this.pushTravelReminders = true,
  });

  final bool emailBookingUpdates;
  final bool emailNewBids;
  final bool emailMessages;
  final bool emailPromotions;
  final bool pushBookingAlerts;
  final bool pushMessageAlerts;
  final bool pushTravelReminders;

  NotificationPreferences copyWith({
    bool? emailBookingUpdates,
    bool? emailNewBids,
    bool? emailMessages,
    bool? emailPromotions,
    bool? pushBookingAlerts,
    bool? pushMessageAlerts,
    bool? pushTravelReminders,
  }) => NotificationPreferences(
    emailBookingUpdates: emailBookingUpdates ?? this.emailBookingUpdates,
    emailNewBids: emailNewBids ?? this.emailNewBids,
    emailMessages: emailMessages ?? this.emailMessages,
    emailPromotions: emailPromotions ?? this.emailPromotions,
    pushBookingAlerts: pushBookingAlerts ?? this.pushBookingAlerts,
    pushMessageAlerts: pushMessageAlerts ?? this.pushMessageAlerts,
    pushTravelReminders: pushTravelReminders ?? this.pushTravelReminders,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationPreferences &&
      other.emailBookingUpdates == emailBookingUpdates &&
      other.emailNewBids == emailNewBids &&
      other.emailMessages == emailMessages &&
      other.emailPromotions == emailPromotions &&
      other.pushBookingAlerts == pushBookingAlerts &&
      other.pushMessageAlerts == pushMessageAlerts &&
      other.pushTravelReminders == pushTravelReminders;

  @override
  int get hashCode => Object.hash(
    emailBookingUpdates,
    emailNewBids,
    emailMessages,
    emailPromotions,
    pushBookingAlerts,
    pushMessageAlerts,
    pushTravelReminders,
  );
}

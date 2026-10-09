/// Who the signed-in account is. A traveler posts requests; an agent bids.
enum UserRole { traveler, agent, admin }

/// The signed-in account.
final class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.verified,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;

  /// For agents: whether TripByBid has verified the business.
  final bool verified;
  final String? phone;
  final String? avatarUrl;

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.email == email &&
      other.name == name &&
      other.role == role &&
      other.verified == verified &&
      other.phone == phone &&
      other.avatarUrl == avatarUrl;

  @override
  int get hashCode =>
      Object.hash(id, email, name, role, verified, phone, avatarUrl);

  @override
  String toString() => 'User($id, $email, $role)';
}

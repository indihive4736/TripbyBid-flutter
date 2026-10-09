import '../../domain/entities/user.dart';

/// The profile JSON returned by `/auth/login` and `/auth/me`
/// (`OwnProfileResponse` in the backend).
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.verified,
    this.phone,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, Object?> json) {
    if (json case {
      'id': final String id,
      'email': final String email,
      'name': final String name,
      'role': final String role,
    }) {
      return UserModel(
        id: id,
        email: email,
        name: name,
        role: role,
        verified: json['verified'] == true,
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
    }
    throw const FormatException('Invalid user payload');
  }

  final String id;
  final String email;
  final String name;

  /// Backend role: `user` (traveler), `agent` or `admin`.
  final String role;
  final bool verified;
  final String? phone;
  final String? avatarUrl;

  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role,
    'verified': verified,
    'phone': phone,
    'avatar_url': avatarUrl,
  };

  User toEntity() => User(
    id: id,
    email: email,
    name: name,
    role: switch (role) {
      'agent' => UserRole.agent,
      'admin' => UserRole.admin,
      _ => UserRole.traveler,
    },
    verified: verified,
    phone: phone,
    avatarUrl: avatarUrl,
  );
}

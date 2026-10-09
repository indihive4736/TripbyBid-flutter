import 'package:tripbybid/core/network/auth_tokens.dart';
import 'package:tripbybid/features/auth/data/models/user_model.dart';
import 'package:tripbybid/features/auth/domain/entities/user.dart';

/// `OwnProfileResponse` as the backend sends it (extra fields included).
Map<String, Object?> userJson({String role = 'user'}) => {
  'id': 'u-1',
  'email': 'asha@example.com',
  'name': 'Asha Rao',
  'role': role,
  'phone': '+919800000000',
  'avatar_url': null,
  'rating': 4.5,
  'total_bookings': 3,
  'verified': true,
  'agency_name': null,
  'created_at': '2026-01-01T00:00:00.000Z',
  'is_active': true,
};

const tUserModel = UserModel(
  id: 'u-1',
  email: 'asha@example.com',
  name: 'Asha Rao',
  role: 'user',
  verified: true,
  phone: '+919800000000',
);

const tUser = User(
  id: 'u-1',
  email: 'asha@example.com',
  name: 'Asha Rao',
  role: UserRole.traveler,
  verified: true,
  phone: '+919800000000',
);

final tTokens = AuthTokens(
  accessToken: 'access-1',
  refreshToken: 'refresh-1',
  expiresAt: DateTime.utc(2026, 10, 10, 12),
);

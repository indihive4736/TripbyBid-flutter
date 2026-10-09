import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/features/auth/data/models/login_response_model.dart';
import 'package:tripbybid/features/auth/data/models/user_model.dart';
import 'package:tripbybid/features/auth/domain/entities/user.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  group('UserModel', () {
    test('parses the backend profile and maps it to the entity', () {
      expect(UserModel.fromJson(userJson()).toEntity(), tUser);
    });

    test('maps backend roles to UserRole', () {
      UserRole role(String backendRole) =>
          UserModel.fromJson(userJson(role: backendRole)).toEntity().role;

      expect(role('user'), UserRole.traveler);
      expect(role('agent'), UserRole.agent);
      expect(role('admin'), UserRole.admin);
    });

    test('round-trips through toJson', () {
      expect(UserModel.fromJson(tUserModel.toJson()).toEntity(), tUser);
    });

    test('throws FormatException when required fields are missing', () {
      expect(
        () => UserModel.fromJson({'id': 'u-1'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('LoginResponseModel parses user and session', () {
    final model = LoginResponseModel.fromJson({
      'user': userJson(),
      'session': {
        'access_token': 'a',
        'refresh_token': 'r',
        'expires_in': 900,
        'expires_at': 1791633600,
        'token_type': 'bearer',
      },
    });

    expect(model.user.toEntity(), tUser);
    expect(model.tokens.accessToken, 'a');
    expect(model.tokens.refreshToken, 'r');
    expect(
      model.tokens.expiresAt,
      DateTime.fromMillisecondsSinceEpoch(1791633600 * 1000, isUtc: true),
    );
  });
}

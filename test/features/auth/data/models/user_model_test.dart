import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/features/auth/data/models/user_model.dart';
import 'package:tripbybid/features/auth/domain/entities/user.dart';

import '../../../../helpers/fixtures.dart';

void main() {
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
}

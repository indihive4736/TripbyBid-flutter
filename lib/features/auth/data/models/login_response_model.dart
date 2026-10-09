import '../../../../core/network/auth_tokens.dart';
import 'user_model.dart';

/// `POST /auth/login` → `{user, session}`.
class LoginResponseModel {
  const LoginResponseModel({required this.user, required this.tokens});

  factory LoginResponseModel.fromJson(Map<String, Object?> json) {
    if (json case {
      'user': final Map<String, Object?> user,
      'session': final Map<String, Object?> session,
    }) {
      return LoginResponseModel(
        user: UserModel.fromJson(user),
        tokens: AuthTokens.fromSessionJson(session),
      );
    }
    throw const FormatException('Invalid login payload');
  }

  final UserModel user;
  final AuthTokens tokens;
}

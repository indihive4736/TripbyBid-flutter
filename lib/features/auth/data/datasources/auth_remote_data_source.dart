import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  });

  /// `null` when the token is valid but has no profile.
  Future<UserModel?> getCurrentUser();

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    return _parse(json, LoginResponseModel.fromJson);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final json = await _client.get('/auth/me');
    if (json == null) return null;
    return _parse(json, UserModel.fromJson);
  }

  @override
  Future<void> logout() => _client.post('/auth/logout');

  static T _parse<T>(Object? json, T Function(Map<String, Object?>) fromJson) {
    try {
      if (json is Map<String, Object?>) return fromJson(json);
    } on FormatException {
      // Falls through to the error below.
    } on TypeError {
      // A field had an unexpected type.
    }
    throw const ServerException('Unexpected response from server.');
  }
}

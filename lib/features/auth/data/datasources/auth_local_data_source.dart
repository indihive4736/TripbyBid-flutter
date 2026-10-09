import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/auth_tokens.dart';
import '../../../../core/network/token_storage.dart';
import '../models/user_model.dart';

/// The session tokens plus a cached copy of the profile, so the app can start
/// signed in while offline.
abstract interface class AuthLocalDataSource {
  Future<void> saveSession(AuthTokens tokens, UserModel user);
  Future<bool> hasSession();
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl({
    required TokenStorage tokenStorage,
    required FlutterSecureStorage secureStorage,
  }) : _tokens = tokenStorage,
       _storage = secureStorage;

  static const _userKey = 'cached_user';

  final TokenStorage _tokens;
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveSession(AuthTokens tokens, UserModel user) async {
    await _tokens.write(tokens);
    await cacheUser(user);
  }

  @override
  Future<bool> hasSession() async => await _tokens.read() != null;

  @override
  Future<UserModel?> getCachedUser() async {
    final String? raw;
    try {
      raw = await _storage.read(key: _userKey);
    } on Exception {
      throw const CacheException();
    }
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    } on Exception {
      throw const CacheException();
    }
  }

  @override
  Future<void> clearSession() async {
    await _tokens.clear();
    try {
      await _storage.delete(key: _userKey);
    } on Exception {
      throw const CacheException();
    }
  }
}

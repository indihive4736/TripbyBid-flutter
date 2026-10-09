import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// A cached copy of the profile, so the app can start signed in while
/// offline. (The session itself is persisted by Supabase.)
abstract interface class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._storage);

  static const _userKey = 'cached_user';

  final FlutterSecureStorage _storage;

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
  Future<void> clear() async {
    try {
      await _storage.delete(key: _userKey);
    } on Exception {
      throw const CacheException();
    }
  }
}

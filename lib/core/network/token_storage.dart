import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../error/exceptions.dart';
import 'auth_tokens.dart';

/// Persists the backend session. Shared by `ApiClient` (to attach and refresh
/// tokens) and the auth feature (to save and clear the session).
abstract interface class TokenStorage {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  static const _key = 'auth_session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final String? raw;
    try {
      raw = await _storage.read(key: _key);
    } on Exception {
      throw const CacheException();
    }
    if (raw == null) return null;
    try {
      return AuthTokens.fromSessionJson(
        jsonDecode(raw) as Map<String, Object?>,
      );
    } on Object {
      // Unreadable leftovers from an older format: treat as signed out.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    try {
      await _storage.write(
        key: _key,
        value: jsonEncode(tokens.toSessionJson()),
      );
    } on Exception {
      throw const CacheException();
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on Exception {
      throw const CacheException();
    }
  }
}

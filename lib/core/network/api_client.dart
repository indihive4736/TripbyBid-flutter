import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../error/exceptions.dart';
import 'auth_tokens.dart';
import 'token_storage.dart';

/// JSON client for the NestJS API.
///
/// Authenticated requests carry `Authorization: Bearer <access token>`. The
/// access token is refreshed shortly before it expires and once more on a 401.
/// Refreshes are single-flight: the backend revokes the whole session when a
/// refresh token is reused, so two concurrent refreshes would sign the user out.
///
/// Throws [UnauthorizedException], [ServerException] or [NetworkException].
class ApiClient {
  ApiClient({
    required http.Client httpClient,
    required TokenStorage tokenStorage,
    required String baseUrl,
    DateTime Function()? clock,
    Duration timeout = const Duration(seconds: 20),
  }) : _http = httpClient,
       _tokens = tokenStorage,
       _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _clock = clock ?? DateTime.now,
       _timeout = timeout;

  static const _refreshMargin = Duration(seconds: 30);

  final http.Client _http;
  final TokenStorage _tokens;
  final String _baseUrl;
  final DateTime Function() _clock;
  final Duration _timeout;

  Future<AuthTokens?>? _refreshInFlight;

  Future<Object?> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) => _send('GET', path, query: query, authenticated: authenticated);

  Future<Object?> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('POST', path, body: body, authenticated: authenticated);

  Future<Object?> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('PATCH', path, body: body, authenticated: authenticated);

  Future<Object?> delete(String path, {bool authenticated = true}) =>
      _send('DELETE', path, authenticated: authenticated);

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required bool authenticated,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    if (!authenticated) {
      return _decode(await _request(method, uri, body, null));
    }

    var tokens = await _tokens.read();
    if (tokens == null) throw const UnauthorizedException('Not signed in.');
    if (tokens.expiresWithin(_refreshMargin, _clock())) {
      tokens = await _refresh(tokens);
    }

    var response = await _request(method, uri, body, tokens.accessToken);
    if (response.statusCode == 401) {
      tokens = await _refresh(tokens);
      response = await _request(method, uri, body, tokens.accessToken);
    }
    return _decode(response);
  }

  /// Returns fresh tokens or throws [UnauthorizedException] (session cleared).
  Future<AuthTokens> _refresh(AuthTokens stale) async {
    final fresh = await (_refreshInFlight ??= _rotate(
      stale,
    ).whenComplete(() => _refreshInFlight = null));
    if (fresh == null) throw const UnauthorizedException();
    return fresh;
  }

  Future<AuthTokens?> _rotate(AuthTokens stale) async {
    // Another request may already have rotated: sending the old refresh token
    // again would count as reuse and revoke the session.
    final current = await _tokens.read();
    if (current == null) return null;
    if (current.refreshToken != stale.refreshToken) return current;

    final response = await _request(
      'POST',
      Uri.parse('$_baseUrl/auth/refresh'),
      {'refresh_token': current.refreshToken},
      null,
    );
    if (response.statusCode == 400 || response.statusCode == 401) {
      await _tokens.clear();
      return null;
    }
    final json = _decode(response);
    if (json case {'session': final Map<String, Object?> session}) {
      try {
        final fresh = AuthTokens.fromSessionJson(session);
        await _tokens.write(fresh);
        return fresh;
      } on FormatException {
        // Falls through to the error below.
      }
    }
    throw const ServerException('Unexpected response from server.');
  }

  Future<http.Response> _request(
    String method,
    Uri uri,
    Object? body,
    String? accessToken,
  ) async {
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    try {
      final streamed = await _http.send(request).timeout(_timeout);
      return await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw const NetworkException('The server took too long to respond.');
    } on http.ClientException {
      throw const NetworkException();
    }
  }

  Object? _decode(http.Response response) {
    final Object? json;
    try {
      json = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      if (_isSuccess(response.statusCode)) {
        throw const ServerException('Unexpected response from server.');
      }
      throw ServerException(
        'Request failed (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    if (_isSuccess(response.statusCode)) return json;

    final message =
        _errorMessage(json) ?? 'Request failed (${response.statusCode}).';
    if (response.statusCode == 401) throw UnauthorizedException(message);
    throw ServerException(message, statusCode: response.statusCode);
  }

  static bool _isSuccess(int status) => status >= 200 && status < 300;

  /// NestJS errors look like `{statusCode, message, error}`, where `message`
  /// is a string or (for validation errors) a list of strings.
  static String? _errorMessage(Object? json) => switch (json) {
    {'message': final String message} => message,
    {'message': final List<Object?> messages} when messages.isNotEmpty =>
      messages.whereType<String>().join('\n'),
    _ => null,
  };
}

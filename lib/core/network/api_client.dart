import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../error/exceptions.dart';
import 'access_token_provider.dart';

/// JSON client for the NestJS API.
///
/// Authenticated requests carry `Authorization: Bearer <access token>` from
/// the [AccessTokenProvider]. On a 401 the token is refreshed once and the
/// request retried; if that fails the provider ends the session.
///
/// Throws [UnauthorizedException], [ServerException] or [NetworkException].
class ApiClient {
  ApiClient({
    required http.Client httpClient,
    required AccessTokenProvider tokens,
    required String baseUrl,
    Duration timeout = const Duration(seconds: 20),
  }) : _http = httpClient,
       _tokens = tokens,
       _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _timeout = timeout;

  final http.Client _http;
  final AccessTokenProvider _tokens;
  final String _baseUrl;
  final Duration _timeout;

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
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: query == null || query.isEmpty ? null : query);
    if (!authenticated) {
      return _decode(await _request(method, uri, body, null));
    }

    final token = await _tokens.accessToken();
    if (token == null) throw const UnauthorizedException('Not signed in.');

    var response = await _request(method, uri, body, token);
    if (response.statusCode == 401) {
      final fresh = await _tokens.refreshAfterRejection(token);
      if (fresh == null) throw const UnauthorizedException();
      response = await _request(method, uri, body, fresh);
    }
    return _decode(response);
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

  /// NestJS errors are `{statusCode, message, error}`, where `message` is a
  /// string or (for validation errors) a list of strings. Some routes wrap
  /// it as `{success: false, error: {message}}`.
  static String? _errorMessage(Object? json) => switch (json) {
    {'error': {'message': final Object? inner}} => _messageText(inner),
    {'message': final Object? message} => _messageText(message),
    _ => null,
  };

  static String? _messageText(Object? message) => switch (message) {
    final String text when text.isNotEmpty => text,
    final List<Object?> items when items.isNotEmpty =>
      items.whereType<String>().join('\n'),
    _ => null,
  };
}

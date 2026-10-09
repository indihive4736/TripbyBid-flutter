import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tripbybid/core/error/exceptions.dart';
import 'package:tripbybid/core/network/api_client.dart';
import 'package:tripbybid/core/network/auth_tokens.dart';
import 'package:tripbybid/core/network/token_storage.dart';

class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this.tokens]);

  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> write(AuthTokens tokens) async => this.tokens = tokens;

  @override
  Future<void> clear() async => tokens = null;
}

final now = DateTime.utc(2026, 10, 10, 12);

AuthTokens tokens(
  String id, {
  Duration validFor = const Duration(minutes: 10),
}) => AuthTokens(
  accessToken: 'access-$id',
  refreshToken: 'refresh-$id',
  expiresAt: now.add(validFor),
);

http.Response json(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> sessionJson(String id) => {
  'session': {
    'access_token': 'access-$id',
    'refresh_token': 'refresh-$id',
    'expires_in': 900,
    'expires_at':
        now.add(const Duration(minutes: 15)).millisecondsSinceEpoch ~/ 1000,
    'token_type': 'bearer',
  },
};

void main() {
  late InMemoryTokenStorage storage;
  late List<http.Request> requests;

  ApiClient client(Future<http.Response> Function(http.Request) handler) =>
      ApiClient(
        httpClient: MockClient((request) {
          requests.add(request);
          return handler(request);
        }),
        tokenStorage: storage,
        baseUrl: 'https://api.test/api/',
        clock: () => now,
      );

  setUp(() {
    storage = InMemoryTokenStorage(tokens('1'));
    requests = [];
  });

  test('sends JSON with the bearer token and decodes the response', () async {
    final api = client((_) async => json({'ok': true}));

    final result = await api.post('/bids', body: {'amount': 10});

    expect(result, {'ok': true});
    final request = requests.single;
    expect(request.url.toString(), 'https://api.test/api/bids');
    expect(request.headers['Authorization'], 'Bearer access-1');
    expect(request.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(request.body), {'amount': 10});
  });

  test('unauthenticated requests carry no token and need no session', () async {
    storage.tokens = null;
    final api = client((_) async => json({'ok': true}));

    await api.post('/auth/login', body: {}, authenticated: false);

    expect(requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('authenticated request without a session throws Unauthorized', () {
    storage.tokens = null;
    final api = client((_) async => json({}));

    expect(api.get('/auth/me'), throwsA(isA<UnauthorizedException>()));
  });

  test('on 401 refreshes once and retries with the new token', () async {
    final api = client((request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        expect(jsonDecode(request.body), {'refresh_token': 'refresh-1'});
        return json(sessionJson('2'));
      }
      return request.headers['Authorization'] == 'Bearer access-2'
          ? json({'id': 'u-1'})
          : json({'statusCode': 401, 'message': 'Invalid token'}, 401);
    });

    expect(await api.get('/auth/me'), {'id': 'u-1'});
    expect(storage.tokens?.refreshToken, 'refresh-2');
    expect(requests.map((r) => r.url.path), [
      '/api/auth/me',
      '/api/auth/refresh',
      '/api/auth/me',
    ]);
  });

  test(
    'refreshes before sending when the access token is about to expire',
    () async {
      storage.tokens = tokens('1', validFor: const Duration(seconds: 10));
      final api = client(
        (request) async => request.url.path.endsWith('/auth/refresh')
            ? json(sessionJson('2'))
            : json({'ok': true}),
      );

      await api.get('/bids/agent/my');

      expect(requests.first.url.path, '/api/auth/refresh');
      expect(requests.last.headers['Authorization'], 'Bearer access-2');
    },
  );

  test('concurrent 401s share one refresh (a reused refresh token would '
      'revoke the session)', () async {
    final refreshGate = Completer<void>();
    final api = client((request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        await refreshGate.future;
        return json(sessionJson('2'));
      }
      return request.headers['Authorization'] == 'Bearer access-2'
          ? json({'ok': true})
          : json({'message': 'Invalid token'}, 401);
    });

    final calls = [api.get('/a'), api.get('/b'), api.get('/c')];
    await Future<void>.delayed(Duration.zero);
    refreshGate.complete();
    await Future.wait(calls);

    expect(
      requests.where((r) => r.url.path.endsWith('/auth/refresh')),
      hasLength(1),
    );
  });

  test(
    'does not resend a refresh token another request already rotated',
    () async {
      final api = client((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          fail('must not refresh: storage already holds rotated tokens');
        }
        if (request.headers['Authorization'] == 'Bearer access-1') {
          // Simulates another request having rotated while this one was in flight.
          storage.tokens = tokens('2');
          return json({'message': 'Invalid token'}, 401);
        }
        return json({'ok': true});
      });

      expect(await api.get('/a'), {'ok': true});
    },
  );

  test(
    'a rejected refresh clears the session and throws Unauthorized',
    () async {
      final api = client(
        (request) async => request.url.path.endsWith('/auth/refresh')
            ? json({'message': 'Invalid refresh token'}, 401)
            : json({'message': 'Invalid token'}, 401),
      );

      await expectLater(api.get('/a'), throwsA(isA<UnauthorizedException>()));
      expect(storage.tokens, isNull);
    },
  );

  test(
    'maps NestJS errors to ServerException with the server message',
    () async {
      final api = client(
        (_) async => json({
          'statusCode': 400,
          'message': ['email must be an email', 'password is too short'],
          'error': 'Bad Request',
        }, 400),
      );

      await expectLater(
        api.post('/auth/login', body: {}, authenticated: false),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.message,
                'message',
                'email must be an email\npassword is too short',
              ),
        ),
      );
    },
  );

  test('connection failures become NetworkException', () {
    final api = client((_) async => throw http.ClientException('offline'));

    expect(api.get('/a'), throwsA(isA<NetworkException>()));
  });

  test('an empty 2xx body decodes to null', () async {
    final api = client((_) async => http.Response('', 200));

    expect(await api.get('/auth/me'), isNull);
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tripbybid/core/error/exceptions.dart';
import 'package:tripbybid/core/network/access_token_provider.dart';
import 'package:tripbybid/core/network/api_client.dart';

class FakeTokens implements AccessTokenProvider {
  FakeTokens({this.token = 'access-1', this.refreshed = 'access-2'});

  String? token;

  /// What a refresh yields; null means the session is gone.
  String? refreshed;
  final rejected = <String>[];

  @override
  Future<String?> accessToken() async => token;

  @override
  Future<String?> refreshAfterRejection(String rejected) async {
    this.rejected.add(rejected);
    token = refreshed;
    return refreshed;
  }
}

http.Response json(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late FakeTokens tokens;
  late List<http.Request> requests;

  ApiClient client(Future<http.Response> Function(http.Request) handler) =>
      ApiClient(
        httpClient: MockClient((request) {
          requests.add(request);
          return handler(request);
        }),
        tokens: tokens,
        baseUrl: 'https://api.test/api/',
      );

  setUp(() {
    tokens = FakeTokens();
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

  test('adds query parameters', () async {
    final api = client((_) async => json([]));

    await api.get('/booking-requests', query: {'limit': '100'});

    expect(requests.single.url.queryParameters, {'limit': '100'});
  });

  test('unauthenticated requests carry no token and need no session', () async {
    tokens.token = null;
    final api = client((_) async => json({'ok': true}));

    await api.post('/auth/login', body: {}, authenticated: false);

    expect(requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('authenticated request without a session throws Unauthorized', () {
    tokens.token = null;
    final api = client((_) async => json({}));

    expect(api.get('/users/me'), throwsA(isA<UnauthorizedException>()));
  });

  test('on 401 refreshes once and retries with the new token', () async {
    final api = client(
      (request) async => request.headers['Authorization'] == 'Bearer access-2'
          ? json({'id': 'u-1'})
          : json({'statusCode': 401, 'message': 'Invalid token'}, 401),
    );

    expect(await api.get('/users/me'), {'id': 'u-1'});
    expect(tokens.rejected, ['access-1']);
    expect(requests, hasLength(2));
  });

  test('when the refresh fails the call throws Unauthorized', () async {
    tokens.refreshed = null;
    final api = client((_) async => json({'message': 'Invalid token'}, 401));

    await expectLater(
      api.get('/users/me'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(requests, hasLength(1));
  });

  test('maps NestJS validation errors to ServerException', () async {
    final api = client(
      (_) async => json({
        'statusCode': 400,
        'message': ['email must be an email', 'password is too short'],
        'error': 'Bad Request',
      }, 400),
    );

    await expectLater(
      api.post('/booking-requests', body: {}),
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
  });

  test('reads the wrapped {error: {message}} envelope', () async {
    final api = client(
      (_) async => json({
        'success': false,
        'error': {'code': 'CONFLICT', 'message': 'Bid is no longer available'},
      }, 409),
    );

    await expectLater(
      api.post('/bids/b-1/accept'),
      throwsA(
        isA<ServerException>().having(
          (e) => e.message,
          'message',
          'Bid is no longer available',
        ),
      ),
    );
  });

  test('connection failures become NetworkException', () {
    final api = client((_) async => throw http.ClientException('offline'));

    expect(api.get('/a'), throwsA(isA<NetworkException>()));
  });

  test('an empty 2xx body decodes to null', () async {
    final api = client((_) async => http.Response('', 200));

    expect(await api.get('/bookings/request/r-1'), isNull);
  });
}

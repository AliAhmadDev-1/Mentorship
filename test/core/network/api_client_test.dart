import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mentorship/core/network/api_client.dart';
import 'package:mentorship/core/network/error_handler.dart';
import 'package:mentorship/core/network/micro_mentor_api.dart';
import 'package:mentorship/core/network/network_info.dart';
import 'package:mentorship/core/network/session_expiration_notifier.dart';
import 'package:mentorship/core/storage/token_storage.dart';

void main() {
  group('ApiClient', () {
    test('MicroMentorApi uses the documented auth request encodings', () async {
      late http.Request loginRequest;
      late http.Request registerRequest;
      var callCount = 0;
      final client = ApiClient(
        baseUrl: 'https://api.example.test/api',
        networkInfo: _OnlineNetworkInfo(),
        httpClient: MockClient((request) async {
          callCount++;
          if (callCount == 1) {
            loginRequest = request;
          } else {
            registerRequest = request;
          }
          return http.Response(
            jsonEncode({
              'id': 1,
              'email': 'mentee@example.com',
              'access_token': 'access-token',
            }),
            200,
          );
        }),
      );
      final api = MicroMentorApi(client: client);

      await api.login(email: 'mentee@example.com', password: 'SuperSecure123');
      await api.register(
        email: 'mentee@example.com',
        password: 'SuperSecure123',
        firstName: 'Micro',
        lastName: 'Mentor',
        role: 'mentee',
      );

      expect(_contentType(loginRequest), 'application/json');
      expect(jsonDecode(loginRequest.body), {
        'email': 'mentee@example.com',
        'password': 'SuperSecure123',
      });
      expect(_contentType(registerRequest), 'application/json');
      expect(jsonDecode(registerRequest.body), {
        'email': 'mentee@example.com',
        'password': 'SuperSecure123',
        'first_name': 'Micro',
        'last_name': 'Mentor',
        'role': 'mentee',
      });
    });

    test(
      'mentor registration sends account fields and parses onboarding',
      () async {
        late http.Request capturedRequest;
        final client = ApiClient(
          baseUrl: 'https://api.example.test/api',
          networkInfo: _OnlineNetworkInfo(),
          httpClient: MockClient((request) async {
            capturedRequest = request;
            return http.Response(
              jsonEncode({
                'id': 2,
                'email': 'mentor@example.com',
                'role': 'mentor',
                'access_token': 'access-token',
                'onboarding': {
                  'application_id': 17,
                  'status': 'draft',
                  'current_step': 'professional_profile',
                  'completion_percent': 0,
                  'version': 1,
                },
              }),
              201,
            );
          }),
        );

        final response = await MicroMentorApi(client: client).register(
          email: 'mentor@example.com',
          password: 'SuperSecure123',
          firstName: 'Sarah',
          lastName: 'Chen',
          role: 'mentor',
        );

        expect(_contentType(capturedRequest), 'application/json');
        expect(jsonDecode(capturedRequest.body), {
          'email': 'mentor@example.com',
          'password': 'SuperSecure123',
          'first_name': 'Sarah',
          'last_name': 'Chen',
          'role': 'mentor',
        });
        expect(response.data?.onboarding?.applicationId, 17);
      },
    );

    test('onboarding draft saves as JSON with the latest ETag', () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'https://api.example.test/api',
        networkInfo: _OnlineNetworkInfo(),
        tokenStorage: _FakeTokenStorage(accessToken: 'access-token'),
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'id': 18,
              'status': 'draft',
              'current_step': 'expertise',
              'completion_percent': 25,
              'version': 2,
              'professional_profile': {},
              'category_ids': [],
              'expertise_ids': [],
              'documents': [],
              'packages': [],
              'availability_windows': [],
              'accepts_inquiries': true,
              'fields_requiring_changes': [],
              'can_edit': true,
              'can_submit': false,
            }),
            200,
            headers: {'etag': '"application-18-version-2"'},
          );
        }),
      );
      final api = MicroMentorApi(client: client);

      final loaded = await api.getMentorOnboarding();
      await api.updateMentorOnboarding({
        'current_step': 'expertise',
      }, etag: loaded.etag);

      expect(requests.first.method, 'GET');
      expect(requests.first.url.path, '/api/mentor-onboarding/');
      expect(requests.last.method, 'PATCH');
      expect(requests.last.url.path, '/api/mentor-onboarding/');
      expect(requests.last.headers['If-Match'], '"application-18-version-2"');
      expect(_contentType(requests.last), 'application/json');
      expect(jsonDecode(requests.last.body), {'current_step': 'expertise'});
    });

    test('direct storage upload does not add backend authorization', () async {
      late http.Request capturedRequest;
      final client = ApiClient(
        networkInfo: _OnlineNetworkInfo(),
        tokenStorage: _FakeTokenStorage(accessToken: 'access-token'),
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response('', 200);
        }),
      );

      final response = await client.uploadBytes(
        'https://storage.example.test/private-upload',
        [1, 2, 3],
        headers: const {'Content-Type': 'application/pdf'},
      );

      expect(response.success, true);
      expect(capturedRequest.method, 'PUT');
      expect(capturedRequest.headers['Authorization'], isNull);
      expect(capturedRequest.headers['Content-Type'], 'application/pdf');
      expect(capturedRequest.bodyBytes, [1, 2, 3]);
    });

    test(
      'uses pagination, concrete slot, health, and cancel contracts',
      () async {
        final requests = <http.Request>[];
        final client = ApiClient(
          baseUrl: 'https://api.example.test/api',
          networkInfo: _OnlineNetworkInfo(),
          tokenStorage: _FakeTokenStorage(accessToken: 'access-token'),
          httpClient: MockClient((request) async {
            requests.add(request);
            if (request.url.path.endsWith('/health/')) {
              return http.Response(jsonEncode({'status': 'ok'}), 200);
            }
            if (request.url.path.endsWith('/availability/')) {
              return http.Response(
                jsonEncode({'mentor_id': 17, 'slots': []}),
                200,
              );
            }
            if (request.url.path.endsWith('/cancel/')) {
              return http.Response(
                jsonEncode({'session_id': 91, 'status': 'cancelled'}),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'count': 0,
                'next': null,
                'previous': null,
                'results': [],
              }),
              200,
            );
          }),
        );
        final api = MicroMentorApi(client: client);

        final health = await api.health();
        await api.listMentors(page: 2, pageSize: 20);
        await api.listBookings(status: 'completed', page: 3, pageSize: 10);
        await api.getMentorAvailability(
          17,
          from: DateTime(2026, 9, 24),
          to: DateTime(2026, 10, 24),
          durationMinutes: 30,
          timezone: 'Asia/Karachi',
        );
        await api.cancelSession(91);

        expect(health.data, true);
        expect(requests[0].headers['Authorization'], isNull);
        expect(requests[1].url.queryParameters['page'], '2');
        expect(requests[1].url.queryParameters['page_size'], '20');
        expect(requests[2].url.queryParameters['status'], 'completed');
        expect(requests[2].url.queryParameters['page'], '3');
        expect(
          requests[3].url.queryParameters,
          containsPair('from', '2026-09-24'),
        );
        expect(
          requests[3].url.queryParameters,
          containsPair('duration_minutes', '30'),
        );
        expect(
          requests[3].url.queryParameters,
          containsPair('timezone', 'Asia/Karachi'),
        );
        expect(requests[4].method, 'POST');
        expect(requests[4].url.path, '/api/sessions/91/cancel/');
        expect(jsonDecode(requests[4].body), isEmpty);
      },
    );

    test('public catalog GET requests do not require a bearer token', () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'https://api.example.test/api',
        networkInfo: _OnlineNetworkInfo(),
        tokenStorage: _FakeTokenStorage(),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/categories/') ||
              request.url.path.endsWith('/expertise/') ||
              request.url.path.endsWith('/mentor-profiles/') ||
              request.url.path.endsWith('/packages/') ||
              request.url.path.endsWith('/availability-windows/')) {
            return http.Response(jsonEncode({'results': []}), 200);
          }
          return http.Response(
            jsonEncode({
              'id': 1,
              'headline': 'Mentor',
              'mentor_id': 1,
              'price_usd': 10,
            }),
            200,
          );
        }),
      );
      final api = MicroMentorApi(client: client);

      await api.listCategories();
      await api.getCategory(1);
      await api.listExpertise();
      await api.getExpertise(1);
      await api.listMentorProfiles();
      await api.getMentorProfile(1);
      await api.listPackages(mentorId: 1);
      await api.getPackage(1);
      await api.listAvailability(mentorId: 1);
      await api.getAvailabilityWindow(1);

      expect(requests, hasLength(10));
      expect(
        requests.every(
          (request) => !request.headers.containsKey('Authorization'),
        ),
        true,
      );
    });

    test('sends POST map bodies as multipart form-data', () async {
      late http.Request capturedRequest;
      final client = ApiClient(
        baseUrl: 'https://api.example.test/api',
        networkInfo: _OnlineNetworkInfo(),
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode({'ok': true}), 200);
        }),
      );

      await client.post<Map<String, dynamic>>(
        '/auth/login/',
        authorized: false,
        body: {'email': 'mentee@example.com', 'password': 'SuperSecure123'},
        decoder: (json) => json as Map<String, dynamic>,
      );

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.path, '/api/auth/login/');
      expect(_contentType(capturedRequest), startsWith('multipart/form-data;'));
      expect(capturedRequest.body, contains('name="email"'));
      expect(capturedRequest.body, contains('mentee@example.com'));
      expect(capturedRequest.body, contains('name="password"'));
      expect(capturedRequest.body, contains('SuperSecure123'));
    });

    test('returns backend message for unauthorized public requests', () async {
      var expirationNotifications = 0;
      void onExpired() => expirationNotifications++;
      sessionExpirationNotifier.addListener(onExpired);
      final client = ApiClient(
        baseUrl: 'https://api.example.test/api',
        networkInfo: _OnlineNetworkInfo(),
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Invalid credentials'}),
            401,
          );
        }),
      );

      try {
        final response = await client.post<Map<String, dynamic>>(
          '/auth/login/',
          authorized: false,
          body: {'email': 'wrong@example.com', 'password': 'bad-password'},
          decoder: (json) => json as Map<String, dynamic>,
        );

        expect(response.success, false);
        expect(response.error?.message, 'Invalid credentials');
        expect(response.error?.statusCode, 401);
        expect(expirationNotifications, 0);
      } finally {
        sessionExpirationNotifier.removeListener(onExpired);
      }
    });

    test('sends PATCH map bodies as multipart form-data', () async {
      late http.Request capturedRequest;
      final client = ApiClient(
        baseUrl: 'https://api.example.test/api',
        networkInfo: _OnlineNetworkInfo(),
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode({'id': 1}), 200);
        }),
      );

      await client.patch<Map<String, dynamic>>(
        '/mentor-profiles/1/',
        authorized: false,
        body: {
          'category_ids': [1, 2],
          'auto_confirm_bookings': true,
        },
        decoder: (json) => json as Map<String, dynamic>,
      );

      expect(capturedRequest.method, 'PATCH');
      expect(capturedRequest.url.path, '/api/mentor-profiles/1/');
      expect(_contentType(capturedRequest), startsWith('multipart/form-data;'));
      expect(capturedRequest.body, contains('name="category_ids"'));
      expect(capturedRequest.body, contains('1,2'));
      expect(capturedRequest.body, contains('name="auto_confirm_bookings"'));
      expect(capturedRequest.body, contains('true'));
    });

    test('sends JsonRequestBody as application/json', () async {
      late http.Request capturedRequest;
      final client = ApiClient(
        baseUrl: 'https://api.example.test/api',
        networkInfo: _OnlineNetworkInfo(),
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode({'id': 12}), 201);
        }),
      );

      await client.post<Map<String, dynamic>>(
        '/conversations/',
        authorized: false,
        body: const JsonRequestBody({'type': 'inquiry', 'mentor_id': 2}),
        decoder: (json) => json as Map<String, dynamic>,
      );

      expect(capturedRequest.headers['Content-Type'], 'application/json');
      expect(jsonDecode(capturedRequest.body), {
        'type': 'inquiry',
        'mentor_id': 2,
      });
    });

    test('adds bearer token to authorized JSON requests', () async {
      late http.Request capturedRequest;
      final client = ApiClient(
        baseUrl: 'https://api.example.test/api',
        networkInfo: _OnlineNetworkInfo(),
        tokenStorage: _FakeTokenStorage(accessToken: 'test-access-token'),
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode({'results': []}), 200);
        }),
      );

      await client.get<Map<String, dynamic>>(
        '/mentor-profiles/',
        decoder: (json) => json as Map<String, dynamic>,
      );

      expect(
        capturedRequest.headers['Authorization'],
        'Bearer test-access-token',
      );
    });

    test('adds bearer token to authorized multipart requests', () async {
      late http.Request capturedRequest;
      final client = ApiClient(
        baseUrl: 'https://api.example.test/api',
        networkInfo: _OnlineNetworkInfo(),
        tokenStorage: _FakeTokenStorage(accessToken: 'test-access-token'),
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode({'id': 1}), 201);
        }),
      );

      await client.post<Map<String, dynamic>>(
        '/mentor-profiles/',
        body: {'headline': 'Senior Product Mentor'},
        decoder: (json) => json as Map<String, dynamic>,
      );

      expect(
        capturedRequest.headers['Authorization'],
        'Bearer test-access-token',
      );
      expect(_contentType(capturedRequest), startsWith('multipart/form-data;'));
    });

    test('does not send protected requests without a token', () async {
      var sent = false;
      var expirationNotifications = 0;
      void onExpired() => expirationNotifications++;
      sessionExpirationNotifier.addListener(onExpired);
      final client = ApiClient(
        baseUrl: 'https://api.example.test/api',
        networkInfo: _OnlineNetworkInfo(),
        tokenStorage: _FakeTokenStorage(),
        httpClient: MockClient((request) async {
          sent = true;
          return http.Response(jsonEncode({'ok': true}), 200);
        }),
      );

      try {
        final response = await client.get<Map<String, dynamic>>(
          '/reviews/',
          decoder: (json) => json as Map<String, dynamic>,
        );

        expect(sent, false);
        expect(response.success, false);
        expect(response.error?.statusCode, 401);
        expect(expirationNotifications, 1);
      } finally {
        sessionExpirationNotifier.removeListener(onExpired);
      }
    });

    test('refreshes access token before protected requests', () async {
      final storage = _FakeTokenStorage(refreshToken: 'test-refresh-token');
      final paths = <String>[];
      final authHeaders = <String?>[];
      final client = ApiClient(
        baseUrl: 'https://api.example.test/api',
        networkInfo: _OnlineNetworkInfo(),
        tokenStorage: storage,
        httpClient: MockClient((request) async {
          paths.add(request.url.path);
          authHeaders.add(request.headers['Authorization']);
          if (request.url.path == '/api/auth/token/refresh/') {
            return http.Response(
              jsonEncode({'access': 'new-access-token'}),
              200,
            );
          }
          return http.Response(jsonEncode({'results': []}), 200);
        }),
      );

      final response = await client.get<Map<String, dynamic>>(
        '/mentor-profiles/',
        decoder: (json) => json as Map<String, dynamic>,
      );

      expect(response.success, true);
      expect(paths, ['/api/auth/token/refresh/', '/api/mentor-profiles/']);
      expect(authHeaders.last, 'Bearer new-access-token');
      expect(storage.accessToken, 'new-access-token');
    });

    test(
      'refreshes and retries once after protected request gets 401',
      () async {
        final storage = _FakeTokenStorage(
          accessToken: 'expired-access-token',
          refreshToken: 'test-refresh-token',
        );
        var mentorProfilesCalls = 0;
        final authHeaders = <String?>[];
        final client = ApiClient(
          baseUrl: 'https://api.example.test/api',
          networkInfo: _OnlineNetworkInfo(),
          tokenStorage: storage,
          httpClient: MockClient((request) async {
            authHeaders.add(request.headers['Authorization']);
            if (request.url.path == '/api/auth/token/refresh/') {
              return http.Response(
                jsonEncode({'access_token': 'fresh-access-token'}),
                200,
              );
            }
            mentorProfilesCalls++;
            if (mentorProfilesCalls == 1) {
              return http.Response(jsonEncode({'detail': 'Expired'}), 401);
            }
            return http.Response(jsonEncode({'results': []}), 200);
          }),
        );

        final response = await client.get<Map<String, dynamic>>(
          '/mentor-profiles/',
          decoder: (json) => json as Map<String, dynamic>,
        );

        expect(response.success, true);
        expect(mentorProfilesCalls, 2);
        expect(authHeaders.first, 'Bearer expired-access-token');
        expect(authHeaders.last, 'Bearer fresh-access-token');
        expect(storage.wasCleared, false);
      },
    );

    test('refreshes and retries protected POST after 401', () async {
      final storage = _FakeTokenStorage(
        accessToken: 'expired-access-token',
        refreshToken: 'old-refresh-token',
      );
      var conversationCalls = 0;
      final authHeaders = <String?>[];
      final client = ApiClient(
        baseUrl: 'https://api.example.test/api',
        networkInfo: _OnlineNetworkInfo(),
        tokenStorage: storage,
        httpClient: MockClient((request) async {
          authHeaders.add(request.headers['Authorization']);
          if (request.url.path == '/api/auth/token/refresh/') {
            return http.Response(
              jsonEncode({
                'access_token': 'fresh-access-token',
                'refresh_token': 'new-refresh-token',
              }),
              200,
            );
          }
          conversationCalls++;
          if (conversationCalls == 1) {
            return http.Response(
              jsonEncode({'detail': 'Token is expired'}),
              401,
            );
          }
          return http.Response(jsonEncode({'id': 12}), 200);
        }),
      );

      final response = await client.post<Map<String, dynamic>>(
        '/conversations/',
        body: const JsonRequestBody({'type': 'inquiry', 'mentor_id': 2}),
        decoder: (json) => json as Map<String, dynamic>,
      );

      expect(response.success, true);
      expect(conversationCalls, 2);
      expect(authHeaders.first, 'Bearer expired-access-token');
      expect(authHeaders.last, 'Bearer fresh-access-token');
      expect(storage.accessToken, 'fresh-access-token');
      expect(storage.refreshToken, 'new-refresh-token');
      expect(storage.wasCleared, false);
    });

    test('surfaces browser-blocked request errors', () {
      final exception = ErrorHandler.fromObject(
        http.ClientException('XMLHttpRequest error.'),
      );

      expect(exception.message, ErrorHandler.browserBlockedMessage);
      expect(exception.statusCode, isNull);
    });
  });
}

String _contentType(http.Request request) {
  return request.headers.entries
      .firstWhere((entry) => entry.key.toLowerCase() == 'content-type')
      .value;
}

class _OnlineNetworkInfo extends NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

class _FakeTokenStorage extends TokenStorage {
  _FakeTokenStorage({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;
  bool wasCleared = false;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveAccessToken(String token) async => accessToken = token;

  @override
  Future<void> saveRefreshToken(String token) async => refreshToken = token;

  @override
  Future<void> clear() async {
    wasCleared = true;
    accessToken = null;
    refreshToken = null;
  }
}

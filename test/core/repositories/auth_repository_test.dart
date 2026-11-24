import 'package:flutter_test/flutter_test.dart';
import 'package:mentorship/core/models/api_models.dart';
import 'package:mentorship/core/models/app_user.dart';
import 'package:mentorship/core/network/api_exception.dart';
import 'package:mentorship/core/network/api_response.dart';
import 'package:mentorship/core/network/error_handler.dart';
import 'package:mentorship/core/network/micro_mentor_api.dart';
import 'package:mentorship/core/repositories/auth_repository.dart';
import 'package:mentorship/core/storage/token_storage.dart';
import 'package:mentorship/core/utils/result.dart';

void main() {
  group('AuthRepository', () {
    test('login saves tokens without requiring a profile request', () async {
      final api = _LoginApi();
      final tokenStorage = _FakeTokenStorage();
      final repository = AuthRepository(api: api, tokenStorage: tokenStorage);

      final result = await repository.login(
        'mentee@example.com',
        'SuperSecure123',
      );

      expect(result, isA<Success<AuthSession>>());
      expect(tokenStorage.accessToken, 'access-token');
      expect(tokenStorage.refreshToken, 'refresh-token');
      expect(api.profileCalls, 0);
    });
  });
}

class _LoginApi extends MicroMentorApi {
  var profileCalls = 0;

  @override
  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    return const ApiResponse.success(
      AuthResponse(
        id: 1,
        email: 'mentee@example.com',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        role: UserRole.mentee,
      ),
    );
  }

  @override
  Future<ApiResponse<ProfileResponse>> getProfile() async {
    profileCalls++;
    return const ApiResponse.failure(
      ApiException(
        message: ErrorHandler.unauthorizedMessage,
        type: ApiExceptionType.unauthorized,
        statusCode: 401,
      ),
    );
  }
}

class _FakeTokenStorage extends TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> saveAccessToken(String token) async => accessToken = token;

  @override
  Future<void> saveRefreshToken(String token) async => refreshToken = token;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

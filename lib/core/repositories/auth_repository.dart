import '../models/app_user.dart';
import '../models/api_models.dart';
import '../models/mentor_onboarding.dart';
import '../network/api_exception.dart';
import '../network/error_handler.dart';
import '../network/micro_mentor_api.dart';
import '../storage/token_storage.dart';
import '../utils/result.dart';

class AuthRepository {
  AuthRepository({MicroMentorApi? api, TokenStorage? tokenStorage})
    : _api = api ?? MicroMentorApi(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final MicroMentorApi _api;
  final TokenStorage _tokenStorage;

  Future<Result<AuthSession>> login(String email, String password) async {
    final response = await _api.login(email: email, password: password);
    if (!response.success) return Failure(response.error!);

    try {
      final session = _sessionFromAuthResponse(
        response.data,
        fallbackEmail: email,
      );
      await _tokenStorage.saveTokens(
        accessToken: session.token,
        refreshToken: session.refreshToken,
      );

      return Success(session);
    } catch (error) {
      return Failure(
        ApiException(
          message: ErrorHandler.invalidFormatMessage,
          type: ApiExceptionType.parseError,
          rawData: response.data ?? error,
        ),
      );
    }
  }

  Future<Result<AuthSession>> register(
    String firstName,
    String lastName,
    String email,
    String password,
    UserRole role,
  ) async {
    final response = await _api.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      role: role.name,
    );
    if (!response.success) return Failure(response.error!);

    try {
      final session = _sessionFromAuthResponse(
        response.data,
        fallbackEmail: email,
        fallbackFirstName: firstName,
        fallbackLastName: lastName,
        fallbackRole: role,
      );
      await _tokenStorage.saveTokens(
        accessToken: session.token,
        refreshToken: session.refreshToken,
      );
      return Success(session);
    } catch (error) {
      return Failure(
        ApiException(
          message: ErrorHandler.invalidFormatMessage,
          type: ApiExceptionType.parseError,
          rawData: response.data ?? error,
        ),
      );
    }
  }

  Future<void> logout() async {
    await _api.logout();
    await _tokenStorage.clear();
  }

  Future<void> clearLocalSession() => _tokenStorage.clear();

  Future<String?> getToken() => _tokenStorage.readAccessToken();

  Future<Result<AppUser>> getCurrentUser() async {
    final response = await _api.getProfile();
    if (!response.success) return Failure(response.error!);
    final profile = response.data;
    if (profile == null) {
      return const Failure(
        ApiException(
          message: ErrorHandler.invalidFormatMessage,
          type: ApiExceptionType.parseError,
        ),
      );
    }
    return Success(_userFromProfile(profile));
  }

  AppUser _userFromProfile(ProfileResponse profile) {
    final nameParts = profile.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    return AppUser.fromJson({
      'id': profile.email,
      'email': profile.email,
      'first_name': nameParts.isEmpty ? '' : nameParts.first,
      'last_name': nameParts.length <= 1 ? '' : nameParts.skip(1).join(' '),
      'role': profile.role.name,
      'mentor_profile_id': profile.mentorProfileId,
    });
  }

  AuthSession _sessionFromAuthResponse(
    AuthResponse? payload, {
    required String fallbackEmail,
    String? fallbackFirstName,
    String? fallbackLastName,
    UserRole? fallbackRole,
  }) {
    if (payload == null || payload.accessToken.isEmpty) {
      throw const FormatException('Missing access token');
    }
    return AuthSession(
      token: payload.accessToken,
      refreshToken: payload.refreshToken,
      onboarding: payload.onboarding,
      user: payload.toUser(
        fallbackEmail: fallbackEmail,
        firstName: fallbackFirstName ?? '',
        lastName: fallbackLastName ?? '',
        fallbackRole: fallbackRole ?? payload.role ?? UserRole.mentee,
      ),
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    this.refreshToken,
    this.onboarding,
  });

  final String token;
  final String? refreshToken;
  final MentorOnboardingSummary? onboarding;
  final AppUser user;
}

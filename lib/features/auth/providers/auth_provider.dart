import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/mentor_onboarding.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/result.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(api: ref.watch(microMentorApiProvider)),
);

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.error,
    this.fieldErrors = const {},
    this.mentorOnboardingRequired = false,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? token;
  final ApiException? error;
  final Map<String, List<String>> fieldErrors;
  final bool mentorOnboardingRequired;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? token,
    ApiException? error,
    Map<String, List<String>>? fieldErrors,
    bool? mentorOnboardingRequired,
    bool clearError = false,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    token: token ?? this.token,
    error: clearError ? null : error ?? this.error,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    mentorOnboardingRequired:
        mentorOnboardingRequired ?? this.mentorOnboardingRequired,
  );
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    try {
      final token = await _repository.getToken();
      if (token == null) {
        return const AuthState(status: AuthStatus.unauthenticated);
      }
      final profile = await _repository.getCurrentUser();
      switch (profile) {
        case Success(data: final user):
          return AuthState(
            status: AuthStatus.authenticated,
            token: token,
            user: user,
            mentorOnboardingRequired: await _requiresMentorOnboarding(
              user.role,
            ),
          );
        case Failure():
          return const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<Result<UserRole>> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await _repository.login(email, password);
    switch (result) {
      case Success(data: final session):
        return _completeAuth(
          session,
          mentorOnboardingRequired: await _requiresMentorOnboarding(
            session.user.role,
            onboarding: session.onboarding,
          ),
        );
      case Failure(error: final error):
        return _failAuth(error);
    }
  }

  Future<Result<UserRole>> register(
    String firstName,
    String lastName,
    String email,
    String password,
    UserRole role,
  ) async {
    state = const AsyncLoading();
    final result = await _repository.register(
      firstName,
      lastName,
      email,
      password,
      role,
    );
    return switch (result) {
      Success(data: final session) => _completeAuth(
        session,
        mentorOnboardingRequired: session.user.role == UserRole.mentor,
      ),
      Failure(error: final error) => _failAuth(error),
    };
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _repository.logout();
    } catch (_) {
      await _repository.clearLocalSession();
    }
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }

  Future<bool> _requiresMentorOnboarding(
    UserRole role, {
    MentorOnboardingSummary? onboarding,
  }) async {
    if (role != UserRole.mentor) return false;
    if (onboarding != null) return onboarding.status != 'verified';
    try {
      final response = await ref
          .read(microMentorApiProvider)
          .getMentorOnboardingStatus();
      return !response.success || response.data?.isVerified != true;
    } catch (_) {
      // Keep mentors in the recoverable onboarding flow when status is
      // temporarily unavailable instead of incorrectly exposing the dashboard.
      return true;
    }
  }

  Result<UserRole> _completeAuth(
    AuthSession session, {
    bool? mentorOnboardingRequired,
  }) {
    state = AsyncData(
      AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
        token: session.token,
        fieldErrors: const {},
        mentorOnboardingRequired:
            mentorOnboardingRequired ?? session.onboarding != null,
      ),
    );
    return Success(session.user.role);
  }

  Result<UserRole> _failAuth(ApiException error) {
    state = AsyncData(
      AuthState(
        status: AuthStatus.unauthenticated,
        error: error,
        fieldErrors: error.fieldErrors,
      ),
    );
    return Failure(error);
  }
}

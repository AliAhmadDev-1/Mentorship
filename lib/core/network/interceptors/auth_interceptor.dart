import '../../storage/token_storage.dart';
import '../session_expiration_notifier.dart';

class AuthInterceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;
  bool _isClearingSession = false;

  Future<Map<String, String>> authHeaders({bool authorized = true}) async {
    if (!authorized) return const {};
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> handleUnauthorized() async {
    if (_isClearingSession) return;
    _isClearingSession = true;
    try {
      await _tokenStorage.clear();
      sessionExpirationNotifier.notifyExpired();
    } finally {
      _isClearingSession = false;
    }
  }
}

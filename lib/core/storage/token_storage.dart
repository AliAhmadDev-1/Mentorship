import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_strings.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: AppStrings.tokenKey);

  Future<String?> readRefreshToken() =>
      _storage.read(key: AppStrings.refreshTokenKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: AppStrings.tokenKey, value: token);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: AppStrings.refreshTokenKey, value: token);

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await saveRefreshToken(refreshToken);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: AppStrings.tokenKey);
    await _storage.delete(key: AppStrings.refreshTokenKey);
  }
}

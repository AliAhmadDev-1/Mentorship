import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_strings.dart';

class OnboardingStorage {
  OnboardingStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<bool> hasCompletedOnboarding() async {
    final value = await _storage.read(key: AppStrings.onboardingCompletedKey);
    return value == 'true';
  }

  Future<void> markCompleted() =>
      _storage.write(key: AppStrings.onboardingCompletedKey, value: 'true');
}

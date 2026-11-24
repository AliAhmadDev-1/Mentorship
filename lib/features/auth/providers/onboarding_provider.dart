import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/onboarding_storage.dart';

final onboardingStorageProvider = Provider<OnboardingStorage>(
  (ref) => OnboardingStorage(),
);

final onboardingProvider = AsyncNotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends AsyncNotifier<bool> {
  OnboardingStorage get _storage => ref.read(onboardingStorageProvider);

  @override
  Future<bool> build() async {
    try {
      return await _storage.hasCompletedOnboarding();
    } catch (_) {
      return false;
    }
  }

  Future<void> complete() async {
    await _storage.markCompleted();
    state = const AsyncData(true);
  }
}

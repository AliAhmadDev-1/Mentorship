import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorship/app.dart';
import 'package:mentorship/core/repositories/auth_repository.dart';
import 'package:mentorship/core/storage/onboarding_storage.dart';
import 'package:mentorship/features/auth/providers/auth_provider.dart';
import 'package:mentorship/features/auth/providers/onboarding_provider.dart';

void main() {
  testWidgets('Micro-Mentor app boots', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MicroMentorApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'Splash routes to onboarding when onboarding state is unavailable',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingStorageProvider.overrideWithValue(
              _FailingOnboardingStorage(),
            ),
          ],
          child: const MicroMentorApp(),
        ),
      );

      await tester.pump();

      await tester.pump(const Duration(milliseconds: 2300));
      await tester.pumpAndSettle();

      expect(find.text('Learn from the Best Experts'), findsOneWidget);
    },
  );

  testWidgets('Splash routes to login when auth state is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith(_CompletedOnboardingNotifier.new),
          authRepositoryProvider.overrideWithValue(_FailingAuthRepository()),
        ],
        child: const MicroMentorApp(),
      ),
    );

    await tester.pump();

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
  });
}

class _CompletedOnboardingNotifier extends OnboardingNotifier {
  @override
  Future<bool> build() async => true;
}

class _FailingOnboardingStorage extends OnboardingStorage {
  @override
  Future<bool> hasCompletedOnboarding() async =>
      throw StateError('storage unavailable');
}

class _FailingAuthRepository extends AuthRepository {
  @override
  Future<String?> getToken() async => throw StateError('auth unavailable');
}

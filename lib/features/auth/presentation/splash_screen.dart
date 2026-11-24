import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _routeAfterSplash();
  }

  Future<void> _routeAfterSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    try {
      final hasCompletedOnboarding = await ref.read(onboardingProvider.future);
      if (!mounted) return;
      if (!hasCompletedOnboarding) {
        context.go('/onboarding');
        return;
      }
      final auth = await ref.read(authProvider.future);
      if (!mounted) return;
      if (auth.status != AuthStatus.authenticated) {
        context.go('/auth/login');
        return;
      }
      if (auth.user?.role == UserRole.mentor) {
        context.go(
          auth.mentorOnboardingRequired ? '/mentor/onboarding' : '/dashboard',
        );
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (!mounted) return;
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.darkest,
                  size: 44,
                ),
              ).animate().fadeIn(duration: 500.ms).scale(duration: 500.ms),
              const SizedBox(height: 20),
              Text(
                'Micro Mentor',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) =>
                      Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scale(
                            begin: const Offset(.5, .5),
                            end: const Offset(1, 1),
                            delay: (i * 120).ms,
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

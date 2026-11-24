import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/onboarding_provider.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/booking/presentation/payment_screen.dart';
import '../../features/dashboard/presentation/mentor_dashboard_screen.dart';
import '../../features/discovery/presentation/discovery_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/mentor_profile/presentation/mentor_profile_screen.dart';
import '../../features/mentor_onboarding/presentation/mentor_onboarding_screen.dart';
import '../../features/messages/presentation/chat_screen.dart';
import '../../features/messages/presentation/messages_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_mentor_profile_screen.dart';
import '../../features/profile/presentation/mentor_services_screen.dart';
import '../../features/profile/providers/role_provider.dart';
import '../../features/review/presentation/review_screen.dart';
import '../../features/review/presentation/reviews_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/session/presentation/video_session_screen.dart';
import '../../features/session/presentation/sessions_screen.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../models/app_user.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final role = ref.watch(roleProvider);
  final authState = ref.read(authProvider).valueOrNull;
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation:
        role == UserRole.mentor && authState?.mentorOnboardingRequired == true
        ? '/mentor/onboarding'
        : '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final onboarding = ref.read(onboardingProvider);
      final role = ref.read(roleProvider);
      if (auth.isLoading || onboarding.isLoading) return null;
      final location = state.uri.path;
      final authState = auth.valueOrNull;
      final hasCompletedOnboarding = onboarding.valueOrNull ?? false;
      final isPublic =
          location == '/splash' ||
          location == '/onboarding' ||
          location.startsWith('/auth/');

      if (!hasCompletedOnboarding) {
        return location == '/onboarding' || location == '/splash'
            ? null
            : '/onboarding';
      }

      if (authState?.status != AuthStatus.authenticated) {
        if (location == '/splash' || location == '/onboarding') {
          return '/auth/login';
        }
        return isPublic ? null : '/auth/login';
      }

      final roleHome = role == UserRole.mentor
          ? authState!.mentorOnboardingRequired
                ? '/mentor/onboarding'
                : '/dashboard'
          : '/home';
      if (location == '/auth/register' && role == UserRole.mentor) {
        return '/mentor/onboarding';
      }
      if (location == '/splash' ||
          location == '/onboarding' ||
          location.startsWith('/auth/')) {
        return roleHome;
      }

      if (role == UserRole.mentor &&
          (location == '/home' ||
              location == '/discover' ||
              location.startsWith('/book/') ||
              location.startsWith('/payment/') ||
              location.startsWith('/review/'))) {
        return roleHome;
      }

      if (role == UserRole.mentee &&
          (location == '/dashboard' ||
              location == '/schedule' ||
              location.startsWith('/profile/edit/') ||
              location.startsWith('/services/'))) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/mentor/onboarding',
        builder: (context, state) => const MentorOnboardingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/mentor/:id',
        builder: (context, state) =>
            MentorProfileScreen(mentorId: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/book/:mentorId',
        builder: (context, state) =>
            BookingScreen(mentorId: state.pathParameters['mentorId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/payment/:bookingId',
        builder: (context, state) =>
            PaymentScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sessions-list',
        builder: (context, state) => const SessionsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/session/:bookingId',
        builder: (context, state) =>
            VideoSessionScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/review/:bookingId',
        builder: (context, state) =>
            ReviewScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reviews',
        builder: (context, state) => ReviewsScreen(
          mentorId: state.uri.queryParameters['mentorId'],
          canManage: state.uri.queryParameters['manage'] == 'true',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile/edit/:mentorId',
        builder: (context, state) => EditMentorProfileScreen(
          mentorId: state.pathParameters['mentorId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/services/:mentorId',
        builder: (context, state) =>
            MentorServicesScreen(mentorId: state.pathParameters['mentorId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/chat/:conversationId',
        builder: (context, state) =>
            ChatScreen(conversationId: state.pathParameters['conversationId']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _Shell(navigationShell: navigationShell, role: role),
        branches: role == UserRole.mentor ? _mentorBranches : _menteeBranches,
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(onboardingProvider, (_, __) => notifyListeners());
  }
}

final _menteeBranches = [
  StatefulShellBranch(
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/discover',
        builder: (context, state) => const DiscoveryScreen(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/messages',
        builder: (context, state) => const MessagesScreen(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  ),
];

final _mentorBranches = [
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MentorDashboardScreen(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/messages',
        builder: (context, state) => const MessagesScreen(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const ScheduleScreen(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  ),
];

class _Shell extends StatelessWidget {
  const _Shell({required this.navigationShell, required this.role});

  final StatefulNavigationShell navigationShell;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        navigationShell: navigationShell,
        role: role,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/network/error_handler.dart';
import 'core/network/session_expiration_notifier.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';

class MicroMentorApp extends ConsumerWidget {
  const MicroMentorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Micro-Mentor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => _SessionExpirationListener(
        router: router,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class _SessionExpirationListener extends StatefulWidget {
  const _SessionExpirationListener({required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<_SessionExpirationListener> createState() =>
      _SessionExpirationListenerState();
}

class _SessionExpirationListenerState
    extends State<_SessionExpirationListener> {
  @override
  void initState() {
    super.initState();
    sessionExpirationNotifier.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    sessionExpirationNotifier.removeListener(_onSessionExpired);
    super.dispose();
  }

  void _onSessionExpired() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.router.go('/auth/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ErrorHandler.unauthorizedMessage)),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

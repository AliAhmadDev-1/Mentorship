import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/api_models.dart';
import '../../../core/models/app_user.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/role_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull?.user;
    final role = ref.watch(roleProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final profileResponse = ref.watch(profileProvider(user?.id));
    final profile = profileResponse.valueOrNull?.data;
    final dashboardMentorId = role == UserRole.mentor
        ? ref.watch(dashboardProvider).valueOrNull?.mentorId
        : null;
    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final resolvedRole = profile?.role ?? role;
            final resolvedName = profile?.name.trim().isNotEmpty == true
                ? profile!.name
                : user?.fullName ?? 'MicroMentor user';
            final resolvedEmail = profile?.email.trim().isNotEmpty == true
                ? profile!.email
                : user?.email ?? '';
            final mentorProfileId =
                user?.mentorProfileId ??
                profile?.mentorProfileId?.toString() ??
                dashboardMentorId?.toString();
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: AppAvatar(
                    initials: user?.avatarInitials ?? _initials(resolvedName),
                    colorValue: resolvedRole == UserRole.mentor
                        ? 0xFFF0BF63
                        : 0xFF53D6B4,
                    size: 84,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  resolvedName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(resolvedEmail, textAlign: TextAlign.center),
                Center(
                  child: Chip(
                    label: Text(
                      resolvedRole == UserRole.mentor ? 'Mentor' : 'Mentee',
                    ),
                    backgroundColor: resolvedRole == UserRole.mentor
                        ? AppColors.gold.withValues(alpha: .12)
                        : AppColors.primarySoft,
                  ),
                ),
                const SizedBox(height: 18),
                _ProfileStats(profile: profile, role: resolvedRole),
                const SizedBox(height: 18),
                if (resolvedRole == UserRole.mentor &&
                    mentorProfileId != null) ...[
                  _MenuItem(
                    label: 'Edit Profile',
                    icon: Icons.edit_outlined,
                    onTap: () async {
                      await context.push('/profile/edit/$mentorProfileId');
                      ref.invalidate(profileProvider);
                    },
                  ),
                  _MenuItem(
                    label: 'Services',
                    icon: Icons.sell_outlined,
                    onTap: () => context.push('/services/$mentorProfileId'),
                  ),
                  _MenuItem(
                    label: 'Availability',
                    icon: Icons.calendar_month_outlined,
                    onTap: () => context.go('/schedule'),
                  ),
                  _MenuItem(
                    label: 'My Sessions',
                    icon: Icons.event_note_outlined,
                    onTap: () => context.push('/sessions-list'),
                  ),
                  _MenuItem(
                    label: 'Reviews Received',
                    icon: Icons.reviews_outlined,
                    onTap: () =>
                        context.push('/reviews?mentorId=$mentorProfileId'),
                  ),
                  _MenuItem(
                    label: 'Verification',
                    icon: Icons.verified_user_outlined,
                    onTap: () => context.push('/mentor/onboarding'),
                  ),
                ] else if (resolvedRole == UserRole.mentee) ...[
                  _MenuItem(
                    label: 'My Sessions',
                    icon: Icons.event_note_outlined,
                    onTap: () => context.push('/sessions-list'),
                  ),
                  _MenuItem(
                    label: 'My Reviews',
                    icon: Icons.rate_review_outlined,
                    onTap: () => context.push('/reviews?manage=true'),
                  ),
                ],
                GlassCard(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isDarkMode,
                    onChanged: (_) =>
                        ref.read(themeModeProvider.notifier).toggle(),
                    title: const Text('Dark Mode'),
                    secondary: const Icon(Icons.dark_mode_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  label: 'Sign Out',
                  icon: Icons.logout,
                  onTap: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) context.go('/auth/login');
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.profile, required this.role});

  final ProfileResponse? profile;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat('Sessions', '${profile?.sessions ?? 0}')),
        Expanded(
          child: _Stat(
            role == UserRole.mentor ? 'Earned' : 'Spent',
            '\$${(profile?.spentUsd ?? 0).toStringAsFixed(0)}',
          ),
        ),
        Expanded(
          child: _Stat(role == UserRole.mentor ? 'Mentees' : 'Mentors', '-'),
        ),
      ],
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return '?';
  final first = parts.first[0];
  final last = parts.length > 1 ? parts.last[0] : '';
  return '$first$last'.toUpperCase();
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(4),
    child: GlassCard(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

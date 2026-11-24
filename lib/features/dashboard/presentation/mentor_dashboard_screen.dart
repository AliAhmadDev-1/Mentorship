import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/availability.dart';
import '../../../core/providers/api_provider.dart';
import '../../../shared/extensions/date_extensions.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/section_header.dart';
import '../../mentor_onboarding/providers/mentor_onboarding_provider.dart';
import '../../schedule/providers/availability_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class MentorDashboardScreen extends ConsumerWidget {
  const MentorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final availability = ref.watch(availabilityProvider);
    final user = ref.watch(authProvider).valueOrNull?.user;
    final profile = ref.watch(profileProvider(user?.id));
    final onboardingState = ref.watch(mentorOnboardingProvider);
    final onboardingDraft = onboardingState.valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: dashboard.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: LoadingShimmer(count: 6),
          ),
          error: (error, stack) => ErrorStateWidget(
            title: 'Dashboard failed',
            message: '$error',
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Good morning, ${_firstName(profile.valueOrNull?.data?.name ?? user?.fullName ?? 'Mentor')}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  AppAvatar(
                    initials: _initials(
                      profile.valueOrNull?.data?.name ??
                          user?.fullName ??
                          'Mentor',
                    ),
                    colorValue: 0xFFF0BF63,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (onboardingDraft != null && !onboardingDraft.isVerified) ...[
                _OnboardingStatusBanner(
                  draft: onboardingDraft,
                  onTap: () => context.push('/mentor/onboarding'),
                ),
                const SizedBox(height: 14),
              ],
              GlassCard(
                color: AppColors.gold.withValues(alpha: .16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${data.earnings.thisMonth.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(color: AppColors.gold),
                    ),
                    const Text('Total earnings'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Metric('Sessions', '${data.earnings.sessionsCount}'),
                        _Metric(
                          'Rating (${data.earnings.reviewCount})',
                          '${data.earnings.avgRating}',
                        ),
                        _Metric('Repeat', '${data.earnings.repeatClientPct}%'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (onboardingDraft?.isVerified == true) ...[
                      const Chip(
                        label: Text('Verified Mentor · Payouts Ready'),
                        avatar: Icon(
                          Icons.verified,
                          color: AppColors.primary,
                        ),
                      ),
                    ] else ...[
                      Chip(
                        label: Text(
                          'Status: ${onboardingDraft?.status.replaceAll('_', ' ') ?? 'Pending verification'}',
                        ),
                        avatar: const Icon(
                          Icons.shield_outlined,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeader(title: "Today's Sessions"),
              for (final booking in data.todaySessions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: Row(
                      children: [
                        AppAvatar(
                          initials: booking.mentor.avatarInitials,
                          colorValue: booking.mentor.avatarColorValue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${booking.mentor.name}\n${booking.sessionGoal}',
                          ),
                        ),
                        Text(booking.scheduledAt.timeLabel),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Weekly Availability'),
              availability.when(
                loading: () => const LoadingShimmer(count: 1),
                error: (error, stack) => GlassCard(child: Text('$error')),
                data: (items) => GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_availabilitySummary(items)),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: _availabilityRatio(items)),
                      const SizedBox(height: 8),
                      Text(
                        '${(_availabilityRatio(items) * 100).round()}% availability setup',
                      ),
                    ],
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

String _firstName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Mentor';
  return trimmed.split(RegExp(r'\s+')).first;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'M';
  final first = parts.first[0];
  final last = parts.length > 1 ? parts.last[0] : '';
  return '$first$last'.toUpperCase();
}

String _availabilitySummary(List<Availability> items) {
  final active = items.where((item) => item.isEnabled && item.slots.isNotEmpty);
  if (active.isEmpty) return 'No active availability windows';
  return active
      .map((item) {
        final first = item.slots.first;
        return '${item.day} ${first.startTime}-${first.endTime}';
      })
      .join(' · ');
}

double _availabilityRatio(List<Availability> items) {
  if (items.isEmpty) return 0;
  final active = items.where((item) => item.isEnabled && item.slots.isNotEmpty);
  return active.length / items.length;
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _OnboardingStatusBanner extends StatelessWidget {
  const _OnboardingStatusBanner({
    required this.draft,
    required this.onTap,
  });

  final MentorOnboardingDraft draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (title, message, icon, color, buttonLabel) = switch (draft.status) {
      'pending_review' => (
        'Application Under Review',
        'Your profile is currently under review by staff. You will become bookable once verified.',
        Icons.hourglass_top_rounded,
        AppColors.gold,
        'View Status',
      ),
      'changes_requested' => (
        'Changes Requested',
        draft.reviewNotes ??
            'Staff requested updates to your application. Please revise and resubmit.',
        Icons.error_outline_rounded,
        AppColors.error,
        'Edit Application',
      ),
      'rejected' => (
        'Application Not Approved',
        draft.reviewNotes ??
            'Your mentor application could not be approved at this time.',
        Icons.cancel_outlined,
        AppColors.error,
        'View Details',
      ),
      _ => (
        'Onboarding Incomplete (${draft.completionPercent}%)',
        'Complete all required steps to submit your profile and start accepting bookings.',
        Icons.assignment_outlined,
        AppColors.primary,
        'Resume Onboarding',
      ),
    };

    return GlassCard(
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: color,
              ),
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

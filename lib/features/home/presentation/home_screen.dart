import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/booking.dart';
import '../../../shared/extensions/date_extensions.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../discovery/presentation/mentor_card_horizontal.dart';
import '../../discovery/providers/mentor_provider.dart';
import '../providers/home_provider.dart';
import '../repositories/home_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final loadedHome = home.valueOrNull;
    final user = ref.watch(authProvider).valueOrNull?.user;
    final displayName =
        _firstName(loadedHome?.userName) ?? user?.firstName ?? 'there';
    final categories = loadedHome?.categories ?? const <HomeCategory>[];
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(homeProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Good morning'),
                          Text(
                            'Hey, $displayName',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                    const IconButton(
                      tooltip: 'Notifications unavailable',
                      onPressed: null,
                      icon: Icon(Icons.notifications_rounded),
                    ),
                    AppAvatar(
                      initials: user?.avatarInitials ?? 'AM',
                      colorValue: 0xFF53D6B4,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => context.go('/discover'),
                  child: const AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search mentors, skills, companies',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CategoryPill(
                          label: 'All',
                          isSelected: true,
                          onTap: () => context.go('/discover'),
                        ),
                      ),
                      ...categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _CategoryPill(
                            label: category.name,
                            isSelected: false,
                            onTap: () {
                              ref
                                  .read(mentorProvider.notifier)
                                  .refresh(category: category.name);
                              context.go('/discover');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                home.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: LoadingShimmer(count: 4),
                  ),
                  error: (error, stack) => ErrorStateWidget(
                    title: 'Could not load home',
                    message: '$error',
                    onRetry: () => ref.invalidate(homeProvider),
                  ),
                  data: (data) {
                    final booking = data.upcoming;
                    final topics = data.categories
                        .take(9)
                        .map(_topicDataFromCategory)
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (booking != null) ...[
                          const SizedBox(height: 18),
                          _UpcomingSessionCard(
                            booking: booking,
                            onJoin: () => booking.status == 'pending_payment'
                                ? context.push('/payment/${booking.id}')
                                : context.push('/session/${booking.id}'),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Featured Mentors',
                          action: 'View all',
                          onAction: () => context.go('/discover'),
                        ),
                        const SizedBox(height: 12),
                        if (data.featured.isEmpty)
                          const _HomeEmptyCard(
                            icon: Icons.school_outlined,
                            title: 'No featured mentors yet',
                            message:
                                'Featured mentors from the server will appear here.',
                          )
                        else
                          RepaintBoundary(
                            child: SizedBox(
                              height: 218,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (_, i) => MentorCardHorizontal(
                                  mentor: data.featured[i],
                                ),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemCount: data.featured.length,
                              ),
                            ),
                          ),
                        if (topics.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const SectionHeader(title: 'Browse by Topic'),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 390;
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: isCompact ? 2 : 3,
                                childAspectRatio: isCompact ? 1.55 : 1.05,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                children: topics
                                    .map(
                                      (topic) => _TopicCard(
                                        topic: topic,
                                        onTap: () {
                                          ref
                                              .read(mentorProvider.notifier)
                                              .refresh(category: topic.title);
                                          context.go('/discover');
                                        },
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                          const _HomeEmptyCard(
                            icon: Icons.category_outlined,
                            title: 'No topics yet',
                            message:
                                'Categories from the server will appear here.',
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeEmptyCard extends StatelessWidget {
  const _HomeEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _secondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _firstName(String? name) {
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.split(RegExp(r'\s+')).first;
}

Color _secondaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textSecondary
      : AppColors.lightTextSecondary;
}

class _UpcomingSessionCard extends StatelessWidget {
  const _UpcomingSessionCard({required this.booking, required this.onJoin});

  final Booking booking;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final accentSurface = isDark
        ? AppColors.primary.withValues(alpha: .12)
        : AppColors.primary.withValues(alpha: .09);

    return GlassCard(
      padding: EdgeInsets.zero,
      color: cardColor,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Container(height: 3, color: AppColors.primary),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accentSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.video_camera_front_rounded,
                          color: AppColors.primary,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upcoming session',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${booking.scheduledAt.shortDate} · ${booking.scheduledAt.timeLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      _TimePill(minutes: booking.durationMinutes),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      AppAvatar(
                        initials: booking.mentor.avatarInitials,
                        colorValue: booking.mentor.avatarColorValue,
                        size: 46,
                        verified: booking.mentor.verified,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.mentor.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              booking.sessionGoal.isEmpty
                                  ? booking.mentor.title
                                  : booking.sessionGoal,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: onJoin,
                        icon: Icon(
                          booking.status == 'pending_payment'
                              ? Icons.payment_rounded
                              : Icons.play_arrow_rounded,
                          size: 18,
                        ),
                        label: Text(
                          booking.status == 'pending_payment'
                              ? 'Pay'
                              : 'Join',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.darkest,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gold.withValues(alpha: .24)),
      ),
      child: Text(
        '$minutes min',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isSelected
        ? AppColors.primary
        : isDark
        ? AppColors.surfaceHigh
        : AppColors.lightSurface;
    final foreground = isSelected
        ? AppColors.darkest
        : theme.colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isDark
                ? AppColors.borderActive
                : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

_TopicData _topicDataFromCategory(HomeCategory category) {
  final title = category.name.trim().isEmpty ? 'Topic' : category.name.trim();
  final count = category.mentorCount;
  return _TopicData(
    title,
    count == null ? 'Explore mentors' : '$count mentors',
    _topicIcon(title),
    _topicColor(category.id, title),
  );
}

IconData _topicIcon(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('mobile') || lower.contains('app')) {
    return Icons.phone_iphone_rounded;
  }
  if (lower.contains('web') || lower.contains('frontend')) {
    return Icons.language_rounded;
  }
  if (lower.contains('ai') || lower.contains('machine')) {
    return Icons.psychology_rounded;
  }
  if (lower.contains('design') || lower.contains('ux')) {
    return Icons.design_services_rounded;
  }
  if (lower.contains('career') || lower.contains('job')) {
    return Icons.work_rounded;
  }
  if (lower.contains('finance') || lower.contains('money')) {
    return Icons.account_balance_wallet_rounded;
  }
  if (lower.contains('startup') || lower.contains('business')) {
    return Icons.rocket_launch_rounded;
  }
  if (lower.contains('backend') || lower.contains('server')) {
    return Icons.dns_rounded;
  }
  return Icons.category_rounded;
}

Color _topicColor(int id, String title) {
  const colors = [
    Color(0xFF53D6B4),
    Color(0xFFF0BF63),
    Color(0xFFDE7C6B),
    Color(0xFF77A88B),
    Color(0xFFD989A4),
    Color(0xFF6FA7A0),
    Color(0xFF8BBF83),
    Color(0xFFE79B62),
    Color(0xFFB18A6E),
  ];
  final seed = id == 0 ? title.hashCode : id;
  return colors[seed.abs() % colors.length];
}

class _TopicData {
  const _TopicData(this.title, this.subtitle, this.icon, this.color);

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.onTap});

  final _TopicData topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      color: isDark
          ? Color.alphaBlend(
              topic.color.withValues(alpha: .08),
              AppColors.surface,
            )
          : Color.alphaBlend(topic.color.withValues(alpha: .08), Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: topic.color.withValues(alpha: isDark ? .18 : .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(topic.icon, color: topic.color, size: 22),
          ),
          const Spacer(),
          Text(
            topic.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            topic.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

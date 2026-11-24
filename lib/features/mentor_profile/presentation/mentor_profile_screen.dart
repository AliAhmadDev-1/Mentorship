import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/mentor.dart';
import '../../../core/models/review.dart';
import '../../../core/providers/api_provider.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_rating.dart';
import '../../home/providers/home_provider.dart';
import '../../messages/providers/message_provider.dart';
import '../../profile/providers/role_provider.dart';

class MentorProfileScreen extends ConsumerStatefulWidget {
  const MentorProfileScreen({super.key, required this.mentorId});

  final String mentorId;

  @override
  ConsumerState<MentorProfileScreen> createState() =>
      _MentorProfileScreenState();
}

class _MentorProfileScreenState extends ConsumerState<MentorProfileScreen> {
  late Future<_MentorProfileContent> _mentorFuture;
  bool _openingChat = false;

  @override
  void initState() {
    super.initState();
    _mentorFuture = _loadProfile();
  }

  @override
  void didUpdateWidget(covariant MentorProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mentorId != widget.mentorId) {
      _mentorFuture = _loadProfile();
    }
  }

  Future<void> _startConversation(Mentor mentor) async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    try {
      final conversation = await ref
          .read(conversationProvider.notifier)
          .startInquiry(mentorId: mentor.id);
      if (mounted) context.push('/chat/${conversation.id}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start conversation: $error')),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(roleProvider);
    return FutureBuilder(
      future: _mentorFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: ErrorStateWidget(
                title: 'Profile failed',
                message: '${snapshot.error}',
                onRetry: () {},
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snapshot.data!;
        final mentor = profile.mentor;
        final reviews = profile.reviews.take(3).toList();
        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  leading: IconButton(
                    onPressed: context.pop,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  actions: const [
                    IconButton(
                      tooltip: 'Share unavailable',
                      onPressed: null,
                      icon: Icon(Icons.share_rounded),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList.list(
                    children: [
                      Center(
                        child: AppAvatar(
                          initials: mentor.avatarInitials,
                          colorValue: mentor.avatarColorValue,
                          verified: mentor.verified,
                          size: 88,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        mentor.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        '${mentor.title} · ${mentor.company}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StarRating(rating: mentor.rating),
                            const SizedBox(width: 8),
                            Text(
                              '${mentor.ratingLabel} · ${mentor.reviewCount} reviews',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _Stat(
                            label: 'Sessions',
                            value: '${mentor.totalSessions}',
                          ),
                          _Stat(
                            label: 'Experience',
                            value: '${mentor.yearsExperience}y',
                          ),
                          _Stat(
                            label: 'Repeat',
                            value: '${mentor.repeatRate}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const SectionHeader(title: 'About'),
                      Text(mentor.bio),
                      const SizedBox(height: 18),
                      const SectionHeader(title: 'Expertise'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: mentor.expertise
                            .map((skill) => Chip(label: Text(skill)))
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      const SectionHeader(title: 'Pricing'),
                      Row(
                        children: [
                          for (final package in _profilePackages(mentor))
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GlassCard(
                                  child: Column(
                                    children: [
                                      Text('${package.durationMinutes} min'),
                                      if (package.isPopular)
                                        const Text(
                                          'POPULAR',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      Text(
                                        '\$${package.priceUsd.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SectionHeader(
                        title: 'Reviews',
                        action: profile.reviews.length > 3 ? 'See all' : null,
                        onAction: () =>
                            context.push('/reviews?mentorId=${mentor.id}'),
                      ),
                      if (reviews.isEmpty)
                        const GlassCard(child: Text('No reviews yet.'))
                      else
                        for (final review in reviews)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.userName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  StarRating(rating: review.rating),
                                  const SizedBox(height: 6),
                                  Text(review.comment),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: role == UserRole.mentor
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        '\$${mentor.ratePerSlot.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppColors.gold),
                      ),
                      const SizedBox(width: 14),
                      SizedBox.square(
                        dimension: 54,
                        child: IconButton.filledTonal(
                          tooltip: 'Message',
                          onPressed: _openingChat
                              ? null
                              : () => _startConversation(mentor),
                          icon: _openingChat
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.chat_bubble_rounded),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Book Session',
                          onPressed: () => context.push('/book/${mentor.id}'),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<_MentorProfileContent> _loadProfile() async {
    final mentor = await ref
        .read(mentorRepositoryProvider)
        .getMentorById(widget.mentorId);
    final response = await ref
        .read(microMentorApiProvider)
        .listReviews(mentorId: widget.mentorId);
    if (!response.success) throw response.error!;
    final reviews = (response.data?.results ?? const [])
        .map(
          (item) => Review(
            id: '${item.reviewId}',
            mentorId: item.mentorId?.toString() ?? widget.mentorId,
            userName: item.reviewer ?? 'MicroMentor user',
            rating: item.rating.toDouble(),
            comment: item.body ?? '',
            createdAt: item.createdAt ?? DateTime.now(),
            tags: const [],
          ),
        )
        .where((review) => review.comment.trim().isNotEmpty)
        .toList();
    return _MentorProfileContent(mentor: mentor, reviews: reviews);
  }
}

List<MentorPackage> _profilePackages(Mentor mentor) {
  if (mentor.packages.isNotEmpty) return mentor.packages;
  return [
    for (final minutes in [15, 30, 45])
      MentorPackage(
        id: '$minutes',
        durationMinutes: minutes,
        priceUsd: mentor.ratePerSlot * minutes / 15,
        isPopular: minutes == 30,
      ),
  ];
}

class _MentorProfileContent {
  const _MentorProfileContent({required this.mentor, required this.reviews});

  final Mentor mentor;
  final List<Review> reviews;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/mentor.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../providers/mentor_provider.dart';
import 'mentor_card_vertical.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _controller = ScrollController();
  final _search = TextEditingController();
  _MentorSort _sort = _MentorSort.recommended;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >
          _controller.position.maxScrollExtent - 260) {
        ref.read(mentorProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mentors = ref.watch(mentorProvider);
    return Scaffold(
      body: SafeArea(
        child: mentors.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: LoadingShimmer(count: 7),
          ),
          error: (error, stack) => ErrorStateWidget(
            title: 'Discovery failed',
            message: '$error',
            onRetry: () => ref.invalidate(mentorProvider),
          ),
          data: (data) {
            final sortedMentors = _sorted(data.mentors, _sort);
            return RefreshIndicator(
              onRefresh: () => ref.read(mentorProvider.notifier).refresh(),
              child: CustomScrollView(
                controller: _controller,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    sliver: SliverList.list(
                      children: [
                        Text(
                          'Discover',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _search,
                          onSubmitted: (value) => ref
                              .read(mentorProvider.notifier)
                              .refresh(query: value),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search by skill or mentor',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: data.categories.length,
                            itemBuilder: (context, index) {
                              final category = data.categories[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(category),
                                  selected: category == data.category,
                                  selectedColor: AppColors.primarySoft,
                                  onSelected: (_) => ref
                                      .read(mentorProvider.notifier)
                                      .refresh(category: category),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('${data.mentors.length} mentors'),
                            const Spacer(),
                            PopupMenuButton<_MentorSort>(
                              tooltip: 'Sort mentors',
                              initialValue: _sort,
                              onSelected: (value) =>
                                  setState(() => _sort = value),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: _MentorSort.recommended,
                                  child: Text('Recommended'),
                                ),
                                PopupMenuItem(
                                  value: _MentorSort.rating,
                                  child: Text('Highest rated'),
                                ),
                                PopupMenuItem(
                                  value: _MentorSort.priceLow,
                                  child: Text('Lowest price'),
                                ),
                              ],
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sort_rounded, size: 18),
                                  const SizedBox(width: 6),
                                  Text(_sort.label),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (data.mentors.isEmpty)
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: EmptyStateWidget(
                          icon: Icons.search_off_rounded,
                          title: 'No mentors found',
                          message: 'Try a different search or filter.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: data.mentors.length,
                        itemBuilder: (context, index) => RepaintBoundary(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MentorCardVertical(
                              mentor: sortedMentors[index],
                              index: index,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (data.isLoadingMore)
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: LoadingShimmer(count: 1),
                      ),
                    ),
                  if (!data.hasMore)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 20),
                      sliver: SliverToBoxAdapter(
                        child: Center(child: Text('No more mentors')),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _MentorSort { recommended, rating, priceLow }

extension on _MentorSort {
  String get label => switch (this) {
    _MentorSort.recommended => 'Recommended',
    _MentorSort.rating => 'Rating',
    _MentorSort.priceLow => 'Price',
  };
}

List<Mentor> _sorted(List<Mentor> mentors, _MentorSort sort) {
  final items = [...mentors];
  switch (sort) {
    case _MentorSort.recommended:
      break;
    case _MentorSort.rating:
      items.sort((a, b) => b.rating.compareTo(a.rating));
    case _MentorSort.priceLow:
      items.sort((a, b) => a.ratePerSlot.compareTo(b.ratePerSlot));
  }
  return items;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/mentor.dart';
import '../../home/providers/home_provider.dart';

class MentorListState {
  const MentorListState({
    required this.mentors,
    required this.page,
    required this.hasMore,
    required this.isLoadingMore,
    required this.query,
    required this.category,
    required this.categories,
  });

  final List<Mentor> mentors;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String query;
  final String category;
  final List<String> categories;

  MentorListState copyWith({
    List<Mentor>? mentors,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? query,
    String? category,
    List<String>? categories,
  }) => MentorListState(
    mentors: mentors ?? this.mentors,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    query: query ?? this.query,
    category: category ?? this.category,
    categories: categories ?? this.categories,
  );
}

final mentorProvider = AsyncNotifierProvider<MentorNotifier, MentorListState>(
  MentorNotifier.new,
);

class MentorNotifier extends AsyncNotifier<MentorListState> {
  @override
  Future<MentorListState> build() async {
    final repository = ref.read(mentorRepositoryProvider);
    final categoriesFuture = repository.getCategories();
    final mentorsFuture = repository.getMentors();
    final categories = await categoriesFuture;
    final mentors = await mentorsFuture;
    return MentorListState(
      mentors: mentors.mentors,
      page: 1,
      hasMore: mentors.hasMore,
      isLoadingMore: false,
      query: '',
      category: 'All',
      categories: categories,
    );
  }

  Future<void> refresh({String? query, String? category}) async {
    final current = state.valueOrNull;
    final nextQuery = query ?? current?.query ?? '';
    final nextCategory = category ?? current?.category ?? 'All';
    state = const AsyncLoading();
    final mentors = await ref
        .read(mentorRepositoryProvider)
        .getMentors(query: nextQuery, category: nextCategory);
    state = AsyncData(
      MentorListState(
        mentors: mentors.mentors,
        page: 1,
        hasMore: mentors.hasMore,
        isLoadingMore: false,
        query: nextQuery,
        category: nextCategory,
        categories: current?.categories ?? const ['All'],
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    final nextPage = current.page + 1;
    final page = await ref
        .read(mentorRepositoryProvider)
        .getMentors(
          query: current.query,
          category: current.category,
          page: nextPage,
        );
    state = AsyncData(
      current.copyWith(
        mentors: [...current.mentors, ...page.mentors],
        page: nextPage,
        hasMore: page.hasMore,
        isLoadingMore: false,
      ),
    );
  }
}

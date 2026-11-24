import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/booking.dart';
import '../../../core/repositories/booking_repository.dart';
import '../../home/providers/home_provider.dart';

enum SessionListFilter { upcoming, completed }

class SessionListState {
  const SessionListState({
    required this.items,
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<Booking> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  SessionListState copyWith({
    List<Booking>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
  }) => SessionListState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

final sessionListProvider =
    AsyncNotifierProvider.family<
      SessionListNotifier,
      SessionListState,
      SessionListFilter
    >(SessionListNotifier.new);

class SessionListNotifier
    extends FamilyAsyncNotifier<SessionListState, SessionListFilter> {
  @override
  Future<SessionListState> build(SessionListFilter arg) async {
    final page = await _load(1);
    return SessionListState(
      items: page.bookings,
      page: page.page,
      hasMore: page.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await _load(current.page + 1);
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.bookings],
          page: page.page,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<BookingPage> _load(int page) {
    final repository = ref.read(bookingRepositoryProvider);
    return switch (arg) {
      SessionListFilter.upcoming => repository.getBookingsPage(
        from: DateTime.now(),
        page: page,
      ),
      SessionListFilter.completed => repository.getBookingsPage(
        status: 'completed',
        page: page,
      ),
    };
  }
}

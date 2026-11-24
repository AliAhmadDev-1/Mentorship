import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/booking.dart';
import '../../../core/models/mentor.dart';
import '../../home/providers/home_provider.dart';

final bookingProvider = AsyncNotifierProvider<BookingNotifier, List<Booking>>(
  BookingNotifier.new,
);

class BookingNotifier extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() =>
      ref.read(bookingRepositoryProvider).getUpcomingBookings();

  Future<Booking> createBooking(
    Mentor mentor,
    DateTime scheduledAt,
    int durationMinutes,
    String sessionGoal,
  ) async {
    final booking = await ref
        .read(bookingRepositoryProvider)
        .createBooking(mentor, scheduledAt, durationMinutes, sessionGoal);
    state = AsyncData([...(state.valueOrNull ?? []), booking]);
    return booking;
  }

  Future<Booking> confirmPayment(String id) async {
    final booking = await ref
        .read(bookingRepositoryProvider)
        .confirmPayment(id);
    state = AsyncData([
      for (final item in state.valueOrNull ?? <Booking>[])
        if (item.id == id) booking else item,
    ]);
    return booking;
  }

  Future<Booking> cancel(String id) async {
    final booking = await ref.read(bookingRepositoryProvider).cancelBooking(id);
    state = AsyncData([
      for (final item in state.valueOrNull ?? <Booking>[])
        if (item.id == id) booking else item,
    ]);
    return booking;
  }
}

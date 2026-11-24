import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/booking.dart';
import '../../../core/models/mentor.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/repositories/booking_repository.dart';
import '../../../core/repositories/mentor_repository.dart';
import '../repositories/home_repository.dart';

final mentorRepositoryProvider = Provider<MentorRepository>(
  (ref) => MentorRepository(api: ref.watch(microMentorApiProvider)),
);
final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(api: ref.watch(microMentorApiProvider)),
);
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(api: ref.watch(microMentorApiProvider)),
);

class HomeState {
  const HomeState({
    required this.userName,
    required this.categories,
    required this.featured,
    required this.upcoming,
  });

  final String userName;
  final List<HomeCategory> categories;
  final List<Mentor> featured;
  final Booking? upcoming;
}

final homeProvider = AsyncNotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);

class HomeNotifier extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final content = await ref.read(homeRepositoryProvider).getHome();
    return HomeState(
      userName: content.userName,
      categories: content.categories,
      featured: content.featured,
      upcoming: content.upcoming,
    );
  }
}

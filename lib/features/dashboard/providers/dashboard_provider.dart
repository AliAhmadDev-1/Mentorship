import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/booking.dart';
import '../../../core/models/mentor_earnings.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(api: ref.watch(microMentorApiProvider)),
);

class DashboardState {
  const DashboardState({
    required this.mentorId,
    required this.earnings,
    required this.todaySessions,
  });

  final int mentorId;
  final MentorEarnings earnings;
  final List<Booking> todaySessions;
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
      DashboardNotifier.new,
    );

// And it's exist
class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    final content = await ref
        .read(dashboardRepositoryProvider)
        .getDashboardContent();
    return DashboardState(
      mentorId: content.mentorId,
      earnings: content.earnings,
      todaySessions: content.todaySessions,
    );
  }
}

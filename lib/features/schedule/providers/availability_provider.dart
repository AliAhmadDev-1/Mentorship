import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/availability.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/repositories/availability_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>(
  (ref) => AvailabilityRepository(api: ref.watch(microMentorApiProvider)),
);
final availabilityProvider =
    AsyncNotifierProvider<AvailabilityNotifier, List<Availability>>(
      AvailabilityNotifier.new,
    );

class AvailabilityNotifier extends AsyncNotifier<List<Availability>> {
  int? _mentorId;

  @override
  Future<List<Availability>> build() async {
    final dashboard = await ref.read(dashboardProvider.future);
    _mentorId = dashboard.mentorId;
    return ref
        .read(availabilityRepositoryProvider)
        .getWeeklyAvailability(dashboard.mentorId);
  }

  Future<void> toggleDay(String day) async {
    final mentorId = await _requireMentorId();
    await ref.read(availabilityRepositoryProvider).toggleDay(day, mentorId);
    state = AsyncData(
      await ref
          .read(availabilityRepositoryProvider)
          .getWeeklyAvailability(mentorId),
    );
  }

  Future<void> addTimeSlot(String day, String startTime, String endTime) async {
    final mentorId = await _requireMentorId();
    await ref
        .read(availabilityRepositoryProvider)
        .addTimeSlot(day, startTime, endTime, mentorId);
    state = AsyncData(
      await ref
          .read(availabilityRepositoryProvider)
          .getWeeklyAvailability(mentorId),
    );
  }

  Future<void> removeTimeSlot(String day, String id) async {
    await ref.read(availabilityRepositoryProvider).removeTimeSlot(day, id);
    final mentorId = await _requireMentorId();
    state = AsyncData(
      await ref
          .read(availabilityRepositoryProvider)
          .getWeeklyAvailability(mentorId),
    );
  }

  Future<int> _requireMentorId() async {
    final existing = _mentorId;
    if (existing != null) return existing;
    final dashboard = await ref.read(dashboardProvider.future);
    _mentorId = dashboard.mentorId;
    return dashboard.mentorId;
  }
}

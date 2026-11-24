import '../models/api_models.dart';
import '../models/availability.dart';
import '../models/time_slot.dart';
import '../network/micro_mentor_api.dart';

class AvailabilityRepository {
  AvailabilityRepository({MicroMentorApi? api})
    : _api = api ?? MicroMentorApi();

  final MicroMentorApi _api;

  Future<List<Availability>> getWeeklyAvailability(Object mentorId) async {
    final response = await _api.listAvailability(mentorId: mentorId);
    if (!response.success) throw response.error!;
    return _groupWindows(response.data?.results ?? const []);
  }

  Future<void> toggleDay(String day, Object mentorId) async {
    final current = await getWeeklyAvailability(mentorId);
    final selected = current.firstWhere((item) => item.day == day);
    final nextValue = !selected.isEnabled;

    if (selected.slots.isEmpty) {
      final response = await _api.createAvailabilityWindow({
        'weekday': _weekdayValue(day),
        'starts_at': '09:00',
        'ends_at': '17:00',
        'timezone': 'UTC',
        'slot_interval_minutes': 30,
        'is_active': nextValue,
      });
      if (!response.success) throw response.error!;
      return;
    }

    for (final slot in selected.slots) {
      final response = await _api.updateAvailabilityWindow(slot.id, {
        'is_active': nextValue,
      });
      if (!response.success) throw response.error!;
    }
  }

  Future<void> addTimeSlot(
    String day,
    String startTime,
    String endTime,
    Object mentorId,
  ) async {
    final response = await _api.createAvailabilityWindow({
      'weekday': _weekdayValue(day),
      'starts_at': startTime,
      'ends_at': endTime,
      'timezone': 'UTC',
      'slot_interval_minutes': 30,
      'is_active': true,
    });
    if (!response.success) throw response.error!;
  }

  Future<void> removeTimeSlot(String day, String id) async {
    final response = await _api.deleteAvailabilityWindow(id);
    if (!response.success) throw response.error!;
  }
}

List<Availability> _groupWindows(List<AvailabilityWindowResponse> windows) {
  return List.generate(7, (index) {
    final weekday = index + 1;
    final day = _dayName(weekday);
    final dayWindows = windows
        .where((item) => item.weekday == weekday)
        .toList();
    final slots = dayWindows.map(_slotFromWindow).toList();
    return Availability(
      id: '$weekday',
      mentorId: dayWindows.isEmpty ? '' : dayWindows.first.mentorId.toString(),
      day: day,
      isEnabled: dayWindows.any((item) => item.isActive ?? true),
      slots: slots,
    );
  });
}

TimeSlot _slotFromWindow(AvailabilityWindowResponse window) {
  return TimeSlot(
    id: '${window.id}',
    startTime: window.startsAt ?? '09:00',
    endTime: window.endsAt ?? '17:00',
    isBooked: false,
  );
}

String _dayName(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[(weekday - 1).clamp(0, 6)];
}

int _weekdayValue(String day) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final index = names.indexOf(day);
  return index == -1 ? 1 : index + 1;
}

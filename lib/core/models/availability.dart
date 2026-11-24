import 'time_slot.dart';

class Availability {
  const Availability({
    required this.id,
    required this.mentorId,
    required this.day,
    required this.isEnabled,
    required this.slots,
  });

  final String id;
  final String mentorId;
  final String day;
  final bool isEnabled;
  final List<TimeSlot> slots;

  Availability copyWith({bool? isEnabled, List<TimeSlot>? slots}) =>
      Availability(
        id: id,
        mentorId: mentorId,
        day: day,
        isEnabled: isEnabled ?? this.isEnabled,
        slots: slots ?? this.slots,
      );
}

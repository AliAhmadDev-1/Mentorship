class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
  });

  final String id;
  final String startTime;
  final String endTime;
  final bool isBooked;
}

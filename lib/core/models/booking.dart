import 'mentor.dart';

class Booking {
  const Booking({
    required this.id,
    required this.mentorId,
    required this.mentor,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    required this.amount,
    required this.agoraChannel,
    required this.sessionGoal,
  });

  final String id;
  final String mentorId;
  final Mentor mentor;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status;
  final double amount;
  final String agoraChannel;
  final String sessionGoal;

  Booking copyWith({String? status}) => Booking(
    id: id,
    mentorId: mentorId,
    mentor: mentor,
    scheduledAt: scheduledAt,
    durationMinutes: durationMinutes,
    status: status ?? this.status,
    amount: amount,
    agoraChannel: agoraChannel,
    sessionGoal: sessionGoal,
  );
}

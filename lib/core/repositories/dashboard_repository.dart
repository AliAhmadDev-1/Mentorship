import '../models/api_models.dart';
import '../models/booking.dart';
import '../models/mentor.dart';
import '../models/mentor_earnings.dart';
import '../network/api_exception.dart';
import '../network/error_handler.dart';
import '../network/micro_mentor_api.dart';

class DashboardRepository {
  DashboardRepository({MicroMentorApi? api}) : _api = api ?? MicroMentorApi();

  final MicroMentorApi _api;

  Future<MentorDashboardContent> getDashboardContent() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dashboardFuture = _dashboard();
    final sessionsFuture = _api.listBookings(
      from: DateTime(now.year, now.month, now.day),
      to: tomorrow,
      pageSize: 100,
    );
    final dashboard = await dashboardFuture;
    final sessions = await sessionsFuture;
    if (!sessions.success) throw sessions.error!;
    return MentorDashboardContent(
      mentorId: dashboard.mentorId,
      earnings: _earningsFromDashboard(dashboard),
      todaySessions: (sessions.data?.results ?? const [])
          .map(_bookingFromSession)
          .toList(),
    );
  }

  Future<MentorEarnings> getEarnings() async {
    final dashboard = await _dashboard();
    return _earningsFromDashboard(dashboard);
  }

  Future<List<Booking>> getTodaySessions() async {
    return (await getDashboardContent()).todaySessions;
  }

  MentorEarnings _earningsFromDashboard(MentorDashboardResponse dashboard) {
    return MentorEarnings(
      thisMonth: dashboard.earningsUsd,
      sessionsCount: dashboard.upcomingSessionsCount,
      avgRating: dashboard.averageRating,
      repeatClientPct: dashboard.repeatClientPercent.round(),
      totalSessions: dashboard.totalSessions,
      completedSessions: dashboard.completedSessions,
      reviewCount: dashboard.reviewCount,
      currency: dashboard.currency,
    );
  }

  Future<MentorDashboardResponse> _dashboard() async {
    final response = await _api.getMentorDashboard();
    if (!response.success) throw response.error!;
    final data = response.data;
    if (data == null) {
      throw const ApiException(
        message: ErrorHandler.invalidFormatMessage,
        type: ApiExceptionType.parseError,
      );
    }
    return data;
  }
}

class MentorDashboardContent {
  const MentorDashboardContent({
    required this.mentorId,
    required this.earnings,
    required this.todaySessions,
  });

  final int mentorId;
  final MentorEarnings earnings;
  final List<Booking> todaySessions;
}

Booking _bookingFromSession(SessionDetailResponse session) {
  final menteeName = session.mentee.trim().isEmpty
      ? 'Mentee'
      : session.mentee.trim();
  final topic = session.topic ?? session.goals ?? 'Mentor session';
  final mentor = Mentor(
    id: session.mentorId?.toString() ?? '',
    name: menteeName,
    title: topic,
    company: 'MicroMentor',
    expertise: const ['Mentorship'],
    ratePerSlot: session.amountUsd ?? 0,
    rating: 0,
    reviewCount: 0,
    totalSessions: 0,
    yearsExperience: 0,
    repeatRate: 0,
    verified: false,
    bio: topic,
    avatarInitials: _initials(menteeName),
    avatarColorValue: _avatarColor(session.id, menteeName),
  );

  return Booking(
    id: '${session.id}',
    mentorId: session.mentorId?.toString() ?? '',
    mentor: mentor,
    scheduledAt: session.startsAt ?? DateTime.now(),
    durationMinutes: session.durationMinutes ?? 15,
    status: session.status,
    amount: session.amountUsd ?? 0,
    agoraChannel: session.videoRoomUrl ?? '',
    sessionGoal: topic,
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  final first = parts.first[0];
  final last = parts.length > 1 ? parts.last[0] : '';
  return '$first$last'.toUpperCase();
}

int _avatarColor(Object id, String name) {
  const palette = [
    0xFF53D6B4,
    0xFFF0BF63,
    0xFFDE7C6B,
    0xFF77A88B,
    0xFFD989A4,
    0xFF6FA7A0,
  ];
  final seed = id.hashCode ^ name.hashCode;
  return palette[seed.abs() % palette.length];
}

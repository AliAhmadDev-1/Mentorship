class MentorEarnings {
  const MentorEarnings({
    required this.thisMonth,
    required this.sessionsCount,
    required this.avgRating,
    required this.repeatClientPct,
    this.totalSessions = 0,
    this.completedSessions = 0,
    this.reviewCount = 0,
    this.currency = 'USD',
  });

  final double thisMonth;
  final int sessionsCount;
  final double avgRating;
  final int repeatClientPct;
  final int totalSessions;
  final int completedSessions;
  final int reviewCount;
  final String currency;
}

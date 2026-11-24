import '../models/api_models.dart';
import '../models/booking.dart';
import '../models/mentor.dart';
import '../network/api_exception.dart';
import '../network/error_handler.dart';
import '../network/micro_mentor_api.dart';

class BookingRepository {
  BookingRepository({MicroMentorApi? api}) : _api = api ?? MicroMentorApi();

  final MicroMentorApi _api;

  Future<List<Booking>> getUpcomingBookings() async {
    final now = DateTime.now();
    final page = await getBookingsPage(from: now, pageSize: 100);
    return page.bookings
        .where((booking) => booking.scheduledAt.isAfter(now))
        .toList();
  }

  Future<BookingPage> getBookingsPage({
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _api.listBookings(
      status: status,
      from: from,
      to: to,
      page: page,
      pageSize: pageSize,
    );
    if (!response.success) throw response.error!;
    final data = response.data;
    if (data == null) {
      throw const ApiException(
        message: ErrorHandler.invalidFormatMessage,
        type: ApiExceptionType.parseError,
      );
    }
    return BookingPage(
      bookings: data.results.map(_bookingFromSession).toList(),
      page: data.page ?? page,
      hasMore: data.hasNext ?? data.next != null,
    );
  }

  Future<Booking> cancelBooking(String bookingId) async {
    final response = await _api.cancelSession(bookingId);
    if (!response.success) throw response.error!;
    return getBookingById(bookingId);
  }

  Future<Booking> createBooking(
    Mentor mentor,
    DateTime scheduledAt,
    int durationMinutes,
    String sessionGoal,
  ) async {
    final selectedPackage = mentor.packageForDuration(durationMinutes);
    final packageId = selectedPackage?.id ?? mentor.primaryPackageId;
    if (packageId == null || packageId.isEmpty) {
      throw const ApiException(
        message: 'This mentor does not have an active package yet.',
        type: ApiExceptionType.validation,
      );
    }

    final response = await _api.createBooking(
      packageId: packageId,
      startsAt: scheduledAt,
      goals: sessionGoal.trim().isEmpty ? null : sessionGoal.trim(),
      topic: mentor.title,
    );
    if (!response.success) throw response.error!;
    final sessionId = response.data?.sessionId;
    if (sessionId == null || sessionId == 0) {
      throw const ApiException(
        message: ErrorHandler.invalidFormatMessage,
        type: ApiExceptionType.parseError,
      );
    }
    return getBookingById('$sessionId');
  }

  Future<Booking> confirmPayment(String bookingId) async {
    final response = await _api.confirmPayment(
      sessionId: bookingId,
      providerPaymentId: 'test_payment_$bookingId',
    );
    if (!response.success) throw response.error!;
    return getBookingById(bookingId);
  }

  Future<Booking> getBookingById(String id) async {
    final response = await _api.getSession(id);
    if (!response.success) throw response.error!;
    final session = response.data;
    if (session == null) {
      throw const ApiException(
        message: ErrorHandler.invalidFormatMessage,
        type: ApiExceptionType.parseError,
      );
    }
    return _bookingFromSession(session);
  }
}

class BookingPage {
  const BookingPage({
    required this.bookings,
    required this.page,
    required this.hasMore,
  });

  final List<Booking> bookings;
  final int page;
  final bool hasMore;
}

Booking _bookingFromSession(SessionDetailResponse session) {
  final mentorName = session.mentor.trim().isEmpty
      ? 'Your mentor'
      : session.mentor.trim();
  final mentorId = session.mentorId?.toString() ?? '';
  final title = _fallbackText(session.topic, 'Mentor session');

  final mentor = Mentor(
    id: mentorId,
    name: mentorName,
    title: title,
    company: 'MicroMentor',
    expertise: _expertiseFromHeadline(title),
    ratePerSlot: session.amountUsd ?? 0,
    rating: 0,
    reviewCount: 0,
    totalSessions: 0,
    yearsExperience: 0,
    repeatRate: 0,
    verified: false,
    bio: title,
    avatarInitials: _initials(mentorName),
    avatarColorValue: _avatarColor(session.mentorId ?? session.id, mentorName),
  );

  return Booking(
    id: '${session.id}',
    mentorId: mentorId,
    mentor: mentor,
    scheduledAt: session.startsAt ?? DateTime.now(),
    durationMinutes: session.durationMinutes ?? 15,
    status: session.status,
    amount: session.amountUsd ?? 0,
    agoraChannel: session.videoRoomUrl ?? '',
    sessionGoal: session.goals ?? session.topic ?? '',
  );
}

List<String> _expertiseFromHeadline(String headline) {
  final words = headline
      .split(RegExp(r'[\s,/&+-]+'))
      .where((word) => word.trim().length > 2)
      .take(3)
      .toList();
  return words.isEmpty ? const ['Mentorship'] : words;
}

String _fallbackText(String? value, String fallback) {
  final text = value?.trim();
  return text == null || text.isEmpty ? fallback : text;
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

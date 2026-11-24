import '../../../core/models/api_models.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/mentor.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/error_handler.dart';
import '../../../core/network/micro_mentor_api.dart';

class HomeRepository {
  HomeRepository({MicroMentorApi? api}) : _api = api ?? MicroMentorApi();

  final MicroMentorApi _api;

  Future<HomeContent> getHome() async {
    final response = await _api.home();
    if (!response.success) throw response.error!;

    final payload = response.data;
    if (payload == null) {
      throw const ApiException(
        message: ErrorHandler.invalidFormatMessage,
        type: ApiExceptionType.parseError,
      );
    }

    final upcomingSession =
        payload.upcomingSession ??
        await _loadUpcomingSession(payload.upcomingSessionId);

    return HomeContent(
      userName: payload.user.name,
      categories: payload.categories
          .map(HomeCategory.fromResponse)
          .where((category) => category.name.trim().isNotEmpty)
          .toList(),
      featured: payload.featuredMentors.map(_mentorFromItem).toList(),
      upcoming: upcomingSession == null
          ? null
          : _bookingFromSession(upcomingSession),
    );
  }

  Future<SessionDetailResponse?> _loadUpcomingSession(int? sessionId) async {
    if (sessionId == null) return null;
    final response = await _api.getSession(sessionId);
    if (!response.success) throw response.error!;
    return response.data;
  }

  Mentor _mentorFromItem(MentorListItem item) {
    final name = item.name.trim().isEmpty ? 'Mentor' : item.name.trim();
    final title = item.headline.trim().isEmpty
        ? 'MicroMentor expert'
        : item.headline.trim();
    final expertise = item.expertise.isEmpty
        ? _expertiseFromHeadline(title)
        : item.expertise;
    final package = _firstActivePackage(item.packages);
    final packages = _packagesFromResponses(item.packages);

    return Mentor(
      id: '${item.id}',
      name: name,
      title: title,
      company: item.company?.trim().isNotEmpty == true
          ? item.company!.trim()
          : 'MicroMentor',
      expertise: expertise,
      ratePerSlot: package?.priceUsd ?? item.startingPrice,
      rating: item.rating ?? 0,
      reviewCount: item.reviewCount ?? 0,
      totalSessions: item.totalSessions ?? 0,
      yearsExperience: item.yearsExperience ?? 0,
      repeatRate: item.repeatRate ?? 0,
      verified: item.verified ?? false,
      bio: item.bio ?? title,
      avatarInitials: _initials(name),
      avatarColorValue: _avatarColor(item.id, name),
      primaryPackageId: package == null ? null : '${package.id}',
      packages: packages,
    );
  }

  Booking _bookingFromSession(SessionDetailResponse session) {
    final mentorName = session.mentor.trim().isEmpty
        ? 'Your mentor'
        : session.mentor.trim();
    final mentorId = session.mentorId?.toString() ?? '';
    final title = session.topic?.trim().isNotEmpty == true
        ? session.topic!.trim()
        : 'Mentor session';

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
      avatarColorValue: _avatarColor(
        session.mentorId ?? session.id,
        mentorName,
      ),
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
}

PackageResponse? _firstActivePackage(List<PackageResponse> packages) {
  for (final package in packages) {
    if (package.isActive ?? true) return package;
  }
  return packages.isEmpty ? null : packages.first;
}

List<MentorPackage> _packagesFromResponses(List<PackageResponse> packages) {
  return packages
      .where((package) => package.isActive ?? true)
      .map(
        (package) => MentorPackage(
          id: '${package.id}',
          durationMinutes: package.durationMinutes ?? 15,
          priceUsd: package.priceUsd,
          isPopular: package.isPopular ?? false,
        ),
      )
      .toList();
}

class HomeContent {
  const HomeContent({
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

class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.name,
    this.slug,
    this.mentorCount,
  });

  final int id;
  final String name;
  final String? slug;
  final int? mentorCount;

  factory HomeCategory.fromResponse(CategoryResponse response) {
    return HomeCategory(
      id: response.id,
      name: response.name,
      slug: response.slug,
      mentorCount: response.mentorCount,
    );
  }
}

List<String> _expertiseFromHeadline(String headline) {
  final words = headline
      .split(RegExp(r'[\s,/&+-]+'))
      .where((word) => word.trim().length > 2)
      .take(3)
      .toList();
  return words.isEmpty ? const ['Mentorship'] : words;
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

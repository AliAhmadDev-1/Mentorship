import 'app_user.dart';
import 'mentor_onboarding.dart';

class ApiListResponse<T> {
  const ApiListResponse({
    required this.results,
    this.count,
    this.next,
    this.previous,
    this.page,
    this.pageSize,
    this.hasNext,
    this.hasPrevious,
  });

  final List<T> results;
  final int? count;
  final String? next;
  final String? previous;
  final int? page;
  final int? pageSize;
  final bool? hasNext;
  final bool? hasPrevious;

  factory ApiListResponse.fromJson(
    Object? json,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) {
    final map = _map(json);
    final list = switch (json) {
      {'results': final List items} => items,
      {'messages': final List items} => items,
      {'data': final List items} => items,
      final List items => items,
      _ => const [],
    };
    return ApiListResponse(
      results: list.map((item) => itemFromJson(_map(item))).toList(),
      count: _nullableInt(map['count']),
      next: _nullableString(map['next']),
      previous: _nullableString(map['previous']),
      page: _nullableInt(map['page']),
      pageSize: _nullableInt(map['page_size']),
      hasNext:
          _nullableBool(map['has_next']) ??
          (_nullableString(map['next']) != null ? true : null),
      hasPrevious:
          _nullableBool(map['has_previous']) ??
          (_nullableString(map['previous']) != null ? true : null),
    );
  }
}

class AuthResponse {
  const AuthResponse({
    required this.id,
    required this.email,
    required this.accessToken,
    this.refreshToken,
    this.role,
    this.firstName = '',
    this.lastName = '',
    this.mentorProfileId,
    this.onboarding,
  });

  final int id;
  final String email;
  final String accessToken;
  final String? refreshToken;
  final UserRole? role;
  final String firstName;
  final String lastName;
  final int? mentorProfileId;
  final MentorOnboardingSummary? onboarding;

  factory AuthResponse.fromJson(Object? json) {
    final map = _dataOrSelf(json);
    final userMap = _mapOrNull(map['user']);
    return AuthResponse(
      id: _int(map['id'] ?? userMap?['id'] ?? map['user_id']),
      email: _string(map['email'] ?? userMap?['email']),
      accessToken: _string(
        map['access_token'] ?? map['access'] ?? map['token'],
      ),
      refreshToken: _nullableString(map['refresh_token'] ?? map['refresh']),
      role: _nullableRole(
        map['role'] ??
            map['user_role'] ??
            map['user_type'] ??
            map['account_type'] ??
            userMap?['role'] ??
            userMap?['user_role'] ??
            userMap?['user_type'] ??
            userMap?['account_type'],
      ),
      firstName: _string(map['first_name'] ?? userMap?['first_name']),
      lastName: _string(map['last_name'] ?? userMap?['last_name']),
      mentorProfileId: _nullableInt(
        map['mentor_profile_id'] ?? userMap?['mentor_profile_id'],
      ),
      onboarding: map['onboarding'] is Map
          ? MentorOnboardingSummary.fromJson(map['onboarding'])
          : null,
    );
  }

  AppUser toUser({
    String? fallbackEmail,
    String? firstName,
    String? lastName,
    UserRole fallbackRole = UserRole.mentee,
  }) {
    return AppUser.fromJson({
      'id': id,
      'email': email.isEmpty ? fallbackEmail ?? '' : email,
      'first_name': this.firstName.isNotEmpty
          ? this.firstName
          : firstName ?? '',
      'last_name': this.lastName.isNotEmpty ? this.lastName : lastName ?? '',
      'role': role?.name ?? fallbackRole.name,
      'mentor_profile_id': mentorProfileId,
    });
  }
}

class TokenRefreshResponse {
  const TokenRefreshResponse({required this.accessToken});

  final String accessToken;

  factory TokenRefreshResponse.fromJson(Object? json) {
    final map = _dataOrSelf(json);
    return TokenRefreshResponse(
      accessToken: _string(
        map['access_token'] ?? map['access'] ?? map['token'],
      ),
    );
  }
}

class DetailMessageResponse {
  const DetailMessageResponse({required this.detail});

  final String detail;

  factory DetailMessageResponse.fromJson(Object? json) =>
      DetailMessageResponse(detail: _string(_dataOrSelf(json)['detail']));
}

class HomeResponse {
  const HomeResponse({
    required this.user,
    required this.categories,
    required this.featuredMentors,
    this.upcomingSessionId,
    this.upcomingSession,
  });

  final HomeUser user;
  final int? upcomingSessionId;
  final SessionDetailResponse? upcomingSession;
  final List<CategoryResponse> categories;
  final List<MentorListItem> featuredMentors;

  factory HomeResponse.fromJson(Object? json) {
    final map = _dataOrSelf(json);
    final upcoming = map['upcoming_session'];
    return HomeResponse(
      user: HomeUser.fromJson(map['user']),
      upcomingSessionId: _nullableInt(map['upcoming_session_id']),
      upcomingSession: upcoming is Map
          ? SessionDetailResponse.fromJson(upcoming)
          : null,
      categories: _list(
        map['categories'],
        (item) => CategoryResponse.fromJson(item),
      ),
      featuredMentors: _list(
        map['featured_mentors'] ?? map['featured'] ?? map['mentors'],
        (item) => MentorListItem.fromJson(item),
      ),
    );
  }
}

class HomeUser {
  const HomeUser({required this.name, required this.role});

  final String name;
  final UserRole role;

  factory HomeUser.fromJson(Object? json) {
    final map = _map(json);
    return HomeUser(name: _string(map['name']), role: _role(map['role']));
  }
}

class MentorListItem {
  const MentorListItem({
    required this.id,
    required this.name,
    required this.headline,
    required this.startingPrice,
    this.company,
    this.expertise = const [],
    this.rating,
    this.reviewCount,
    this.totalSessions,
    this.yearsExperience,
    this.repeatRate,
    this.verified,
    this.bio,
    this.packages = const [],
  });

  final int id;
  final String name;
  final String headline;
  final double startingPrice;
  final String? company;
  final List<String> expertise;
  final double? rating;
  final int? reviewCount;
  final int? totalSessions;
  final int? yearsExperience;
  final int? repeatRate;
  final bool? verified;
  final String? bio;
  final List<PackageResponse> packages;

  factory MentorListItem.fromJson(Object? json) {
    final map = _map(json);
    return MentorListItem(
      id: _int(map['id'] ?? map['mentor_id']),
      name: _string(
        map['name'] ?? map['full_name'] ?? map['display_name'] ?? map['email'],
      ),
      headline: _string(map['headline'] ?? map['title'] ?? map['role_title']),
      startingPrice: _double(
        map['starting_price'] ??
            map['starting_price_usd'] ??
            map['rate_per_slot'] ??
            map['price_usd'],
      ),
      company: _nullableString(map['company']),
      expertise: _stringItems(map['expertise'] ?? map['expertises']),
      rating: _nullableDouble(map['rating'] ?? map['average_rating']),
      reviewCount: _nullableInt(map['review_count'] ?? map['reviews_count']),
      totalSessions: _nullableInt(
        map['total_sessions'] ?? map['sessions_count'],
      ),
      yearsExperience: _nullableInt(map['years_experience']),
      repeatRate: _nullableInt(map['repeat_rate']),
      verified: _nullableBool(map['verified'] ?? map['is_verified']),
      bio: _nullableString(map['bio']),
      packages: _list(
        map['packages'],
        (item) => PackageResponse.fromJson(item),
      ),
    );
  }
}

class MentorDetailResponse {
  const MentorDetailResponse({
    required this.id,
    required this.name,
    required this.headline,
    required this.bio,
    required this.packages,
  });

  final int id;
  final String name;
  final String headline;
  final String bio;
  final List<PackageResponse> packages;

  factory MentorDetailResponse.fromJson(Object? json) {
    final map = _map(json);
    return MentorDetailResponse(
      id: _int(map['id']),
      name: _string(map['name']),
      headline: _string(map['headline']),
      bio: _string(map['bio']),
      packages: _list(
        map['packages'],
        (item) => PackageResponse.fromJson(item),
      ),
    );
  }
}

class MentorAvailabilityResponse {
  const MentorAvailabilityResponse({
    required this.mentorId,
    required this.weeklyWindows,
    required this.bookedStarts,
    this.timezone,
    this.durationMinutes,
    this.slots = const [],
  });

  final int mentorId;
  final List<AvailabilityWindowResponse> weeklyWindows;
  final List<DateTime> bookedStarts;
  final String? timezone;
  final int? durationMinutes;
  final List<BookableSlotResponse> slots;

  factory MentorAvailabilityResponse.fromJson(Object? json) {
    final map = _map(json);
    return MentorAvailabilityResponse(
      mentorId: _int(map['mentor_id']),
      weeklyWindows: _list(
        map['weekly_windows'],
        (item) => AvailabilityWindowResponse.fromJson(item),
      ),
      bookedStarts: _list(map['booked_starts'], _dateTime),
      timezone: _nullableString(map['timezone']),
      durationMinutes: _nullableInt(map['duration_minutes']),
      slots: _list(map['slots'], BookableSlotResponse.fromJson),
    );
  }
}

class BookableSlotResponse {
  const BookableSlotResponse({
    required this.startsAt,
    required this.endsAt,
    required this.available,
  });

  final DateTime startsAt;
  final DateTime endsAt;
  final bool available;

  factory BookableSlotResponse.fromJson(Object? json) {
    final map = _map(json);
    return BookableSlotResponse(
      startsAt: _dateTime(map['starts_at']),
      endsAt: _dateTime(map['ends_at']),
      available: _nullableBool(map['available']) ?? false,
    );
  }
}

class BookingCreateResponse {
  const BookingCreateResponse({
    required this.sessionId,
    required this.paymentStatus,
  });

  final int sessionId;
  final String paymentStatus;

  factory BookingCreateResponse.fromJson(Object? json) {
    final map = _map(json);
    return BookingCreateResponse(
      sessionId: _int(map['session_id']),
      paymentStatus: _string(map['payment_status']),
    );
  }
}

class SessionDetailResponse {
  const SessionDetailResponse({
    required this.id,
    required this.mentor,
    required this.mentee,
    required this.startsAt,
    required this.status,
    this.mentorId,
    this.durationMinutes,
    this.amountUsd,
    this.goals,
    this.topic,
    this.videoRoomUrl,
  });

  final int id;
  final String mentor;
  final String mentee;
  final DateTime? startsAt;
  final String status;
  final int? mentorId;
  final int? durationMinutes;
  final double? amountUsd;
  final String? goals;
  final String? topic;
  final String? videoRoomUrl;

  factory SessionDetailResponse.fromJson(Object? json) {
    final map = _map(json);
    final mentorMap = _mapOrNull(map['mentor']);
    final menteeMap = _mapOrNull(map['mentee']);
    final packageMap = _mapOrNull(map['package']);
    return SessionDetailResponse(
      id: _int(map['id']),
      mentor:
          _personName(mentorMap) ??
          _string(map['mentor_name'] ?? map['mentor']),
      mentee:
          _personName(menteeMap) ??
          _string(map['mentee_name'] ?? map['mentee']),
      startsAt: _nullableDateTime(map['starts_at']),
      status: _string(map['status']),
      mentorId: _nullableInt(map['mentor_id'] ?? mentorMap?['id']),
      durationMinutes: _nullableInt(
        map['duration_minutes'] ?? packageMap?['duration_minutes'],
      ),
      amountUsd: _nullableDouble(
        map['price_usd'] ??
            map['amount_usd'] ??
            map['amount'] ??
            packageMap?['price_usd'],
      ),
      goals: _nullableString(map['goals'] ?? map['session_goal']),
      topic: _nullableString(map['topic']),
      videoRoomUrl: _nullableString(map['video_room_url']),
    );
  }
}

class PaymentConfirmationResponse {
  const PaymentConfirmationResponse({
    required this.sessionId,
    required this.status,
    required this.videoRoomUrl,
  });

  final int sessionId;
  final String status;
  final String videoRoomUrl;

  factory PaymentConfirmationResponse.fromJson(Object? json) {
    final map = _map(json);
    return PaymentConfirmationResponse(
      sessionId: _int(map['session_id']),
      status: _string(map['status']),
      videoRoomUrl: _string(map['video_room_url']),
    );
  }
}

class SessionStatusResponse {
  const SessionStatusResponse({required this.sessionId, required this.status});

  final int sessionId;
  final String status;

  factory SessionStatusResponse.fromJson(Object? json) {
    final map = _map(json);
    return SessionStatusResponse(
      sessionId: _int(map['session_id']),
      status: _string(map['status']),
    );
  }
}

class ProfileResponse {
  const ProfileResponse({
    required this.name,
    required this.email,
    required this.role,
    required this.sessions,
    required this.spentUsd,
    this.mentorProfileId,
  });

  final String name;
  final String email;
  final UserRole role;
  final int sessions;
  final double spentUsd;
  final int? mentorProfileId;

  factory ProfileResponse.fromJson(Object? json) {
    final map = _dataOrSelf(json);
    return ProfileResponse(
      name: _string(
        map['name'] ?? map['full_name'] ?? map['display_name'] ?? map['email'],
      ),
      email: _string(map['email']),
      role: _role(
        map['role'] ??
            map['user_role'] ??
            map['user_type'] ??
            map['account_type'],
      ),
      sessions: _int(map['sessions']),
      spentUsd: _double(map['spent_usd']),
      mentorProfileId: _nullableInt(map['mentor_profile_id']),
    );
  }
}

class MentorDashboardResponse {
  const MentorDashboardResponse({
    required this.mentorId,
    required this.totalSessions,
    required this.completedSessions,
    required this.upcomingSessionsCount,
    required this.earningsUsd,
    required this.currency,
    required this.averageRating,
    required this.reviewCount,
    required this.repeatClientPercent,
  });

  final int mentorId;
  final int totalSessions;
  final int completedSessions;
  final int upcomingSessionsCount;
  final double earningsUsd;
  final String currency;
  final double averageRating;
  final int reviewCount;
  final double repeatClientPercent;

  factory MentorDashboardResponse.fromJson(Object? json) {
    final map = _map(json);
    return MentorDashboardResponse(
      mentorId: _int(map['mentor_id']),
      totalSessions: _int(map['total_sessions']),
      completedSessions: _int(map['completed_sessions']),
      upcomingSessionsCount: _int(
        map['upcoming_sessions_count'] ?? map['upcoming_sessions'],
      ),
      earningsUsd: _double(map['earnings_usd']),
      currency: _nullableString(map['currency']) ?? 'USD',
      averageRating: _double(map['average_rating']),
      reviewCount: _int(map['review_count']),
      repeatClientPercent: _double(map['repeat_client_percent']),
    );
  }
}

class CategoryResponse {
  const CategoryResponse({
    required this.id,
    required this.name,
    this.emoji,
    this.slug,
    this.mentorCount,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final int id;
  final String name;
  final String? emoji;
  final String? slug;
  final int? mentorCount;
  final bool isActive;
  final int sortOrder;

  factory CategoryResponse.fromJson(Object? json) {
    final map = _map(json);
    return CategoryResponse(
      id: _int(map['id']),
      name: _string(map['name']),
      emoji: _nullableString(map['emoji']),
      slug: _nullableString(map['slug']),
      mentorCount: _nullableInt(map['mentor_count'] ?? map['mentors_count']),
      isActive: _nullableBool(map['is_active']) ?? true,
      sortOrder: _nullableInt(map['sort_order']) ?? 0,
    );
  }
}

class ExpertiseResponse {
  const ExpertiseResponse({
    required this.id,
    required this.name,
    this.slug,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final int id;
  final String name;
  final String? slug;
  final bool isActive;
  final int sortOrder;

  factory ExpertiseResponse.fromJson(Object? json) {
    final map = _map(json);
    return ExpertiseResponse(
      id: _int(map['id']),
      name: _string(map['name']),
      slug: _nullableString(map['slug']),
      isActive: _nullableBool(map['is_active']) ?? true,
      sortOrder: _nullableInt(map['sort_order']) ?? 0,
    );
  }
}

class MentorProfileResponse {
  const MentorProfileResponse({
    required this.id,
    required this.headline,
    this.bio,
    this.company,
    this.yearsExperience,
    this.city,
    this.linkedinUrl,
    this.introVideoUrl,
    this.autoConfirmBookings,
    this.isActive,
    this.categoryIds = const [],
    this.expertiseIds = const [],
    this.categories = const [],
    this.expertise = const [],
  });

  final int id;
  final String headline;
  final String? bio;
  final String? company;
  final int? yearsExperience;
  final String? city;
  final String? linkedinUrl;
  final String? introVideoUrl;
  final bool? autoConfirmBookings;
  final bool? isActive;
  final List<int> categoryIds;
  final List<int> expertiseIds;
  final List<String> categories;
  final List<String> expertise;

  factory MentorProfileResponse.fromJson(Object? json) {
    final map = _dataOrSelf(json);
    return MentorProfileResponse(
      id: _int(map['id']),
      headline: _string(map['headline']),
      bio: _nullableString(map['bio']),
      company: _nullableString(map['company']),
      yearsExperience: _nullableInt(map['years_experience']),
      city: _nullableString(map['city']),
      linkedinUrl: _nullableString(map['linkedin_url']),
      introVideoUrl: _nullableString(map['intro_video_url']),
      autoConfirmBookings: _nullableBool(map['auto_confirm_bookings']),
      isActive: _nullableBool(map['is_active']),
      categoryIds: _idItems(map['category_ids'] ?? map['categories']),
      expertiseIds: _idItems(map['expertise_ids'] ?? map['expertise']),
      categories: _stringItems(map['categories']),
      expertise: _stringItems(map['expertise']),
    );
  }
}

class PackageResponse {
  const PackageResponse({
    required this.id,
    required this.mentorId,
    required this.priceUsd,
    this.durationMinutes,
    this.isPopular,
    this.isActive,
  });

  final int id;
  final int mentorId;
  final double priceUsd;
  final int? durationMinutes;
  final bool? isPopular;
  final bool? isActive;

  factory PackageResponse.fromJson(Object? json) {
    final map = _map(json);
    return PackageResponse(
      id: _int(map['id']),
      mentorId: _int(map['mentor_id']),
      priceUsd: _double(map['price_usd']),
      durationMinutes: _nullableInt(map['duration_minutes']),
      isPopular: _nullableBool(map['is_popular']),
      isActive: _nullableBool(map['is_active']),
    );
  }
}

class AvailabilityWindowResponse {
  const AvailabilityWindowResponse({
    required this.id,
    required this.mentorId,
    this.weekday,
    this.startsAt,
    this.endsAt,
    this.timezone,
    this.slotIntervalMinutes,
    this.isActive,
  });

  final int id;
  final int mentorId;
  final int? weekday;
  final String? startsAt;
  final String? endsAt;
  final String? timezone;
  final int? slotIntervalMinutes;
  final bool? isActive;

  factory AvailabilityWindowResponse.fromJson(Object? json) {
    final map = _map(json);
    return AvailabilityWindowResponse(
      id: _int(map['id']),
      mentorId: _int(map['mentor_id']),
      weekday: _nullableInt(map['weekday']),
      startsAt: _nullableString(map['starts_at']),
      endsAt: _nullableString(map['ends_at']),
      timezone: _nullableString(map['timezone']),
      slotIntervalMinutes: _nullableInt(map['slot_interval_minutes']),
      isActive: _nullableBool(map['is_active']),
    );
  }
}

class PaymentStatusResponse {
  const PaymentStatusResponse({
    required this.sessionId,
    required this.amountUsd,
    required this.status,
    required this.provider,
  });

  final int sessionId;
  final double amountUsd;
  final String status;
  final String provider;

  factory PaymentStatusResponse.fromJson(Object? json) {
    final map = _map(json);
    return PaymentStatusResponse(
      sessionId: _int(map['session_id']),
      amountUsd: _double(map['amount_usd']),
      status: _string(map['status']),
      provider: _string(map['provider']),
    );
  }
}

class ReviewMutationResponse {
  const ReviewMutationResponse({
    required this.reviewId,
    required this.rating,
    this.body,
    this.createdAt,
    this.reviewer,
    this.mentorId,
  });

  final int reviewId;
  final int rating;
  final String? body;
  final DateTime? createdAt;
  final String? reviewer;
  final int? mentorId;

  factory ReviewMutationResponse.fromJson(Object? json) {
    final map = _map(json);
    final reviewerMap = _mapOrNull(
      map['reviewer'] ?? map['mentee'] ?? map['user'],
    );
    return ReviewMutationResponse(
      reviewId: _int(map['review_id'] ?? map['id']),
      rating: _int(map['rating']),
      body: _nullableString(map['body'] ?? map['comment']),
      createdAt: _nullableDateTime(map['created_at']),
      reviewer:
          _personName(reviewerMap) ??
          _nullableString(map['reviewer_name'] ?? map['user_name']),
      mentorId: _nullableInt(map['mentor_id']),
    );
  }
}

class ConversationCreateResponse {
  const ConversationCreateResponse({
    required this.id,
    this.type,
    this.status,
    this.mentorId,
    this.menteeId,
    this.otherUserId,
    this.otherUserName,
    this.participants = const [],
    this.lastMessage,
    this.lastMessageAt,
    this.updatedAt,
    this.unreadCount,
    this.sessionId,
  });

  final int id;
  final String? type;
  final String? status;
  final int? mentorId;
  final int? menteeId;
  final int? otherUserId;
  final String? otherUserName;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? updatedAt;
  final int? unreadCount;
  final int? sessionId;

  factory ConversationCreateResponse.fromJson(Object? json) {
    final map = _map(json);
    return ConversationCreateResponse(
      id: _int(map['id']),
      type: _nullableString(map['type']),
      status: _nullableString(map['status']),
      mentorId: _nullableInt(map['mentor_id']),
      menteeId: _nullableInt(map['mentee_id']),
      otherUserId: _nullableInt(map['other_user_id']),
      otherUserName: _nullableString(map['other_user_name']),
      participants: _personItems(map['participants']),
      lastMessage: _nullableString(map['last_message']),
      lastMessageAt: _nullableDateTime(map['last_message_at']),
      updatedAt: _nullableDateTime(map['updated_at'] ?? map['created_at']),
      unreadCount: _nullableInt(map['unread_count']),
      sessionId: _nullableInt(
        map['session_id'] ??
            map['related_session_id'] ??
            _mapOrNull(map['session'])?['id'] ??
            _mapOrNull(map['related_session'])?['id'],
      ),
    );
  }
}

class ConversationDetailResponse {
  const ConversationDetailResponse({
    required this.id,
    required this.messages,
    this.type,
    this.status,
    this.mentorId,
    this.menteeId,
    this.otherUserId,
    this.otherUserName,
    this.participants = const [],
    this.sessionId,
  });

  final int id;
  final List<MessageResponse> messages;
  final String? type;
  final String? status;
  final int? mentorId;
  final int? menteeId;
  final int? otherUserId;
  final String? otherUserName;
  final List<String> participants;
  final int? sessionId;

  factory ConversationDetailResponse.fromJson(Object? json) {
    final map = _map(json);
    return ConversationDetailResponse(
      id: _int(map['id']),
      type: _nullableString(map['type']),
      status: _nullableString(map['status']),
      mentorId: _nullableInt(map['mentor_id']),
      menteeId: _nullableInt(map['mentee_id']),
      otherUserId: _nullableInt(map['other_user_id']),
      otherUserName: _nullableString(map['other_user_name']),
      participants: _personItems(map['participants']),
      sessionId: _nullableInt(
        map['session_id'] ??
            map['related_session_id'] ??
            _mapOrNull(map['session'])?['id'] ??
            _mapOrNull(map['related_session'])?['id'],
      ),
      messages: _list(
        map['messages'],
        (item) => MessageResponse.fromJson(item),
      ),
    );
  }
}

class MessageResponse {
  const MessageResponse({
    required this.id,
    required this.createdAt,
    this.body,
    this.senderId,
    this.sender,
    this.isMine,
  });

  final int id;
  final DateTime? createdAt;
  final String? body;
  final String? senderId;
  final String? sender;
  final bool? isMine;

  factory MessageResponse.fromJson(Object? json) {
    final map = _map(json);
    final senderMap = _mapOrNull(map['sender']);
    return MessageResponse(
      id: _int(map['message_id'] ?? map['id']),
      createdAt: _nullableDateTime(map['created_at']),
      body: _nullableString(map['body']),
      senderId: _nullableString(map['sender_id'] ?? senderMap?['id']),
      sender:
          _personName(senderMap) ??
          _nullableString(map['sender_name'] ?? map['sender']),
      isMine: _nullableBool(
        map['is_mine'] ??
            map['isMine'] ??
            map['mine'] ??
            map['from_current_user'],
      ),
    );
  }
}

class DeleteResponse {
  const DeleteResponse({required this.deleted});

  final bool deleted;

  factory DeleteResponse.fromJson(Object? json) =>
      DeleteResponse(deleted: _bool(_map(json)['deleted']));
}

Map<String, dynamic> _dataOrSelf(Object? value) {
  final map = _map(value);
  final data = map['data'];
  if (data is Map) return _map(data);
  return map;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry('$key', item));
  return const {};
}

Map<String, dynamic>? _mapOrNull(Object? value) {
  if (value is Map) return _map(value);
  return null;
}

List<T> _list<T>(Object? value, T Function(Object? item) fromJson) {
  if (value is! List) return const [];
  return value.map(fromJson).toList();
}

String _string(Object? value) => value?.toString() ?? '';

String? _nullableString(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

int _int(Object? value) => _nullableInt(value) ?? 0;

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double _double(Object? value) {
  return _nullableDouble(value) ?? 0;
}

double? _nullableDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool _bool(Object? value) => _nullableBool(value) ?? false;

bool? _nullableBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}

UserRole _role(Object? value) => _nullableRole(value) ?? UserRole.mentee;

UserRole? _nullableRole(Object? value) {
  final text = value?.toString().toLowerCase().trim();
  if (text == 'mentor' || text == 'mentor_user' || text == 'teacher') {
    return UserRole.mentor;
  }
  if (text == 'mentee' || text == 'mentee_user' || text == 'student') {
    return UserRole.mentee;
  }
  return null;
}

DateTime _dateTime(Object? value) =>
    _nullableDateTime(value) ?? DateTime.fromMillisecondsSinceEpoch(0);

DateTime? _nullableDateTime(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}

List<String> _stringItems(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) {
        if (item is Map) return _string(_map(item)['name']);
        return _string(item);
      })
      .where((item) => item.trim().isNotEmpty)
      .toList();
}

List<int> _idItems(Object? value) {
  if (value is String) {
    return value
        .split(',')
        .map((item) => int.tryParse(item.trim()))
        .whereType<int>()
        .toList();
  }
  if (value is! List) return const [];
  return value
      .map(
        (item) =>
            item is Map ? _nullableInt(_map(item)['id']) : _nullableInt(item),
      )
      .whereType<int>()
      .toList();
}

List<String> _personItems(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) {
        if (item is Map) return _personName(_map(item)) ?? '';
        return _string(item);
      })
      .where((item) => item.trim().isNotEmpty)
      .toList();
}

String? _personName(Map<String, dynamic>? map) {
  if (map == null) return null;
  final name = _nullableString(
    map['name'] ?? map['full_name'] ?? map['display_name'],
  );
  if (name != null) return name;
  final first = _nullableString(map['first_name']);
  final last = _nullableString(map['last_name']);
  final combined = [first, last].whereType<String>().join(' ').trim();
  if (combined.isNotEmpty) return combined;
  return _nullableString(map['email']);
}

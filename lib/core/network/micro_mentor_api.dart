import '../models/api_models.dart';
import '../models/mentor_onboarding.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import 'api_response.dart';

class MicroMentorApi {
  MicroMentorApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ApiResponse<AuthResponse>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) {
    return _client.post(
      ApiEndpoints.register,
      authorized: false,
      body: JsonRequestBody({
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
      }),
      decoder: AuthResponse.fromJson,
    );
  }

  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) {
    return _client.post(
      ApiEndpoints.login,
      authorized: false,
      body: JsonRequestBody({'email': email, 'password': password}),
      decoder: AuthResponse.fromJson,
    );
  }

  Future<ApiResponse<TokenRefreshResponse>> refreshToken({
    required String refreshToken,
  }) {
    return _client.post(
      ApiEndpoints.tokenRefresh,
      authorized: false,
      body: JsonRequestBody({'refresh_token': refreshToken}),
      decoder: TokenRefreshResponse.fromJson,
    );
  }

  Future<ApiResponse<DetailMessageResponse>> logout() => _client.post(
    ApiEndpoints.logout,
    decoder: DetailMessageResponse.fromJson,
  );

  Future<ApiResponse<HomeResponse>> home() =>
      _client.get(ApiEndpoints.home, decoder: HomeResponse.fromJson);

  Future<ApiResponse<bool>> health() => _client.get(
    ApiEndpoints.health,
    authorized: false,
    decoder: (json) => json is Map && json['status'] == 'ok',
  );

  Future<ApiResponse<ApiListResponse<MentorListItem>>> listMentors({
    String? q,
    String? category,
    int page = 1,
    int pageSize = 20,
  }) {
    return _client.get(
      ApiEndpoints.mentors,
      queryParameters: {
        'q': q,
        'category': category,
        'page': page,
        'page_size': pageSize,
      },
      decoder: (json) => ApiListResponse.fromJson(
        json,
        (item) => MentorListItem.fromJson(item),
      ),
    );
  }

  Future<ApiResponse<MentorDetailResponse>> getMentor(Object mentorId) =>
      _client.get(
        ApiEndpoints.mentorDetail(mentorId),
        decoder: MentorDetailResponse.fromJson,
      );

  Future<ApiResponse<MentorAvailabilityResponse>> getMentorAvailability(
    Object mentorId, {
    DateTime? from,
    DateTime? to,
    int? durationMinutes,
    String? timezone,
  }) => _client.get(
    ApiEndpoints.mentorAvailability(mentorId),
    queryParameters: {
      if (from != null) 'from': _dateOnly(from),
      if (to != null) 'to': _dateOnly(to),
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (timezone != null) 'timezone': timezone,
    },
    decoder: MentorAvailabilityResponse.fromJson,
  );

  Future<ApiResponse<BookingCreateResponse>> createBooking({
    required Object packageId,
    required DateTime startsAt,
    String? goals,
    String? topic,
  }) {
    return _client.post(
      ApiEndpoints.bookings,
      body: {
        'package_id': packageId,
        'starts_at': startsAt.toUtc().toIso8601String(),
        if (goals != null) 'goals': goals,
        if (topic != null) 'topic': topic,
      },
      decoder: BookingCreateResponse.fromJson,
    );
  }

  Future<ApiResponse<ApiListResponse<SessionDetailResponse>>> listBookings({
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) => _client.get(
    ApiEndpoints.bookings,
    queryParameters: {
      'status': status,
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
      'page': page,
      'page_size': pageSize,
    },
    decoder: (json) => ApiListResponse.fromJson(
      json,
      (item) => SessionDetailResponse.fromJson(item),
    ),
  );

  Future<ApiResponse<SessionStatusResponse>> cancelSession(Object sessionId) =>
      _client.post(
        ApiEndpoints.cancelSession(sessionId),
        body: const JsonRequestBody({}),
        decoder: SessionStatusResponse.fromJson,
      );

  Future<ApiResponse<SessionDetailResponse>> getSession(Object sessionId) =>
      _client.get(
        ApiEndpoints.sessionDetail(sessionId),
        decoder: SessionDetailResponse.fromJson,
      );

  Future<ApiResponse<PaymentConfirmationResponse>> confirmPayment({
    required Object sessionId,
    required String providerPaymentId,
  }) {
    return _client.post(
      ApiEndpoints.confirmPayment(sessionId),
      body: {'provider_payment_id': providerPaymentId},
      decoder: PaymentConfirmationResponse.fromJson,
    );
  }

  Future<ApiResponse<PaymentStatusResponse>> getPaymentStatus(
    Object sessionId,
  ) => _client.get(
    ApiEndpoints.paymentStatus(sessionId),
    decoder: PaymentStatusResponse.fromJson,
  );

  Future<ApiResponse<SessionStatusResponse>> completeSession(
    Object sessionId,
  ) => _client.post(
    ApiEndpoints.completeSession(sessionId),
    decoder: SessionStatusResponse.fromJson,
  );

  Future<ApiResponse<ReviewMutationResponse>> submitSessionReview({
    required Object sessionId,
    required int rating,
    required String body,
  }) {
    return _client.post(
      ApiEndpoints.submitSessionReview(sessionId),
      body: {'rating': rating, 'body': body},
      decoder: ReviewMutationResponse.fromJson,
    );
  }

  Future<ApiResponse<ProfileResponse>> getProfile() =>
      _client.get(ApiEndpoints.profile, decoder: ProfileResponse.fromJson);

  Future<ApiResponse<MentorDashboardResponse>> getMentorDashboard() =>
      _client.get(
        ApiEndpoints.mentorDashboard,
        decoder: MentorDashboardResponse.fromJson,
      );

  Future<ApiResponse<MentorOnboardingDraft>> getMentorOnboarding() =>
      _client.get(
        ApiEndpoints.mentorOnboarding,
        decoder: MentorOnboardingDraft.fromJson,
      );

  Future<ApiResponse<MentorOnboardingDraft>> updateMentorOnboarding(
    Map<String, dynamic> body, {
    String? etag,
  }) => _client.patch(
    ApiEndpoints.mentorOnboarding,
    body: JsonRequestBody(body),
    headers: {if (etag != null && etag.isNotEmpty) 'If-Match': etag},
    decoder: MentorOnboardingDraft.fromJson,
  );

  Future<ApiResponse<MentorOnboardingDraft>> getMentorOnboardingStatus() =>
      _client.get(
        ApiEndpoints.mentorOnboardingStatus,
        decoder: MentorOnboardingDraft.fromJson,
      );

  Future<ApiResponse<MentorSubmissionResponse>> submitMentorOnboarding({
    required bool confirmInformationAccurate,
    required String termsVersion,
  }) => _client.post(
    ApiEndpoints.mentorOnboardingSubmit,
    body: JsonRequestBody({
      'confirm_information_accurate': confirmInformationAccurate,
      'terms_version': termsVersion,
    }),
    decoder: MentorSubmissionResponse.fromJson,
  );

  Future<ApiResponse<MentorUploadRequest>> requestMentorDocumentUpload({
    required String documentType,
    required String fileName,
    required String contentType,
    required int sizeBytes,
  }) => _client.post(
    ApiEndpoints.mentorDocumentUploadRequest,
    body: JsonRequestBody({
      'document_type': documentType,
      'file_name': fileName,
      'content_type': contentType,
      'size_bytes': sizeBytes,
    }),
    decoder: MentorUploadRequest.fromJson,
  );

  Future<ApiResponse<void>> uploadMentorDocumentBytes({
    required MentorUploadRequest request,
    required List<int> bytes,
  }) => _client.uploadBytes(
    request.uploadUrl,
    bytes,
    headers: request.uploadHeaders,
  );

  Future<ApiResponse<MentorDocument>> confirmMentorDocument({
    required Object documentId,
    required String checksumSha256,
  }) => _client.post(
    ApiEndpoints.mentorDocumentConfirm(documentId),
    body: JsonRequestBody({'checksum_sha256': checksumSha256}),
    decoder: MentorDocument.fromJson,
  );

  Future<ApiResponse<void>> deleteMentorDocument(Object documentId) =>
      _client.delete(ApiEndpoints.mentorDocument(documentId));

  Future<ApiResponse<ApiListResponse<CategoryResponse>>> listCategories() =>
      _client.get(
        ApiEndpoints.categories,
        authorized: false,
        decoder: (json) => ApiListResponse.fromJson(
          json,
          (item) => CategoryResponse.fromJson(item),
        ),
      );

  Future<ApiResponse<CategoryResponse>> createCategory(
    Map<String, dynamic> body,
  ) => _client.post(
    ApiEndpoints.categories,
    body: body,
    decoder: CategoryResponse.fromJson,
  );

  Future<ApiResponse<CategoryResponse>> getCategory(Object categoryId) =>
      _client.get(
        ApiEndpoints.category(categoryId),
        authorized: false,
        decoder: CategoryResponse.fromJson,
      );

  Future<ApiResponse<CategoryResponse>> updateCategory(
    Object categoryId,
    Map<String, dynamic> body,
  ) => _client.patch(
    ApiEndpoints.category(categoryId),
    body: body,
    decoder: CategoryResponse.fromJson,
  );

  Future<ApiResponse<DeleteResponse>> deleteCategory(Object categoryId) =>
      _client.delete(
        ApiEndpoints.category(categoryId),
        decoder: DeleteResponse.fromJson,
      );

  Future<ApiResponse<ApiListResponse<ExpertiseResponse>>> listExpertise() =>
      _client.get(
        ApiEndpoints.expertise,
        authorized: false,
        decoder: (json) => ApiListResponse.fromJson(
          json,
          (item) => ExpertiseResponse.fromJson(item),
        ),
      );

  Future<ApiResponse<ExpertiseResponse>> createExpertise(
    Map<String, dynamic> body,
  ) => _client.post(
    ApiEndpoints.expertise,
    body: body,
    decoder: ExpertiseResponse.fromJson,
  );

  Future<ApiResponse<ExpertiseResponse>> getExpertise(Object expertiseId) =>
      _client.get(
        ApiEndpoints.expertiseDetail(expertiseId),
        authorized: false,
        decoder: ExpertiseResponse.fromJson,
      );

  Future<ApiResponse<ExpertiseResponse>> updateExpertise(
    Object expertiseId,
    Map<String, dynamic> body,
  ) => _client.patch(
    ApiEndpoints.expertiseDetail(expertiseId),
    body: body,
    decoder: ExpertiseResponse.fromJson,
  );

  Future<ApiResponse<DeleteResponse>> deleteExpertise(Object expertiseId) =>
      _client.delete(
        ApiEndpoints.expertiseDetail(expertiseId),
        decoder: DeleteResponse.fromJson,
      );

  Future<ApiResponse<ApiListResponse<MentorProfileResponse>>>
  listMentorProfiles() => _client.get(
    ApiEndpoints.mentorProfiles,
    authorized: false,
    decoder: (json) => ApiListResponse.fromJson(
      json,
      (item) => MentorProfileResponse.fromJson(item),
    ),
  );

  Future<ApiResponse<MentorProfileResponse>> getMentorProfile(
    Object mentorId,
  ) => _client.get(
    ApiEndpoints.mentorProfile(mentorId),
    authorized: false,
    decoder: MentorProfileResponse.fromJson,
  );

  Future<ApiResponse<MentorProfileResponse>> updateMentorProfile(
    Object mentorId,
    Map<String, dynamic> body,
  ) => _client.patch(
    ApiEndpoints.mentorProfile(mentorId),
    body: body,
    decoder: MentorProfileResponse.fromJson,
  );

  Future<ApiResponse<DeleteResponse>> deactivateMentorProfile(
    Object mentorId,
  ) => _client.delete(
    ApiEndpoints.mentorProfile(mentorId),
    decoder: DeleteResponse.fromJson,
  );

  Future<ApiResponse<ApiListResponse<PackageResponse>>> listPackages({
    Object? mentorId,
  }) => _client.get(
    ApiEndpoints.packages,
    authorized: false,
    queryParameters: {'mentor_id': mentorId},
    decoder: (json) => ApiListResponse.fromJson(
      json,
      (item) => PackageResponse.fromJson(item),
    ),
  );

  Future<ApiResponse<PackageResponse>> createPackage(
    Map<String, dynamic> body,
  ) => _client.post(
    ApiEndpoints.packages,
    body: body,
    decoder: PackageResponse.fromJson,
  );

  Future<ApiResponse<PackageResponse>> getPackage(Object packageId) =>
      _client.get(
        ApiEndpoints.packageDetail(packageId),
        authorized: false,
        decoder: PackageResponse.fromJson,
      );

  Future<ApiResponse<PackageResponse>> updatePackage(
    Object packageId,
    Map<String, dynamic> body,
  ) => _client.patch(
    ApiEndpoints.packageDetail(packageId),
    body: body,
    decoder: PackageResponse.fromJson,
  );

  Future<ApiResponse<DeleteResponse>> deletePackage(Object packageId) =>
      _client.delete(
        ApiEndpoints.packageDetail(packageId),
        decoder: DeleteResponse.fromJson,
      );

  Future<ApiResponse<ApiListResponse<AvailabilityWindowResponse>>>
  listAvailability({Object? mentorId}) => _client.get(
    ApiEndpoints.availabilityWindows,
    authorized: false,
    queryParameters: {'mentor_id': mentorId},
    decoder: (json) => ApiListResponse.fromJson(
      json,
      (item) => AvailabilityWindowResponse.fromJson(item),
    ),
  );

  Future<ApiResponse<AvailabilityWindowResponse>> createAvailabilityWindow(
    Map<String, dynamic> body,
  ) => _client.post(
    ApiEndpoints.availabilityWindows,
    body: body,
    decoder: AvailabilityWindowResponse.fromJson,
  );

  Future<ApiResponse<AvailabilityWindowResponse>> getAvailabilityWindow(
    Object windowId,
  ) => _client.get(
    ApiEndpoints.availabilityWindow(windowId),
    authorized: false,
    decoder: AvailabilityWindowResponse.fromJson,
  );

  Future<ApiResponse<AvailabilityWindowResponse>> updateAvailabilityWindow(
    Object windowId,
    Map<String, dynamic> body,
  ) => _client.patch(
    ApiEndpoints.availabilityWindow(windowId),
    body: body,
    decoder: AvailabilityWindowResponse.fromJson,
  );

  Future<ApiResponse<DeleteResponse>> deleteAvailabilityWindow(
    Object windowId,
  ) => _client.delete(
    ApiEndpoints.availabilityWindow(windowId),
    decoder: DeleteResponse.fromJson,
  );

  Future<ApiResponse<ApiListResponse<ReviewMutationResponse>>> listReviews({
    Object? mentorId,
    Object? sessionId,
  }) => _client.get(
    ApiEndpoints.reviews,
    queryParameters: {'mentor_id': mentorId, 'session_id': sessionId},
    decoder: (json) => ApiListResponse.fromJson(
      json,
      (item) => ReviewMutationResponse.fromJson(item),
    ),
  );

  Future<ApiResponse<ReviewMutationResponse>> createReview(
    Map<String, dynamic> body,
  ) => _client.post(
    ApiEndpoints.reviews,
    body: body,
    decoder: ReviewMutationResponse.fromJson,
  );

  Future<ApiResponse<ReviewMutationResponse>> getReview(Object reviewId) =>
      _client.get(
        ApiEndpoints.review(reviewId),
        decoder: ReviewMutationResponse.fromJson,
      );

  Future<ApiResponse<ReviewMutationResponse>> updateReview(
    Object reviewId,
    Map<String, dynamic> body,
  ) => _client.patch(
    ApiEndpoints.review(reviewId),
    body: body,
    decoder: ReviewMutationResponse.fromJson,
  );

  Future<ApiResponse<DeleteResponse>> deleteReview(Object reviewId) => _client
      .delete(ApiEndpoints.review(reviewId), decoder: DeleteResponse.fromJson);

  Future<ApiResponse<ApiListResponse<ConversationCreateResponse>>>
  listConversations() => _client.get(
    ApiEndpoints.conversations,
    decoder: (json) => ApiListResponse.fromJson(
      json,
      (item) => ConversationCreateResponse.fromJson(item),
    ),
  );

  Future<ApiResponse<ConversationCreateResponse>> createConversation({
    Object? mentorId,
    Object? sessionId,
    String type = 'inquiry',
  }) {
    return _client.post(
      ApiEndpoints.conversations,
      body: JsonRequestBody({
        'type': type,
        if (mentorId != null) 'mentor_id': _wireId(mentorId),
        if (sessionId != null) 'session_id': _wireId(sessionId),
      }),
      decoder: ConversationCreateResponse.fromJson,
    );
  }

  Future<ApiResponse<ConversationDetailResponse>> getConversation(
    Object conversationId,
  ) => _client.get(
    ApiEndpoints.conversation(conversationId),
    decoder: ConversationDetailResponse.fromJson,
  );

  Future<ApiResponse<DeleteResponse>> deleteConversation(
    Object conversationId,
  ) => _client.delete(
    ApiEndpoints.conversation(conversationId),
    decoder: DeleteResponse.fromJson,
  );

  Future<ApiResponse<MessageResponse>> sendMessage({
    required Object conversationId,
    required String body,
  }) {
    return _client.post(
      ApiEndpoints.conversationMessages(conversationId),
      body: JsonRequestBody({'body': body}),
      decoder: MessageResponse.fromJson,
    );
  }

  Future<ApiResponse<ApiListResponse<MessageResponse>>> listMessages(
    Object conversationId,
  ) => _client.get(
    ApiEndpoints.conversationMessages(conversationId),
    decoder: (json) => ApiListResponse.fromJson(
      json,
      (item) => MessageResponse.fromJson(item),
    ),
  );
}

Object _wireId(Object value) {
  if (value is int) return value;
  final parsed = int.tryParse(value.toString());
  return parsed ?? value;
}

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

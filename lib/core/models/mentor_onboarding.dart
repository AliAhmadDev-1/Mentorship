class MentorOnboardingDraft {
  const MentorOnboardingDraft({
    required this.id,
    required this.status,
    required this.currentStep,
    required this.completionPercent,
    required this.version,
    required this.professionalProfile,
    required this.categoryIds,
    required this.expertiseIds,
    required this.documents,
    required this.packages,
    required this.availabilityWindows,
    required this.acceptsInquiries,
    required this.fieldsRequiringChanges,
    required this.canEdit,
    required this.canSubmit,
    this.timezone,
    this.submittedAt,
    this.reviewedAt,
    this.reviewNotes,
  });

  final int id;
  final String status;
  final String currentStep;
  final int completionPercent;
  final int version;
  final MentorProfessionalProfile professionalProfile;
  final List<int> categoryIds;
  final List<int> expertiseIds;
  final List<MentorDocument> documents;
  final List<MentorDraftPackage> packages;
  final List<MentorDraftAvailability> availabilityWindows;
  final bool acceptsInquiries;
  final String? timezone;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final List<String> fieldsRequiringChanges;
  final bool canEdit;
  final bool canSubmit;

  bool get isUnderReview => status == 'pending_review';
  bool get isVerified => status == 'verified';
  bool get isRejected => status == 'rejected';

  factory MentorOnboardingDraft.fromJson(Object? json) {
    final map = _map(json);
    return MentorOnboardingDraft(
      id: _int(map['id'] ?? map['application_id']),
      status: _string(map['status'], fallback: 'draft'),
      currentStep: _string(
        map['current_step'],
        fallback: 'professional_profile',
      ),
      completionPercent: _int(map['completion_percent']),
      version: _int(map['version'], fallback: 1),
      professionalProfile: MentorProfessionalProfile.fromJson(
        map['professional_profile'],
      ),
      categoryIds: _intList(map['category_ids']),
      expertiseIds: _intList(map['expertise_ids']),
      documents: _list(map['documents'], MentorDocument.fromJson),
      packages: _list(map['packages'], MentorDraftPackage.fromJson),
      availabilityWindows: _list(
        map['availability_windows'],
        MentorDraftAvailability.fromJson,
      ),
      acceptsInquiries: _bool(map['accepts_inquiries'], fallback: true),
      timezone: _nullableString(map['timezone']),
      submittedAt: _date(map['submitted_at']),
      reviewedAt: _date(map['reviewed_at']),
      reviewNotes: _nullableString(map['review_notes']),
      fieldsRequiringChanges: _stringList(map['fields_requiring_changes']),
      canEdit: _bool(map['can_edit'], fallback: true),
      canSubmit: _bool(map['can_submit']),
    );
  }
}

class MentorProfessionalProfile {
  const MentorProfessionalProfile({
    this.profession,
    this.headline,
    this.company,
    this.yearsExperience,
    this.bio,
    this.linkedinUrl,
    this.portfolioUrl,
  });

  final String? profession;
  final String? headline;
  final String? company;
  final int? yearsExperience;
  final String? bio;
  final String? linkedinUrl;
  final String? portfolioUrl;

  factory MentorProfessionalProfile.fromJson(Object? json) {
    final map = _map(json);
    return MentorProfessionalProfile(
      profession: _nullableString(map['profession']),
      headline: _nullableString(map['headline']),
      company: _nullableString(map['company']),
      yearsExperience: _nullableInt(map['years_experience']),
      bio: _nullableString(map['bio']),
      linkedinUrl: _nullableString(map['linkedin_url']),
      portfolioUrl: _nullableString(map['portfolio_url']),
    );
  }
}

class MentorDocument {
  const MentorDocument({
    required this.id,
    required this.documentType,
    required this.fileName,
    required this.status,
    this.uploadedAt,
    this.createdAt,
  });

  final int id;
  final String documentType;
  final String fileName;
  final String status;
  final DateTime? uploadedAt;
  final DateTime? createdAt;

  bool get isReady => status == 'ready';
  bool get isProcessing =>
      status == 'requested' || status == 'uploaded' || status == 'scanning';

  factory MentorDocument.fromJson(Object? json) {
    final map = _map(json);
    return MentorDocument(
      id: _int(map['id'] ?? map['document_id']),
      documentType: _string(map['document_type']),
      fileName: _string(map['file_name']),
      status: _string(map['status'], fallback: 'requested'),
      uploadedAt: _date(map['uploaded_at']),
      createdAt: _date(map['created_at']),
    );
  }
}

class MentorDraftPackage {
  const MentorDraftPackage({
    required this.clientId,
    required this.durationMinutes,
    required this.priceUsd,
    required this.isPopular,
    required this.isActive,
  });

  final String clientId;
  final int durationMinutes;
  final String priceUsd;
  final bool isPopular;
  final bool isActive;

  factory MentorDraftPackage.fromJson(Object? json) {
    final map = _map(json);
    final duration = _int(map['duration_minutes']);
    return MentorDraftPackage(
      clientId: _string(map['client_id'], fallback: 'mobile-$duration'),
      durationMinutes: duration,
      priceUsd: _string(map['price_usd'], fallback: '0.00'),
      isPopular: _bool(map['is_popular']),
      isActive: _bool(map['is_active'], fallback: true),
    );
  }
}

class MentorDraftAvailability {
  const MentorDraftAvailability({
    required this.clientId,
    required this.weekday,
    required this.startsAt,
    required this.endsAt,
    required this.slotIntervalMinutes,
    required this.isActive,
  });

  final String clientId;
  final int weekday;
  final String startsAt;
  final String endsAt;
  final int slotIntervalMinutes;
  final bool isActive;

  factory MentorDraftAvailability.fromJson(Object? json) {
    final map = _map(json);
    final weekday = _int(map['weekday'], fallback: 1);
    final startsAt = _string(map['starts_at'], fallback: '09:00:00');
    return MentorDraftAvailability(
      clientId: _string(
        map['client_id'],
        fallback: 'day-$weekday-${startsAt.replaceAll(':', '')}',
      ),
      weekday: weekday,
      startsAt: startsAt,
      endsAt: _string(map['ends_at'], fallback: '17:00:00'),
      slotIntervalMinutes: _int(map['slot_interval_minutes'], fallback: 30),
      isActive: _bool(map['is_active'], fallback: true),
    );
  }
}

class MentorOnboardingSummary {
  const MentorOnboardingSummary({
    required this.applicationId,
    required this.status,
    required this.currentStep,
    required this.completionPercent,
    required this.version,
  });

  final int applicationId;
  final String status;
  final String currentStep;
  final int completionPercent;
  final int version;

  factory MentorOnboardingSummary.fromJson(Object? json) {
    final map = _map(json);
    return MentorOnboardingSummary(
      applicationId: _int(map['application_id'] ?? map['id']),
      status: _string(map['status'], fallback: 'draft'),
      currentStep: _string(
        map['current_step'],
        fallback: 'professional_profile',
      ),
      completionPercent: _int(map['completion_percent']),
      version: _int(map['version'], fallback: 1),
    );
  }
}

class MentorUploadRequest {
  const MentorUploadRequest({
    required this.documentId,
    required this.uploadUrl,
    required this.uploadMethod,
    required this.uploadHeaders,
    this.expiresAt,
  });

  final int documentId;
  final String uploadUrl;
  final String uploadMethod;
  final Map<String, String> uploadHeaders;
  final DateTime? expiresAt;

  factory MentorUploadRequest.fromJson(Object? json) {
    final map = _map(json);
    final rawHeaders = _map(map['upload_headers']);
    return MentorUploadRequest(
      documentId: _int(map['document_id']),
      uploadUrl: _string(map['upload_url']),
      uploadMethod: _string(map['upload_method'], fallback: 'PUT'),
      uploadHeaders: rawHeaders.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      expiresAt: _date(map['expires_at']),
    );
  }
}

class MentorSubmissionResponse {
  const MentorSubmissionResponse({
    required this.applicationId,
    required this.status,
    this.submittedAt,
    this.estimatedReviewDays,
  });

  final int applicationId;
  final String status;
  final DateTime? submittedAt;
  final int? estimatedReviewDays;

  factory MentorSubmissionResponse.fromJson(Object? json) {
    final map = _map(json);
    return MentorSubmissionResponse(
      applicationId: _int(map['application_id']),
      status: _string(map['status']),
      submittedAt: _date(map['submitted_at']),
      estimatedReviewDays: _nullableInt(map['estimated_review_days']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

List<T> _list<T>(Object? value, T Function(Object?) parser) =>
    value is List ? value.map(parser).toList() : const [];

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

int _int(Object? value, {int fallback = 0}) => _nullableInt(value) ?? fallback;

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool _bool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return fallback;
}

DateTime? _date(Object? value) => DateTime.tryParse(value?.toString() ?? '');

List<int> _intList(Object? value) => value is List
    ? value.map(_nullableInt).whereType<int>().toList()
    : const [];

List<String> _stringList(Object? value) =>
    value is List ? value.map((item) => item.toString()).toList() : const [];

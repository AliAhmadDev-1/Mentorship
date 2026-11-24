import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/mentor_onboarding.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/error_handler.dart';
import '../../../core/providers/api_provider.dart';

const mentorTermsVersion = 'mentor-terms-2026-08';

final mentorOnboardingProvider =
    AsyncNotifierProvider<MentorOnboardingNotifier, MentorOnboardingDraft>(
      MentorOnboardingNotifier.new,
    );

class MentorOnboardingNotifier extends AsyncNotifier<MentorOnboardingDraft> {
  String? _etag;

  @override
  Future<MentorOnboardingDraft> build() => _load();

  Future<MentorOnboardingDraft> reload() async {
    final draft = await _load();
    state = AsyncData(draft);
    return draft;
  }

  Future<MentorOnboardingDraft> save(Map<String, dynamic> section) async {
    final response = await ref
        .read(microMentorApiProvider)
        .updateMentorOnboarding(section, etag: _etag);
    if (!response.success) {
      if (response.error?.statusCode == 409 &&
          response.error?.code == 'stale_application_version') {
        await reload();
      }
      throw response.error!;
    }
    _etag = response.etag ?? _etag;
    final draft = _requireData(response);
    state = AsyncData(draft);
    return draft;
  }

  Future<void> uploadDocument({
    required String documentType,
    required String fileName,
    required String contentType,
    required List<int> bytes,
  }) async {
    if (bytes.length > 10 * 1024 * 1024) {
      throw const ApiException(
        message: 'Choose a file smaller than 10 MB.',
        type: ApiExceptionType.validation,
      );
    }
    final api = ref.read(microMentorApiProvider);
    final requestResponse = await api.requestMentorDocumentUpload(
      documentType: documentType,
      fileName: fileName,
      contentType: contentType,
      sizeBytes: bytes.length,
    );
    if (!requestResponse.success) throw requestResponse.error!;
    final request = _requireData(requestResponse);
    final uploadResponse = await api.uploadMentorDocumentBytes(
      request: request,
      bytes: bytes,
    );
    if (!uploadResponse.success) throw uploadResponse.error!;
    final checksum = sha256.convert(bytes).toString();
    final confirmResponse = await api.confirmMentorDocument(
      documentId: request.documentId,
      checksumSha256: checksum,
    );
    if (!confirmResponse.success) throw confirmResponse.error!;
    await _pollDocument(request.documentId);
  }

  Future<void> deleteDocument(Object documentId) async {
    final response = await ref
        .read(microMentorApiProvider)
        .deleteMentorDocument(documentId);
    if (!response.success) throw response.error!;
    await reload();
  }

  Future<MentorSubmissionResponse> submit() async {
    final response = await ref
        .read(microMentorApiProvider)
        .submitMentorOnboarding(
          confirmInformationAccurate: true,
          termsVersion: mentorTermsVersion,
        );
    if (!response.success) throw response.error!;
    final submission = _requireData(response);
    await reload();
    return submission;
  }

  Future<MentorOnboardingDraft> _load() async {
    final response = await ref
        .read(microMentorApiProvider)
        .getMentorOnboarding();
    if (!response.success) throw response.error!;
    _etag = response.etag;
    return _requireData(response);
  }

  Future<void> _pollDocument(int documentId) async {
    const terminalStatuses = {'ready', 'unsafe', 'rejected', 'deleted'};
    for (var attempt = 0; attempt < 6; attempt++) {
      final draft = await reload();
      MentorDocument? document;
      for (final item in draft.documents) {
        if (item.id == documentId) {
          document = item;
          break;
        }
      }
      if (document != null && terminalStatuses.contains(document.status)) {
        return;
      }
      if (attempt < 5) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
  }
}

T _requireData<T>(ApiResponse<T> response) {
  final data = response.data;
  if (data != null) return data;
  throw const ApiException(
    message: ErrorHandler.invalidFormatMessage,
    type: ApiExceptionType.parseError,
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentorship/core/models/api_models.dart';
import 'package:mentorship/core/models/mentor_onboarding.dart';
import 'package:mentorship/core/network/api_response.dart';
import 'package:mentorship/core/network/micro_mentor_api.dart';
import 'package:mentorship/core/providers/api_provider.dart';
import 'package:mentorship/features/mentor_onboarding/presentation/mentor_onboarding_screen.dart';

void main() {
  testWidgets('submits a complete mentor draft and shows review status', (
    tester,
  ) async {
    final api = _OnboardingApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [microMentorApiProvider.overrideWithValue(api)],
        child: const MaterialApp(home: MentorOnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Submit for review'), findsOneWidget);

    await tester.tap(
      find.text('I confirm that the information provided is accurate.'),
    );
    await tester.pump();
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    expect(api.submissions, 1);
    expect(api.termsVersion, 'mentor-terms-2026-08');
    expect(find.text('Application under review'), findsOneWidget);
  });

  testWidgets('allows submission without proof while documents are optional', (
    tester,
  ) async {
    final api = _OnboardingApi(includeProfessionalDocument: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [microMentorApiProvider.overrideWithValue(api)],
        child: const MaterialApp(home: MentorOnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('I confirm that the information provided is accurate.'),
    );
    await tester.pump();

    final submit = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Submit for review'),
    );
    expect(submit.onPressed, isNotNull);

    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();
    expect(api.submissions, 1);
  });

  testWidgets('resumes at the current step returned by the backend', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          microMentorApiProvider.overrideWithValue(
            _OnboardingApi(currentStep: 'services'),
          ),
        ],
        child: const MaterialApp(home: MentorOnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Price USD'), findsWidgets);
  });

  testWidgets('editing an earlier screen preserves the furthest saved step', (
    tester,
  ) async {
    final api = _OnboardingApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [microMentorApiProvider.overrideWithValue(api)],
        child: const MaterialApp(home: MentorOnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back'));
    await tester.pump();
    expect(find.text('Availability'), findsOneWidget);

    await tester.tap(find.text('Save & continue'));
    await tester.pumpAndSettle();

    expect(api.lastUpdate?['current_step'], 'review');
    expect(find.text('Review'), findsOneWidget);
  });
}

class _OnboardingApi extends MicroMentorApi {
  _OnboardingApi({
    this.includeProfessionalDocument = true,
    this.currentStep = 'review',
  });

  final bool includeProfessionalDocument;
  final String currentStep;
  var submissions = 0;
  String? termsVersion;
  Map<String, dynamic>? lastUpdate;

  @override
  Future<ApiResponse<MentorOnboardingDraft>> getMentorOnboarding() async =>
      ApiResponse.success(
        MentorOnboardingDraft.fromJson({
          'id': 18,
          'status': submissions == 0 ? 'draft' : 'pending_review',
          'current_step': currentStep,
          'completion_percent': submissions == 0 ? 95 : 100,
          'version': 6,
          'professional_profile': {
            'profession': 'software_engineering',
            'headline': 'Senior Flutter Engineer',
            'years_experience': 8,
            'bio': List.filled(12, 'Experienced mobile mentor').join(' '),
          },
          'category_ids': [1],
          'expertise_ids': [2],
          'documents': includeProfessionalDocument
              ? [
                  {
                    'id': 71,
                    'document_type': 'employment',
                    'file_name': 'proof.pdf',
                    'status': 'ready',
                  },
                ]
              : [],
          'packages': [
            {
              'client_id': 'mobile-30',
              'duration_minutes': 30,
              'price_usd': '35.00',
              'is_popular': true,
              'is_active': true,
            },
          ],
          'timezone': 'Asia/Karachi',
          'availability_windows': [
            {
              'client_id': 'mon-0900',
              'weekday': 1,
              'starts_at': '09:00:00',
              'ends_at': '17:00:00',
              'slot_interval_minutes': 30,
              'is_active': true,
            },
          ],
          'accepts_inquiries': true,
          'fields_requiring_changes': [],
          'can_edit': submissions == 0,
          'can_submit': submissions == 0,
        }),
        headers: const {'etag': '"application-18-version-6"'},
      );

  @override
  Future<ApiResponse<MentorOnboardingDraft>> updateMentorOnboarding(
    Map<String, dynamic> body, {
    String? etag,
  }) async {
    lastUpdate = body;
    return getMentorOnboarding();
  }

  @override
  Future<ApiResponse<ApiListResponse<CategoryResponse>>>
  listCategories() async => const ApiResponse.success(
    ApiListResponse(results: [CategoryResponse(id: 1, name: 'Technology')]),
  );

  @override
  Future<ApiResponse<ApiListResponse<ExpertiseResponse>>>
  listExpertise() async => const ApiResponse.success(
    ApiListResponse(results: [ExpertiseResponse(id: 2, name: 'Flutter')]),
  );

  @override
  Future<ApiResponse<MentorSubmissionResponse>> submitMentorOnboarding({
    required bool confirmInformationAccurate,
    required String termsVersion,
  }) async {
    submissions++;
    this.termsVersion = termsVersion;
    return const ApiResponse.success(
      MentorSubmissionResponse(applicationId: 18, status: 'pending_review'),
    );
  }
}

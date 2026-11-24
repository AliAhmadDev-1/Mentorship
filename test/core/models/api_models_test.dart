import 'package:flutter_test/flutter_test.dart';
import 'package:mentorship/core/models/api_models.dart';
import 'package:mentorship/core/models/app_user.dart';

void main() {
  group('API response models', () {
    test('parses complete mentor login routing fields', () {
      final response = AuthResponse.fromJson({
        'id': 12,
        'email': 'mentor@example.com',
        'first_name': 'Alex',
        'last_name': 'Mentor',
        'role': 'mentor',
        'access_token': 'access',
        'refresh_token': 'refresh',
        'mentor_profile_id': 17,
      });

      final user = response.toUser();
      expect(user.fullName, 'Alex Mentor');
      expect(user.role, UserRole.mentor);
      expect(user.mentorProfileId, '17');
    });

    test('parses auth success responses with tokens', () {
      final response = AuthResponse.fromJson({
        'id': 12,
        'email': 'user@example.com',
        'role': 'mentee',
        'access_token': 'access-token',
        'refresh_token': 'refresh-token',
      });

      expect(response.id, 12);
      expect(response.email, 'user@example.com');
      expect(response.role, UserRole.mentee);
      expect(response.accessToken, 'access-token');
      expect(response.refreshToken, 'refresh-token');
    });

    test('parses onboarding summary from mentor registration', () {
      final response = AuthResponse.fromJson({
        'id': 13,
        'email': 'mentor@example.com',
        'role': 'mentor',
        'onboarding': {
          'application_id': 7,
          'status': 'draft',
          'current_step': 'professional_profile',
          'completion_percent': 0,
          'version': 1,
        },
        'access_token': 'access-token',
      });

      expect(response.role, UserRole.mentor);
      expect(response.onboarding?.applicationId, 7);
      expect(response.onboarding?.currentStep, 'professional_profile');
      expect(response.toUser().mentorProfileId, isNull);
    });

    test('parses list wrapper responses', () {
      final response = ApiListResponse.fromJson({
        'count': 42,
        'next': 'https://api.example.test/api/mentors/?page=2',
        'previous': null,
        'results': [
          {
            'id': 1,
            'name': 'Alice Mentor',
            'headline': 'Senior',
            'starting_price': 50,
          },
        ],
      }, MentorListItem.fromJson);

      expect(response.results.single.id, 1);
      expect(response.results.single.name, 'Alice Mentor');
      expect(response.results.single.startingPrice, 50);
      expect(response.count, 42);
      expect(response.hasNext, true);
      expect(response.hasPrevious, isNull);
    });

    test('parses concrete availability slots and dashboard metrics', () {
      final availability = MentorAvailabilityResponse.fromJson({
        'mentor_id': 17,
        'timezone': 'Asia/Karachi',
        'duration_minutes': 30,
        'slots': [
          {
            'starts_at': '2026-09-24T09:00:00+05:00',
            'ends_at': '2026-09-24T09:30:00+05:00',
            'available': true,
          },
        ],
      });
      final dashboard = MentorDashboardResponse.fromJson({
        'mentor_id': 7,
        'total_sessions': 48,
        'completed_sessions': 41,
        'upcoming_sessions_count': 3,
        'earnings_usd': 1435.0,
        'currency': 'USD',
        'average_rating': 4.8,
        'review_count': 36,
        'repeat_client_percent': 22.5,
      });

      expect(availability.slots.single.available, true);
      expect(availability.slots.single.startsAt.hour, 4);
      expect(availability.timezone, 'Asia/Karachi');
      expect(dashboard.upcomingSessionsCount, 3);
      expect(dashboard.averageRating, 4.8);
      expect(dashboard.reviewCount, 36);
      expect(dashboard.repeatClientPercent, 22.5);
    });

    test('parses editable mentor profile fields and relationship ids', () {
      final profile = MentorProfileResponse.fromJson({
        'data': {
          'id': 17,
          'headline': 'Principal Product Mentor',
          'bio': 'I help product teams grow.',
          'company': 'New Tech Co',
          'years_experience': 10,
          'city': 'Karachi',
          'linkedin_url': 'https://linkedin.com/in/mentor',
          'intro_video_url': 'https://example.com/video',
          'auto_confirm_bookings': true,
          'is_active': true,
          'categories': [
            {'id': 1, 'name': 'Product'},
            {'id': 2, 'name': 'Leadership'},
          ],
          'expertise_ids': '3,4',
        },
      });

      expect(profile.id, 17);
      expect(profile.company, 'New Tech Co');
      expect(profile.yearsExperience, 10);
      expect(profile.categoryIds, [1, 2]);
      expect(profile.categories, ['Product', 'Leadership']);
      expect(profile.expertiseIds, [3, 4]);
      expect(profile.autoConfirmBookings, true);
    });

    test('parses review aliases used by list and mutation endpoints', () {
      final review = ReviewMutationResponse.fromJson({
        'id': 9,
        'rating': 4,
        'comment': 'Very helpful.',
        'reviewer': {'first_name': 'Alex', 'last_name': 'Morgan'},
        'mentor_id': 17,
        'created_at': '2026-09-01T12:00:00Z',
      });

      expect(review.reviewId, 9);
      expect(review.rating, 4);
      expect(review.body, 'Very helpful.');
      expect(review.reviewer, 'Alex Morgan');
      expect(review.mentorId, 17);
    });

    test('parses rich home responses', () {
      final response = HomeResponse.fromJson({
        'data': {
          'user': {'name': 'Jane Doe', 'role': 'mentee'},
          'upcoming_session_id': 42,
          'categories': [
            {'id': 7, 'name': 'AI/ML', 'mentor_count': 12},
          ],
          'featured_mentors': [
            {
              'id': 3,
              'name': 'Alex Mentor',
              'headline': 'AI product coach',
              'company': 'Open Studio',
              'starting_price': 80,
              'expertise': [
                {'name': 'AI'},
                {'name': 'Product'},
              ],
              'rating': 4.8,
              'review_count': 21,
              'verified': true,
            },
          ],
        },
      });

      expect(response.user.name, 'Jane Doe');
      expect(response.upcomingSessionId, 42);
      expect(response.categories.single.mentorCount, 12);
      expect(response.featuredMentors.single.company, 'Open Studio');
      expect(response.featuredMentors.single.expertise, ['AI', 'Product']);
      expect(response.featuredMentors.single.rating, 4.8);
      expect(response.featuredMentors.single.reviewCount, 21);
      expect(response.featuredMentors.single.verified, true);
    });

    test('parses session and payment responses', () {
      final session = SessionDetailResponse.fromJson({
        'id': 42,
        'mentor_id': 4,
        'mentor_name': 'Alice Mentor',
        'mentee_name': 'Jane Mentee',
        'starts_at': '2026-06-20T15:00:00Z',
        'status': 'pending_payment',
        'duration_minutes': 30,
        'price_usd': 125.0,
        'topic': 'Career development',
      });
      final payment = PaymentStatusResponse.fromJson({
        'session_id': 42,
        'amount_usd': 125.0,
        'status': 'paid',
        'provider': 'stripe',
      });

      expect(session.id, 42);
      expect(session.mentorId, 4);
      expect(session.mentor, 'Alice Mentor');
      expect(session.mentee, 'Jane Mentee');
      expect(
        session.startsAt?.toUtc().toIso8601String(),
        '2026-06-20T15:00:00.000Z',
      );
      expect(session.durationMinutes, 30);
      expect(session.amountUsd, 125);
      expect(session.topic, 'Career development');
      expect(payment.sessionId, 42);
      expect(payment.amountUsd, 125);
      expect(payment.status, 'paid');
    });
  });
}

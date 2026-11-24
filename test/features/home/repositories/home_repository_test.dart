import 'package:flutter_test/flutter_test.dart';
import 'package:mentorship/core/models/api_models.dart';
import 'package:mentorship/core/network/api_response.dart';
import 'package:mentorship/core/network/micro_mentor_api.dart';
import 'package:mentorship/features/home/repositories/home_repository.dart';

void main() {
  group('HomeRepository', () {
    test(
      'loads home content from the API and hydrates upcoming session',
      () async {
        final repository = HomeRepository(api: _FakeHomeApi());

        final content = await repository.getHome();

        expect(content.userName, 'Jane Doe');
        expect(content.categories.single.name, 'AI/ML');
        expect(content.categories.single.mentorCount, 12);
        expect(content.featured.single.id, '3');
        expect(content.featured.single.name, 'Alex Mentor');
        expect(content.featured.single.company, 'Open Studio');
        expect(content.featured.single.expertise, ['AI', 'Product']);
        expect(content.featured.single.ratePerSlot, 80);
        expect(content.upcoming?.id, '42');
        expect(content.upcoming?.mentor.name, 'Alice Mentor');
        expect(content.upcoming?.durationMinutes, 30);
        expect(content.upcoming?.sessionGoal, 'Career development');
      },
    );
  });
}

class _FakeHomeApi extends MicroMentorApi {
  @override
  Future<ApiResponse<HomeResponse>> home() async {
    return ApiResponse.success(
      HomeResponse.fromJson({
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
          },
        ],
      }),
    );
  }

  @override
  Future<ApiResponse<SessionDetailResponse>> getSession(
    Object sessionId,
  ) async {
    return ApiResponse.success(
      SessionDetailResponse.fromJson({
        'id': sessionId,
        'mentor': {'id': 4, 'name': 'Alice Mentor'},
        'starts_at': '2026-06-20T15:00:00Z',
        'status': 'confirmed',
        'package': {'duration_minutes': 30, 'price_usd': 125.0},
        'topic': 'Career development',
      }),
    );
  }
}

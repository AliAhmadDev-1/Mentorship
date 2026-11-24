import 'package:flutter_test/flutter_test.dart';
import 'package:mentorship/core/models/api_models.dart';
import 'package:mentorship/core/network/api_response.dart';
import 'package:mentorship/core/network/micro_mentor_api.dart';
import 'package:mentorship/core/repositories/availability_repository.dart';

void main() {
  test(
    'availability reads are scoped and writes derive owner from token',
    () async {
      final api = _AvailabilityApi();
      final repository = AvailabilityRepository(api: api);

      final availability = await repository.getWeeklyAvailability(17);
      await repository.addTimeSlot('Tue', '10:00', '11:00', 17);

      expect(api.listMentorId, 17);
      expect(availability.first.slots, hasLength(1));
      expect(api.createdBody?.containsKey('mentor_id'), isFalse);
      expect(api.createdBody?['weekday'], 2);
    },
  );
}

class _AvailabilityApi extends MicroMentorApi {
  Object? listMentorId;
  Map<String, dynamic>? createdBody;

  @override
  Future<ApiResponse<ApiListResponse<AvailabilityWindowResponse>>>
  listAvailability({Object? mentorId}) async {
    listMentorId = mentorId;
    return const ApiResponse.success(
      ApiListResponse(
        results: [
          AvailabilityWindowResponse(
            id: 4,
            mentorId: 17,
            weekday: 1,
            startsAt: '09:00:00',
            endsAt: '10:00:00',
            isActive: true,
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResponse<AvailabilityWindowResponse>> createAvailabilityWindow(
    Map<String, dynamic> body,
  ) async {
    createdBody = body;
    return const ApiResponse.success(
      AvailabilityWindowResponse(
        id: 5,
        mentorId: 17,
        weekday: 2,
        startsAt: '10:00',
        endsAt: '11:00',
        isActive: true,
      ),
    );
  }
}

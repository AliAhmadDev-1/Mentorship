import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api_models.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';
import '../network/micro_mentor_api.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final microMentorApiProvider = Provider<MicroMentorApi>(
  (ref) => MicroMentorApi(client: ref.watch(apiClientProvider)),
);

final profileProvider =
    FutureProvider.family<ApiResponse<ProfileResponse>, String?>(
      (ref, userId) => ref.read(microMentorApiProvider).getProfile(),
    );

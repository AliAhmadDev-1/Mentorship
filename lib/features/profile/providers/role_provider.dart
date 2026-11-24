import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../auth/providers/auth_provider.dart';

final roleProvider = Provider<UserRole>((ref) {
  final authState = ref.watch(authProvider).valueOrNull;
  return authState?.user?.role ?? UserRole.mentee;
});

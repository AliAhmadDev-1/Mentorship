import 'package:flutter/foundation.dart';

class SessionExpirationNotifier extends ChangeNotifier {
  void notifyExpired() => notifyListeners();
}

final sessionExpirationNotifier = SessionExpirationNotifier();

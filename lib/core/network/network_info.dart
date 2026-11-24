import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  NetworkInfo({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  Future<bool>? _pendingCheck;
  bool? _lastResult;
  DateTime? _lastCheckedAt;

  Future<bool> get isConnected {
    final checkedAt = _lastCheckedAt;
    if (_lastResult != null &&
        checkedAt != null &&
        DateTime.now().difference(checkedAt) < const Duration(seconds: 5)) {
      return Future.value(_lastResult);
    }
    return _pendingCheck ??= _checkConnectivity();
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _lastResult = result.any((item) => item != ConnectivityResult.none);
      _lastCheckedAt = DateTime.now();
      return _lastResult!;
    } finally {
      _pendingCheck = null;
    }
  }
}

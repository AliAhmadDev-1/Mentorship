import 'package:flutter/foundation.dart';

class LoggingInterceptor {
  const LoggingInterceptor();

  void request(
    String method,
    Uri uri,
    Map<String, String> headers,
    Object? body,
  ) {
    if (!kDebugMode) return;
    debugPrint('[API] $method $uri');
    debugPrint('[API] headers=${_masked(headers)}');
    if (body != null) debugPrint('[API] body=${_maskObject(body)}');
  }

  void response(int statusCode, Uri uri, Object? body) {
    if (!kDebugMode) return;
    debugPrint('[API] $statusCode $uri');
    if (body != null) debugPrint('[API] response=${_maskObject(body)}');
  }

  void error(Uri uri, Object error) {
    if (!kDebugMode) return;
    debugPrint('[API] error $uri: $error');
  }

  Map<String, String> _masked(Map<String, String> headers) {
    return headers.map((key, value) {
      final lower = key.toLowerCase();
      if (lower == 'authorization' || lower.contains('token')) {
        return MapEntry(key, '***');
      }
      return MapEntry(key, value);
    });
  }

  Object _maskObject(Object value) {
    if (value is Map) {
      return value.map((key, item) {
        final lower = key.toString().toLowerCase();
        if (lower.contains('password') ||
            lower.contains('token') ||
            lower.contains('authorization') ||
            lower.contains('payment') ||
            lower == 'body' ||
            lower == 'message') {
          return MapEntry(key, '***');
        }
        return MapEntry(key, item);
      });
    }
    return value;
  }
}

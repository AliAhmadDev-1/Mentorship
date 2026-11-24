enum ApiExceptionType {
  noInternet,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  badRequest,
  conflict,
  cancelled,
  parseError,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.type,
    this.statusCode,
    this.fieldErrors = const {},
    this.rawData,
  });

  final String message;
  final int? statusCode;
  final ApiExceptionType type;
  final Map<String, List<String>> fieldErrors;
  final Object? rawData;

  String? get code {
    final data = rawData;
    if (data is Map) return data['code']?.toString();
    return null;
  }

  bool get isAuthFailure => type == ApiExceptionType.unauthorized;

  bool get isRetryable =>
      type == ApiExceptionType.noInternet ||
      type == ApiExceptionType.timeout ||
      statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 504;

  @override
  String toString() =>
      'ApiException(type: $type, statusCode: $statusCode, message: $message)';
}

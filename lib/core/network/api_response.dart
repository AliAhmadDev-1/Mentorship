import 'api_exception.dart';

class ApiResponse<T> {
  const ApiResponse.success(this.data, {this.message, this.headers = const {}})
    : success = true,
      error = null;

  const ApiResponse.failure(this.error)
    : success = false,
      data = null,
      message = null,
      headers = const {};

  final bool success;
  final T? data;
  final String? message;
  final ApiException? error;
  final Map<String, String> headers;

  String? get etag => headers['etag'];
}

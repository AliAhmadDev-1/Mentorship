import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'error_handler.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'network_info.dart';

class JsonRequestBody {
  const JsonRequestBody(this.value);

  final Map<String, dynamic> value;
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenStorage? tokenStorage,
    NetworkInfo? networkInfo,
    LoggingInterceptor? loggingInterceptor,
    String baseUrl = ApiEndpoints.defaultBaseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _networkInfo = networkInfo ?? NetworkInfo(),
       _loggingInterceptor = loggingInterceptor ?? const LoggingInterceptor(),
       _baseUri = Uri.parse(baseUrl) {
    _authInterceptor = AuthInterceptor(_tokenStorage);
  }

  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);
  static const sendTimeout = Duration(seconds: 30);

  final http.Client _httpClient;
  final TokenStorage _tokenStorage;
  final NetworkInfo _networkInfo;
  final LoggingInterceptor _loggingInterceptor;
  final Uri _baseUri;
  late final AuthInterceptor _authInterceptor;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Object? json)? decoder,
    bool authorized = true,
    Map<String, String> headers = const {},
  }) {
    return request<T>(
      'GET',
      path,
      queryParameters: queryParameters,
      decoder: decoder,
      authorized: authorized,
      safeRetryCount: 1,
      extraHeaders: headers,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    T Function(Object? json)? decoder,
    bool authorized = true,
    Map<String, String> headers = const {},
  }) {
    return request<T>(
      'POST',
      path,
      body: body,
      queryParameters: queryParameters,
      decoder: decoder,
      authorized: authorized,
      extraHeaders: headers,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    T Function(Object? json)? decoder,
    bool authorized = true,
    Map<String, String> headers = const {},
  }) {
    return request<T>(
      'PUT',
      path,
      body: body,
      queryParameters: queryParameters,
      decoder: decoder,
      authorized: authorized,
      extraHeaders: headers,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    T Function(Object? json)? decoder,
    bool authorized = true,
    Map<String, String> headers = const {},
  }) {
    return request<T>(
      'PATCH',
      path,
      body: body,
      queryParameters: queryParameters,
      decoder: decoder,
      authorized: authorized,
      extraHeaders: headers,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Object? json)? decoder,
    bool authorized = true,
    Map<String, String> headers = const {},
  }) {
    return request<T>(
      'DELETE',
      path,
      queryParameters: queryParameters,
      decoder: decoder,
      authorized: authorized,
      extraHeaders: headers,
    );
  }

  Future<ApiResponse<T>> request<T>(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    T Function(Object? json)? decoder,
    bool authorized = true,
    int safeRetryCount = 0,
    Map<String, String> extraHeaders = const {},
  }) async {
    if (!await _networkInfo.isConnected) {
      return const ApiResponse.failure(
        ApiException(
          message: ErrorHandler.noInternetMessage,
          type: ApiExceptionType.noInternet,
        ),
      );
    }

    final uri = _resolve(path, queryParameters);
    final useMultipart = _usesMultipart(method, body);
    final requestBody = _requestBody(body);
    var didRefreshToken = false;
    var authHeaders = await _authInterceptor.authHeaders(
      authorized: authorized,
    );
    if (authorized && !authHeaders.containsKey('Authorization')) {
      didRefreshToken = await _refreshAccessToken();
      authHeaders = await _authInterceptor.authHeaders(authorized: authorized);
    }
    if (authorized && !authHeaders.containsKey('Authorization')) {
      await _authInterceptor.handleUnauthorized();
      return const ApiResponse.failure(
        ApiException(
          message: ErrorHandler.unauthorizedMessage,
          type: ApiExceptionType.unauthorized,
          statusCode: 401,
        ),
      );
    }
    var headers = _headers(
      body: requestBody,
      useMultipart: useMultipart,
      authHeaders: authHeaders,
      extraHeaders: extraHeaders,
    );
    final encodedBody = requestBody == null || useMultipart
        ? null
        : jsonEncode(requestBody);

    var attempt = 0;
    while (attempt <= safeRetryCount) {
      try {
        _loggingInterceptor.request(method, uri, headers, requestBody);
        final response = await _send(
          method,
          uri,
          headers,
          encodedBody,
          multipartBody: useMultipart ? body : null,
        ).timeout(_timeoutFor(method));
        final decoded = _tryDecode(response.body);
        _loggingInterceptor.response(response.statusCode, uri, decoded);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final parsed = decoder == null ? decoded as T? : decoder(decoded);
          final message = ErrorHandler.parseBackendError(decoded).message;
          return ApiResponse.success(
            parsed,
            message: message,
            headers: response.headers,
          );
        }

        final exception = ErrorHandler.fromResponse(response);
        if (authorized && exception.isAuthFailure) {
          if (!didRefreshToken && await _refreshAccessToken()) {
            didRefreshToken = true;
            authHeaders = await _authInterceptor.authHeaders(
              authorized: authorized,
            );
            headers = _headers(
              body: requestBody,
              useMultipart: useMultipart,
              authHeaders: authHeaders,
              extraHeaders: extraHeaders,
            );
            continue;
          }
          await _authInterceptor.handleUnauthorized();
        }
        if (_shouldRetry(method, exception, attempt, safeRetryCount)) {
          attempt++;
          continue;
        }
        return ApiResponse.failure(exception);
      } catch (error, stackTrace) {
        final exception = ErrorHandler.fromObject(error, stackTrace);
        _loggingInterceptor.error(uri, exception);
        if (_shouldRetry(method, exception, attempt, safeRetryCount)) {
          attempt++;
          continue;
        }
        return ApiResponse.failure(exception);
      }
    }

    return const ApiResponse.failure(
      ApiException(
        message: ErrorHandler.unknownMessage,
        type: ApiExceptionType.unknown,
      ),
    );
  }

  Map<String, String> _headers({
    required Object? body,
    required bool useMultipart,
    required Map<String, String> authHeaders,
    Map<String, String> extraHeaders = const {},
  }) {
    return {
      'Accept': 'application/json',
      if (body != null && !useMultipart) 'Content-Type': 'application/json',
      ...authHeaders,
      ...extraHeaders,
    };
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final uri = _resolve(ApiEndpoints.tokenRefresh, null);
      const headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      _loggingInterceptor.request('POST', uri, headers, {
        'refresh_token': '***',
      });
      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(sendTimeout);
      final decoded = _tryDecode(response.body);
      _loggingInterceptor.response(response.statusCode, uri, decoded);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      if (decoded is! Map) return false;
      final accessToken =
          decoded['access_token'] ?? decoded['access'] ?? decoded['token'];
      final tokenText = accessToken?.toString() ?? '';
      if (tokenText.isEmpty) return false;
      await _tokenStorage.saveAccessToken(tokenText);
      final rotatedRefreshToken =
          decoded['refresh_token'] ?? decoded['refresh'];
      final refreshText = rotatedRefreshToken?.toString() ?? '';
      if (refreshText.isNotEmpty) {
        await _tokenStorage.saveRefreshToken(refreshText);
      }
      return true;
    } catch (error, stackTrace) {
      final uri = _resolve(ApiEndpoints.tokenRefresh, null);
      _loggingInterceptor.error(
        uri,
        ErrorHandler.fromObject(error, stackTrace),
      );
      return false;
    }
  }

  Future<ApiResponse<void>> uploadBytes(
    String url,
    List<int> bytes, {
    Map<String, String> headers = const {},
  }) async {
    if (!await _networkInfo.isConnected) {
      return const ApiResponse.failure(
        ApiException(
          message: ErrorHandler.noInternetMessage,
          type: ApiExceptionType.noInternet,
        ),
      );
    }
    final uri = Uri.parse(url);
    try {
      final request = http.Request('PUT', uri)
        ..headers.addAll(headers)
        ..bodyBytes = bytes;
      final response = await http.Response.fromStream(
        await _httpClient.send(request),
      ).timeout(sendTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(null, headers: response.headers);
      }
      return ApiResponse.failure(ErrorHandler.fromResponse(response));
    } catch (error, stackTrace) {
      return ApiResponse.failure(ErrorHandler.fromObject(error, stackTrace));
    }
  }

  Uri _resolve(String path, Map<String, dynamic>? queryParameters) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path
        : '${_baseUri.path}/';
    final uri = _baseUri.replace(path: '$basePath$normalizedPath');
    final query = <String, String>{};
    queryParameters?.forEach((key, value) {
      if (value != null) query[key] = value.toString();
    });
    return query.isEmpty ? uri : uri.replace(queryParameters: query);
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body, {
    Object? multipartBody,
  }) async {
    if (multipartBody != null) {
      final request = http.MultipartRequest(method, uri)
        ..headers.addAll(headers)
        ..fields.addAll(_formFields(multipartBody));
      return http.Response.fromStream(await _httpClient.send(request));
    }

    return switch (method) {
      'GET' => await _httpClient.get(uri, headers: headers),
      'POST' => await _httpClient.post(uri, headers: headers, body: body),
      'PUT' => await _httpClient.put(uri, headers: headers, body: body),
      'PATCH' => await _httpClient.patch(uri, headers: headers, body: body),
      'DELETE' => await _httpClient.delete(uri, headers: headers),
      _ => throw ArgumentError('Unsupported HTTP method: $method'),
    };
  }

  Duration _timeoutFor(String method) {
    if (method == 'GET') return receiveTimeout;
    if (method == 'POST' ||
        method == 'PUT' ||
        method == 'PATCH' ||
        method == 'DELETE') {
      return sendTimeout;
    }
    return connectTimeout;
  }

  bool _shouldRetry(
    String method,
    ApiException exception,
    int attempt,
    int safeRetryCount,
  ) {
    return method == 'GET' && exception.isRetryable && attempt < safeRetryCount;
  }

  Object? _tryDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  bool _usesMultipart(String method, Object? body) {
    return body != null &&
        body is Map &&
        (method == 'POST' || method == 'PUT' || method == 'PATCH');
  }

  Object? _requestBody(Object? body) {
    if (body is JsonRequestBody) return body.value;
    return body;
  }

  Map<String, String> _formFields(Object body) {
    if (body is! Map) return const {};
    final fields = <String, String>{};
    body.forEach((key, value) {
      if (value == null) return;
      fields[key.toString()] = _formValue(value);
    });
    return fields;
  }

  String _formValue(Object? value) {
    if (value == null) return '';
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is Iterable) {
      return value.map((item) => _formValue(item)).join(',');
    }
    return value.toString();
  }
}

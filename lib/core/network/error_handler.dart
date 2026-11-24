import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ErrorHandler {
  const ErrorHandler._();

  static const noInternetMessage =
      'No internet connection. Please check your connection and try again.';
  static const serverUnreachableMessage =
      'Cannot reach the API server. Check the base URL and make sure the backend is running.';
  static const timeoutMessage = 'Request timed out. Please try again.';
  static const unauthorizedMessage =
      'Your session has expired. Please login again.';
  static const forbiddenMessage =
      'You do not have permission to perform this action.';
  static const notFoundMessage = 'Requested data was not found.';
  static const conflictMessage =
      'This action conflicts with existing data. Please refresh and try again.';
  static const tooManyRequestsMessage =
      'Too many requests. Please wait and try again.';
  static const serverMessage = 'Server error. Please try again later.';
  static const serviceUnavailableMessage =
      'Service is temporarily unavailable. Please try again later.';
  static const unknownMessage = 'Something went wrong. Please try again.';
  static const browserBlockedMessage =
      'Browser blocked the API request. Please check the API CORS settings.';
  static const invalidFormatMessage = 'Invalid response format.';

  static ApiException fromResponse(http.Response response) {
    final raw = _decode(response.body);
    final parsed = parseBackendError(raw);
    final status = response.statusCode;

    return switch (status) {
      400 => ApiException(
        message: parsed.message ?? 'Bad request.',
        type: ApiExceptionType.badRequest,
        statusCode: status,
        fieldErrors: parsed.fieldErrors,
        rawData: raw,
      ),
      401 => ApiException(
        message: parsed.message ?? unauthorizedMessage,
        type: ApiExceptionType.unauthorized,
        statusCode: status,
        fieldErrors: parsed.fieldErrors,
        rawData: raw,
      ),
      403 => ApiException(
        message: parsed.message ?? forbiddenMessage,
        type: ApiExceptionType.forbidden,
        statusCode: status,
        fieldErrors: parsed.fieldErrors,
        rawData: raw,
      ),
      404 => ApiException(
        message: parsed.message ?? notFoundMessage,
        type: ApiExceptionType.notFound,
        statusCode: status,
        fieldErrors: parsed.fieldErrors,
        rawData: raw,
      ),
      409 => ApiException(
        message: parsed.message ?? conflictMessage,
        type: ApiExceptionType.conflict,
        statusCode: status,
        fieldErrors: parsed.fieldErrors,
        rawData: raw,
      ),
      413 => ApiException(
        message: parsed.message ?? 'The selected file is too large.',
        type: ApiExceptionType.validation,
        statusCode: status,
        fieldErrors: parsed.fieldErrors,
        rawData: raw,
      ),
      415 => ApiException(
        message: parsed.message ?? 'This file type is not supported.',
        type: ApiExceptionType.validation,
        statusCode: status,
        fieldErrors: parsed.fieldErrors,
        rawData: raw,
      ),
      422 => ApiException(
        message: parsed.message ?? 'Validation failed.',
        type: ApiExceptionType.validation,
        statusCode: status,
        fieldErrors: parsed.fieldErrors,
        rawData: raw,
      ),
      429 => ApiException(
        message: parsed.message ?? tooManyRequestsMessage,
        type: ApiExceptionType.server,
        statusCode: status,
        fieldErrors: parsed.fieldErrors,
        rawData: raw,
      ),
      >= 500 && <= 504 => ApiException(
        message:
            parsed.message ??
            (status == 500 ? serverMessage : serviceUnavailableMessage),
        type: ApiExceptionType.server,
        statusCode: status,
        fieldErrors: parsed.fieldErrors,
        rawData: raw,
      ),
      _ => ApiException(
        message: parsed.message ?? unknownMessage,
        type: ApiExceptionType.unknown,
        statusCode: status,
        fieldErrors: parsed.fieldErrors,
        rawData: raw,
      ),
    };
  }

  static ApiException fromObject(Object error, [StackTrace? stackTrace]) {
    if (error is ApiException) return error;
    if (error is TimeoutException) {
      return const ApiException(
        message: timeoutMessage,
        type: ApiExceptionType.timeout,
      );
    }
    if (error is FormatException) {
      return ApiException(
        message: invalidFormatMessage,
        type: ApiExceptionType.parseError,
        rawData: error.message,
      );
    }
    if (error is http.ClientException) {
      final message = error.message.toLowerCase();
      if (message.contains('xmlhttprequest') || message.contains('cors')) {
        return ApiException(
          message: browserBlockedMessage,
          type: ApiExceptionType.unknown,
          rawData: error,
        );
      }
      if (message.contains('socket') ||
          message.contains('connection') ||
          message.contains('dns') ||
          message.contains('host')) {
        return ApiException(
          message: serverUnreachableMessage,
          type: ApiExceptionType.server,
          rawData: error,
        );
      }
    }
    return ApiException(
      message: unknownMessage,
      type: ApiExceptionType.unknown,
      rawData: error,
    );
  }

  static ParsedBackendError parseBackendError(Object? raw) {
    final fieldErrors = <String, List<String>>{};
    String? message;

    void collectField(String key, Object? value) {
      final list = _stringList(value);
      if (list.isNotEmpty) fieldErrors[key] = list;
    }

    if (raw is Map) {
      for (final key in const ['message', 'detail', 'error']) {
        final value = raw[key];
        if (value is String && value.trim().isNotEmpty) {
          message ??= value.trim();
        }
      }

      final nonField = _stringList(raw['non_field_errors']);
      if (nonField.isNotEmpty) {
        fieldErrors['non_field_errors'] = nonField;
        message ??= nonField.join('\n');
      }

      final errors = raw['errors'];
      if (errors is Map) {
        errors.forEach((key, value) => collectField(key.toString(), value));
      } else if (errors is List || errors is String) {
        final list = _stringList(errors);
        if (list.isNotEmpty) {
          fieldErrors['errors'] = list;
          message ??= list.join('\n');
        }
      }

      raw.forEach((key, value) {
        final field = key.toString();
        if (_reservedErrorKeys.contains(field)) return;
        if (value is List) {
          collectField(field, value);
        }
      });
    } else if (raw is String && raw.trim().isNotEmpty) {
      message = raw.trim();
    }

    if (message == null && fieldErrors.isNotEmpty) {
      message = fieldErrors.values.expand((items) => items).join('\n');
    }

    return ParsedBackendError(message: message, fieldErrors: fieldErrors);
  }

  static Object? _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  static List<String> _stringList(Object? value) {
    if (value == null) return const [];
    if (value is String) return value.trim().isEmpty ? const [] : [value];
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return [value.toString()];
  }
}

const _reservedErrorKeys = {
  'message',
  'detail',
  'error',
  'errors',
  'non_field_errors',
};

class ParsedBackendError {
  const ParsedBackendError({this.message, this.fieldErrors = const {}});

  final String? message;
  final Map<String, List<String>> fieldErrors;
}

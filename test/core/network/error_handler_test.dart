import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:mentorship/core/network/error_handler.dart';

void main() {
  group('ErrorHandler.fromResponse', () {
    test('preserves machine-readable error codes', () {
      final exception = ErrorHandler.fromResponse(
        http.Response(
          '{"code":"mentor_not_available","detail":"Unavailable"}',
          403,
        ),
      );

      expect(exception.code, 'mentor_not_available');
      expect(exception.isAuthFailure, false);
    });
    test('uses backend message for unauthorized responses', () {
      final exception = ErrorHandler.fromResponse(
        http.Response('{"detail":"Invalid credentials"}', 401),
      );

      expect(exception.message, 'Invalid credentials');
      expect(exception.statusCode, 401);
    });

    test(
      'falls back to session expired copy for unauthorized without message',
      () {
        final exception = ErrorHandler.fromResponse(http.Response('', 401));

        expect(exception.message, ErrorHandler.unauthorizedMessage);
        expect(exception.statusCode, 401);
      },
    );

    test('uses backend message for server errors when provided', () {
      final exception = ErrorHandler.fromResponse(
        http.Response('{"message":"Payment provider unavailable"}', 500),
      );

      expect(exception.message, 'Payment provider unavailable');
      expect(exception.statusCode, 500);
    });
  });

  group('ErrorHandler.parseBackendError', () {
    test('extracts message variants', () {
      expect(
        ErrorHandler.parseBackendError({
          'message': 'Invalid credentials',
        }).message,
        'Invalid credentials',
      );
      expect(
        ErrorHandler.parseBackendError({
          'detail': 'Authentication credentials were not provided.',
        }).message,
        'Authentication credentials were not provided.',
      );
      expect(
        ErrorHandler.parseBackendError({
          'error': 'Something went wrong',
        }).message,
        'Something went wrong',
      );
    });

    test('extracts field and non-field errors', () {
      final parsed = ErrorHandler.parseBackendError({
        'errors': {
          'email': ['This field is required.'],
          'password': ['Password is too short.'],
        },
        'non_field_errors': ['Invalid email or password.'],
      });

      expect(parsed.fieldErrors['email'], ['This field is required.']);
      expect(parsed.fieldErrors['password'], ['Password is too short.']);
      expect(parsed.fieldErrors['non_field_errors'], [
        'Invalid email or password.',
      ]);
      expect(parsed.message, 'Invalid email or password.');
    });

    test('extracts direct field errors', () {
      final parsed = ErrorHandler.parseBackendError({
        'email': ['Enter a valid email address.'],
        'password': ['This field is required.'],
      });

      expect(parsed.fieldErrors['email'], ['Enter a valid email address.']);
      expect(parsed.fieldErrors['password'], ['This field is required.']);
      expect(
        parsed.message,
        'Enter a valid email address.\nThis field is required.',
      );
    });
  });
}

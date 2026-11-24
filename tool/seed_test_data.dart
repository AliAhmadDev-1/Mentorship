import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _defaultBaseUrl =
    'http://micro-mentor-alb-869670005.us-east-1.elb.amazonaws.com/api';
const _password = 'Password1';

Future<void> main(List<String> args) async {
  final options = _Options.fromArgs(args);
  final client = _SeedClient(baseUrl: options.baseUrl);

  _log('Seeding ${options.baseUrl}');
  _log('Using email suffix "${options.suffix}"');
  final slugSuffix = _slug(options.suffix);

  final mentorSarah = await _ensureUser(
    client,
    email: 'sarah.chen+${options.suffix}@micromentor.test',
    firstName: 'Sarah',
    lastName: 'Chen',
    role: 'mentor',
    headline: 'Senior Flutter Engineer at Google',
    bio:
        'Sarah helps mobile engineers master Flutter architecture, scalable state management, and production-ready app delivery.',
    company: 'Google',
    yearsExperience: 8,
  );
  await client.setAccessTokenFor(email: mentorSarah.email, password: _password);

  final categories = await _createNamedResources(client, '/categories/', [
    {
      'key': 'Flutter',
      'name': 'Flutter $slugSuffix',
      'slug': 'seed-flutter-$slugSuffix',
    },
    {
      'key': 'AI/ML',
      'name': 'AI/ML $slugSuffix',
      'slug': 'seed-ai-ml-$slugSuffix',
    },
    {
      'key': 'Startups',
      'name': 'Startups $slugSuffix',
      'slug': 'seed-startups-$slugSuffix',
    },
    {
      'key': 'Product Design',
      'name': 'Product Design $slugSuffix',
      'slug': 'seed-product-design-$slugSuffix',
    },
  ]);
  final expertise = await _createNamedResources(client, '/expertise/', [
    {
      'key': 'Dart',
      'name': 'Dart $slugSuffix',
      'slug': 'seed-dart-$slugSuffix',
    },
    {
      'key': 'Riverpod',
      'name': 'Riverpod $slugSuffix',
      'slug': 'seed-riverpod-$slugSuffix',
    },
    {
      'key': 'Django',
      'name': 'Django $slugSuffix',
      'slug': 'seed-django-$slugSuffix',
    },
    {
      'key': 'Fundraising',
      'name': 'Fundraising $slugSuffix',
      'slug': 'seed-fundraising-$slugSuffix',
    },
    {
      'key': 'Design Systems',
      'name': 'Design Systems $slugSuffix',
      'slug': 'seed-design-systems-$slugSuffix',
    },
  ]);

  final sarahMentorProfileId = await _configureMentorProfile(
    client,
    profileId: mentorSarah.mentorProfileId,
    headline: 'Senior Flutter Engineer at Google',
    bio:
        'Sarah helps mobile engineers master Flutter architecture, scalable state management, and production-ready app delivery.',
    company: 'Google',
    categoryIds: [categories['Flutter'], categories['AI/ML']],
    expertiseIds: [expertise['Dart'], expertise['Riverpod']],
  );
  final sarahPackageId = await _createPackage(
    client,
    mentorId: sarahMentorProfileId,
    title: 'Flutter architecture review',
    description: 'A focused session for app structure, routing, and Riverpod.',
    durationMinutes: 30,
    priceUsd: 25,
    isPopular: true,
  );
  await _createAvailability(client);

  final mentorOmar = await _ensureUser(
    client,
    email: 'omar.hassan+${options.suffix}@micromentor.test',
    firstName: 'Omar',
    lastName: 'Hassan',
    role: 'mentor',
    headline: 'Backend Architect at Stripe',
    bio:
        'Omar helps developers design scalable backend systems, payment infrastructure, APIs, and production databases.',
    company: 'Stripe',
    yearsExperience: 10,
    categoryIds: [categories['Startups'], categories['AI/ML']],
    expertiseIds: [expertise['Django'], expertise['Fundraising']],
  );
  await client.setAccessTokenFor(email: mentorOmar.email, password: _password);
  final omarMentorProfileId = await _configureMentorProfile(
    client,
    profileId: mentorOmar.mentorProfileId,
    headline: 'Backend Architect at Stripe',
    bio:
        'Omar helps developers design scalable backend systems, payment infrastructure, APIs, and production databases.',
    company: 'Stripe',
    categoryIds: [categories['Startups'], categories['AI/ML']],
    expertiseIds: [expertise['Django'], expertise['Fundraising']],
  );
  await _createPackage(
    client,
    mentorId: omarMentorProfileId,
    title: 'Backend system design coaching',
    description: 'Practical feedback on APIs, payments, and database design.',
    durationMinutes: 45,
    priceUsd: 40,
  );
  await _createAvailability(client);

  final mentee = await _ensureUser(
    client,
    email: 'alex.morgan+${options.suffix}@micromentor.test',
    firstName: 'Alex',
    lastName: 'Morgan',
    role: 'mentee',
  );
  await client.setAccessTokenFor(email: mentee.email, password: _password);
  final sessionId = sarahPackageId == null
      ? null
      : await _createBooking(client, sarahPackageId);
  if (sessionId != null) {
    await _createSessionReview(client, sessionId);
  }
  await _tryCreateConversation(client, sarahMentorProfileId, sessionId);

  _log('Done.');
  _log('Mentor login: ${mentorSarah.email} / $_password');
  _log('Mentor login: ${mentorOmar.email} / $_password');
  _log('Mentee login: ${mentee.email} / $_password');
}

Future<Map<String, int>> _createNamedResources(
  _SeedClient client,
  String path,
  List<Map<String, Object?>> resources,
) async {
  final ids = <String, int>{};
  for (final resource in resources) {
    final name = resource['name']!.toString();
    final key = resource['key']?.toString() ?? name;
    final body = {...resource}..remove('key');
    final response = await client.postJson(path, body, failFast: false);
    final id = _idFrom(response);
    if (id == null) {
      final existing = await client.getJson(path, failFast: false);
      final existingId = _findId(
        existing.json,
        field: 'slug',
        value: body['slug']?.toString() ?? '',
      );
      if (existingId != null) {
        ids[key] = existingId;
        _log('Using existing $path $name (#$existingId)');
        continue;
      }
      _log(
        'Skipped $path $name: HTTP ${response.statusCode} '
        '${jsonEncode(response.json)}',
      );
      continue;
    }
    ids[key] = id;
    _log('Created $path $name (#$id)');
  }
  return ids;
}

String _slug(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : slug;
}

Future<_SeedUser> _ensureUser(
  _SeedClient client, {
  required String email,
  required String firstName,
  required String lastName,
  required String role,
  String? headline,
  String? bio,
  String? company,
  int? yearsExperience,
  List<int?> categoryIds = const [],
  List<int?> expertiseIds = const [],
}) async {
  final response = await client.postForm(
    '/auth/register/',
    {
      'email': email,
      'password': _password,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      if (headline != null) 'headline': headline,
      if (bio != null) 'bio': bio,
      if (company != null) 'company': company,
      if (yearsExperience != null) 'years_experience': yearsExperience,
      if (categoryIds.whereType<int>().isNotEmpty)
        'category_ids': categoryIds.whereType<int>().join(','),
      if (expertiseIds.whereType<int>().isNotEmpty)
        'expertise_ids': expertiseIds.whereType<int>().join(','),
    },
    authorized: false,
    failFast: false,
  );

  if (response.statusCode >= 200 && response.statusCode < 300) {
    final data = _dataOrSelf(response.json);
    final id = _int(data['id']);
    if (id != null) {
      _log('Registered $role $email (#$id)');
      return _SeedUser(
        id: id,
        email: email,
        mentorProfileId: _int(data['mentor_profile_id']),
      );
    }
  }

  _log(
    'Registration for $email returned HTTP ${response.statusCode}: '
    '${jsonEncode(response.json)}',
  );

  final login = await client.postJson('/auth/login/', {
    'email': email,
    'password': _password,
  }, authorized: false);
  final data = _dataOrSelf(login.json);
  final id = _int(data['id']);
  if (id == null) {
    throw StateError('Could not determine user id for $email.');
  }
  _log('Using existing $role $email (#$id)');
  return _SeedUser(id: id, email: email);
}

Future<int?> _configureMentorProfile(
  _SeedClient client, {
  required int? profileId,
  required String headline,
  required String bio,
  required String company,
  required List<int?> categoryIds,
  required List<int?> expertiseIds,
}) async {
  var resolvedProfileId = profileId;
  if (resolvedProfileId == null) {
    final existing = await client.getJson('/mentor-profiles/');
    resolvedProfileId = _findId(
      existing.json,
      field: 'headline',
      value: headline,
    );
  }
  if (resolvedProfileId == null) {
    _log('Could not resolve mentor profile for "$headline"');
    return null;
  }

  final response = await client
      .patchJson('/mentor-profiles/$resolvedProfileId/', {
        'headline': headline,
        'bio': bio,
        'company': company,
        'years_experience': 8,
        'category_ids': categoryIds.whereType<int>().toList(),
        'expertise_ids': expertiseIds.whereType<int>().toList(),
        'auto_confirm_bookings': true,
        'is_active': true,
      }, failFast: false);
  _logResponse('Configured mentor profile', response);
  return resolvedProfileId;
}

Future<int?> _createPackage(
  _SeedClient client, {
  required int? mentorId,
  required String title,
  required String description,
  required int durationMinutes,
  required int priceUsd,
  bool isPopular = false,
}) async {
  final response = await client.postJson('/packages/', {
    if (mentorId != null) 'mentor_id': mentorId,
    'title': title,
    'description': description,
    'duration_minutes': durationMinutes,
    'price_usd': priceUsd,
    'is_popular': isPopular,
    'is_active': true,
  }, failFast: false);
  final id = _idFrom(response);
  if (id == null) {
    final existing = await client.getJson('/packages/');
    final existingId = _findPackageId(
      existing.json,
      mentorId: mentorId,
      durationMinutes: durationMinutes,
      priceUsd: priceUsd,
    );
    if (existingId != null) {
      _log('Using existing package "$title" (#$existingId)');
      return existingId;
    }
    _log(
      'Skipped package "$title": HTTP ${response.statusCode} '
      '${jsonEncode(response.json)}',
    );
    return null;
  }
  _log('Created package "$title" (#$id)');
  return id;
}

Future<void> _createAvailability(_SeedClient client) async {
  for (final weekday in [1, 3, 5]) {
    final response = await client.postJson('/availability-windows/', {
      'weekday': weekday,
      'starts_at': '09:00',
      'ends_at': '17:00',
      'timezone': 'UTC',
      'slot_interval_minutes': 30,
      'is_active': true,
    }, failFast: false);
    _logResponse('Created availability weekday $weekday', response);
  }
}

Future<int?> _createBooking(_SeedClient client, int packageId) async {
  final response = await client.postJson('/bookings/', {
    'package_id': packageId,
    'starts_at': DateTime.now()
        .toUtc()
        .add(const Duration(days: 2, hours: 3))
        .toIso8601String(),
    'goals': 'Review Flutter architecture choices.',
    'topic': 'State management and routing',
  }, failFast: false);

  final data = _dataOrSelf(response.json);
  final sessionId = _int(data['session_id'] ?? data['id']);
  _logResponse('Created booking', response);
  return sessionId;
}

Future<void> _createSessionReview(_SeedClient client, int sessionId) async {
  final payment = await client.postJson(
    '/sessions/$sessionId/payment/confirm/',
    {'provider_payment_id': 'seed-payment-$sessionId'},
    failFast: false,
  );
  _logResponse('Confirmed payment for session $sessionId', payment);

  final complete = await client.postJson(
    '/sessions/$sessionId/complete/',
    const {},
    failFast: false,
  );
  _logResponse('Completed session $sessionId', complete);

  final review = await client.postJson('/sessions/$sessionId/review/', {
    'rating': 5,
    'body': 'Excellent test mentor experience.',
  }, failFast: false);
  _logResponse('Created session review', review);
}

Future<void> _tryCreateConversation(
  _SeedClient client,
  int? mentorId,
  int? sessionId,
) async {
  final response = await client.postJson('/conversations/', {
    if (mentorId != null) 'mentor_id': mentorId,
    if (sessionId != null) 'session_id': sessionId,
    'type': sessionId == null ? 'inquiry' : 'session',
  }, failFast: false);
  _logResponse('Created conversation', response);

  final conversationId = _idFrom(response);
  if (conversationId == null) return;
  await client.postJson('/conversations/$conversationId/messages/', {
    'body': 'Hi Sarah, I added a test booking and want to prep questions.',
  }, failFast: false);
}

int? _idFrom(_SeedResponse response) {
  final data = _dataOrSelf(response.json);
  return _int(
    data['id'] ??
        data['mentor_id'] ??
        data['package_id'] ??
        data['review_id'] ??
        data['message_id'],
  );
}

int? _findId(
  Object? responseBody, {
  required String field,
  required String value,
}) {
  final root = responseBody is Map
      ? responseBody.map((key, item) => MapEntry(key.toString(), item))
      : const <String, dynamic>{};
  final items = root['results'] is List
      ? root['results'] as List
      : responseBody is List
      ? responseBody
      : const [];
  for (final item in items) {
    if (item is Map && item[field]?.toString() == value) {
      return _int(item['id']);
    }
  }
  return null;
}

int? _findPackageId(
  Object? responseBody, {
  required int? mentorId,
  required int durationMinutes,
  required int priceUsd,
}) {
  final root = responseBody is Map
      ? responseBody.map((key, item) => MapEntry(key.toString(), item))
      : const <String, dynamic>{};
  final items = root['results'] is List ? root['results'] as List : const [];
  for (final item in items) {
    if (item is! Map) continue;
    final itemPrice = double.tryParse(item['price_usd']?.toString() ?? '');
    if (_int(item['mentor_id']) == mentorId &&
        _int(item['duration_minutes']) == durationMinutes &&
        itemPrice == priceUsd.toDouble()) {
      return _int(item['id']);
    }
  }
  return null;
}

void _logResponse(String label, _SeedResponse response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    _log('$label.');
    return;
  }
  _log(
    '$label skipped: HTTP ${response.statusCode} '
    '${jsonEncode(response.json)}',
  );
}

Map<String, dynamic> _dataOrSelf(Object? value) {
  if (value is Map) {
    final map = value.map((key, item) => MapEntry(key.toString(), item));
    final data = map['data'];
    if (data is Map) {
      return data.map((key, item) => MapEntry(key.toString(), item));
    }
    return map;
  }
  return const {};
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

void _log(String message) => stdout.writeln(message);

class _SeedClient {
  _SeedClient({required String baseUrl})
    : _baseUri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');

  final Uri _baseUri;
  String? _accessToken;

  Future<void> setAccessTokenFor({
    required String email,
    required String password,
  }) async {
    final response = await postJson('/auth/login/', {
      'email': email,
      'password': password,
    }, authorized: false);
    final data = _dataOrSelf(response.json);
    _accessToken =
        data['access_token']?.toString() ??
        data['access']?.toString() ??
        data['token']?.toString();
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw StateError('Login for $email did not return an access token.');
    }
  }

  Future<_SeedResponse> postJson(
    String path,
    Map<String, Object?> fields, {
    bool authorized = true,
    bool failFast = true,
  }) async {
    final response = await http.post(
      _resolve(path),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (authorized && _accessToken != null)
          'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode(fields),
    );
    final result = _SeedResponse(response.statusCode, _decode(response.body));
    if (failFast && (response.statusCode < 200 || response.statusCode >= 300)) {
      throw HttpException(
        'POST $path failed with HTTP ${response.statusCode}: ${response.body}',
        uri: _resolve(path),
      );
    }
    return result;
  }

  Future<_SeedResponse> postForm(
    String path,
    Map<String, Object?> fields, {
    bool authorized = true,
    bool failFast = true,
  }) async {
    final request = http.MultipartRequest('POST', _resolve(path))
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(
        fields.map((key, value) => MapEntry(key, value.toString())),
      );
    if (authorized && _accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final result = _SeedResponse(response.statusCode, _decode(response.body));
    if (failFast && (response.statusCode < 200 || response.statusCode >= 300)) {
      throw HttpException(
        'POST $path failed with HTTP ${response.statusCode}: ${response.body}',
        uri: _resolve(path),
      );
    }
    return result;
  }

  Future<_SeedResponse> getJson(
    String path, {
    bool authorized = true,
    bool failFast = true,
  }) async {
    final response = await http.get(
      _resolve(path),
      headers: {
        'Accept': 'application/json',
        if (authorized && _accessToken != null)
          'Authorization': 'Bearer $_accessToken',
      },
    );
    final result = _SeedResponse(response.statusCode, _decode(response.body));
    if (failFast && (response.statusCode < 200 || response.statusCode >= 300)) {
      throw HttpException(
        'GET $path failed with HTTP ${response.statusCode}: ${response.body}',
        uri: _resolve(path),
      );
    }
    return result;
  }

  Future<_SeedResponse> patchJson(
    String path,
    Map<String, Object?> fields, {
    bool authorized = true,
    bool failFast = true,
  }) async {
    final response = await http.patch(
      _resolve(path),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (authorized && _accessToken != null)
          'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode(fields),
    );
    final result = _SeedResponse(response.statusCode, _decode(response.body));
    if (failFast && (response.statusCode < 200 || response.statusCode >= 300)) {
      throw HttpException(
        'PATCH $path failed with HTTP ${response.statusCode}: ${response.body}',
        uri: _resolve(path),
      );
    }
    return result;
  }

  Uri _resolve(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return _baseUri.replace(path: '${_baseUri.path}$normalizedPath');
  }

  Object? _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }
}

class _SeedResponse {
  const _SeedResponse(this.statusCode, this.json);

  final int statusCode;
  final Object? json;
}

class _SeedUser {
  const _SeedUser({
    required this.id,
    required this.email,
    this.mentorProfileId,
  });

  final int id;
  final String email;
  final int? mentorProfileId;
}

class _Options {
  const _Options({required this.baseUrl, required this.suffix});

  final String baseUrl;
  final String suffix;

  factory _Options.fromArgs(List<String> args) {
    var baseUrl = Platform.environment['API_BASE_URL'] ?? _defaultBaseUrl;
    var suffix =
        Platform.environment['SEED_SUFFIX'] ??
        DateTime.now().millisecondsSinceEpoch.toString();

    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--base-url':
          baseUrl = args[++i];
          break;
        case '--suffix':
          suffix = args[++i];
          break;
        case '--help':
        case '-h':
          stdout.writeln('''
Seed Micro-Mentor test data through the HTTP API.

Usage:
  dart run tool/seed_test_data.dart [--base-url URL] [--suffix TEXT]

Environment:
  API_BASE_URL   API root. Defaults to the app production URL.
  SEED_SUFFIX    Email suffix. Defaults to a timestamp.
''');
          exit(0);
      }
    }

    return _Options(baseUrl: baseUrl, suffix: suffix);
  }
}

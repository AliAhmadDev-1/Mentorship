import '../models/api_models.dart';
import '../models/mentor.dart';
import '../network/api_exception.dart';
import '../network/error_handler.dart';
import '../network/micro_mentor_api.dart';

class MentorRepository {
  MentorRepository({MicroMentorApi? api}) : _api = api ?? MicroMentorApi();

  final MicroMentorApi _api;

  Future<List<Mentor>> getFeaturedMentors() async {
    final response = await _api.home();
    if (!response.success) throw response.error!;
    final mentors = (response.data?.featuredMentors ?? const [])
        .map(_mentorFromListItem)
        .toList();
    return mentors;
  }

  Future<List<String>> getCategories() async {
    final response = await _api.listCategories();
    if (!response.success) throw response.error!;
    final categories =
        (response.data?.results ?? const [])
            .where((category) => category.isActive)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final names = categories
        .map((category) => category.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    return ['All', ...names];
  }

  Future<MentorPage> getMentors({
    String? query,
    String? category,
    int page = 1,
  }) async {
    final response = await _api.listMentors(
      q: query,
      category: category == null || category == 'All' ? null : category,
      page: page,
      pageSize: 20,
    );
    if (!response.success) throw response.error!;
    final data = response.data;
    if (data == null) {
      throw const ApiException(
        message: ErrorHandler.invalidFormatMessage,
        type: ApiExceptionType.parseError,
      );
    }
    return MentorPage(
      mentors: data.results.map(_mentorFromListItem).toList(),
      hasMore: data.hasNext ?? data.next != null,
    );
  }

  Future<Mentor> getMentorById(String id) async {
    final response = await _api.getMentor(id);
    if (!response.success) throw response.error!;
    final detail = response.data;
    if (detail == null) {
      throw const ApiException(
        message: ErrorHandler.invalidFormatMessage,
        type: ApiExceptionType.parseError,
      );
    }
    return _mentorFromDetail(detail);
  }

  Mentor _mentorFromListItem(MentorListItem item) {
    final name = item.name.trim().isEmpty ? 'Mentor' : item.name.trim();
    final title = item.headline.trim().isEmpty
        ? 'MicroMentor expert'
        : item.headline.trim();
    final package = _firstActivePackage(item.packages);
    final packages = _packagesFromResponses(item.packages);
    final startingPrice = package?.priceUsd ?? item.startingPrice;

    return Mentor(
      id: '${item.id}',
      name: name,
      title: title,
      company: _fallbackText(item.company, 'MicroMentor'),
      expertise: item.expertise.isEmpty
          ? _expertiseFromHeadline(title)
          : item.expertise,
      ratePerSlot: startingPrice,
      rating: item.rating ?? 0,
      reviewCount: item.reviewCount ?? 0,
      totalSessions: item.totalSessions ?? 0,
      yearsExperience: item.yearsExperience ?? 0,
      repeatRate: item.repeatRate ?? 0,
      verified: item.verified ?? false,
      bio: _fallbackText(item.bio, title),
      avatarInitials: _initials(name),
      avatarColorValue: _avatarColor(item.id, name),
      primaryPackageId: package == null ? null : '${package.id}',
      packages: packages,
    );
  }

  Mentor _mentorFromDetail(MentorDetailResponse detail) {
    final name = detail.name.trim().isEmpty ? 'Mentor' : detail.name.trim();
    final title = detail.headline.trim().isEmpty
        ? 'MicroMentor expert'
        : detail.headline.trim();
    final package = _firstActivePackage(detail.packages);
    final packages = _packagesFromResponses(detail.packages);

    return Mentor(
      id: '${detail.id}',
      name: name,
      title: title,
      company: 'MicroMentor',
      expertise: _expertiseFromHeadline(title),
      ratePerSlot: package?.priceUsd ?? 0,
      rating: 0,
      reviewCount: 0,
      totalSessions: 0,
      yearsExperience: 0,
      repeatRate: 0,
      verified: false,
      bio: detail.bio.trim().isEmpty ? title : detail.bio.trim(),
      avatarInitials: _initials(name),
      avatarColorValue: _avatarColor(detail.id, name),
      primaryPackageId: package == null ? null : '${package.id}',
      packages: packages,
    );
  }
}

class MentorPage {
  const MentorPage({required this.mentors, required this.hasMore});

  final List<Mentor> mentors;
  final bool hasMore;
}

PackageResponse? _firstActivePackage(List<PackageResponse> packages) {
  for (final package in packages) {
    if (package.isActive ?? true) return package;
  }
  return packages.isEmpty ? null : packages.first;
}

List<MentorPackage> _packagesFromResponses(List<PackageResponse> packages) {
  return packages
      .where((package) => package.isActive ?? true)
      .map(
        (package) => MentorPackage(
          id: '${package.id}',
          durationMinutes: package.durationMinutes ?? 15,
          priceUsd: package.priceUsd,
          isPopular: package.isPopular ?? false,
        ),
      )
      .toList();
}

List<String> _expertiseFromHeadline(String headline) {
  final words = headline
      .split(RegExp(r'[\s,/&+-]+'))
      .where((word) => word.trim().length > 2)
      .take(3)
      .toList();
  return words.isEmpty ? const ['Mentorship'] : words;
}

String _fallbackText(String? value, String fallback) {
  final text = value?.trim();
  return text == null || text.isEmpty ? fallback : text;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  final first = parts.first[0];
  final last = parts.length > 1 ? parts.last[0] : '';
  return '$first$last'.toUpperCase();
}

int _avatarColor(Object id, String name) {
  const palette = [
    0xFF53D6B4,
    0xFFF0BF63,
    0xFFDE7C6B,
    0xFF77A88B,
    0xFFD989A4,
    0xFF6FA7A0,
  ];
  final seed = id.hashCode ^ name.hashCode;
  return palette[seed.abs() % palette.length];
}

class Mentor {
  const Mentor({
    required this.id,
    required this.name,
    required this.title,
    required this.company,
    required this.expertise,
    required this.ratePerSlot,
    required this.rating,
    required this.reviewCount,
    required this.totalSessions,
    required this.yearsExperience,
    required this.repeatRate,
    required this.verified,
    required this.bio,
    required this.avatarInitials,
    required this.avatarColorValue,
    this.primaryPackageId,
    this.packages = const [],
  });

  final String id;
  final String name;
  final String title;
  final String company;
  final List<String> expertise;
  final double ratePerSlot;
  final double rating;
  final int reviewCount;
  final int totalSessions;
  final int yearsExperience;
  final int repeatRate;
  final bool verified;
  final String bio;
  final String avatarInitials;
  final int avatarColorValue;
  final String? primaryPackageId;
  final List<MentorPackage> packages;

  String get ratingLabel => rating.toStringAsFixed(1);

  MentorPackage? packageForDuration(int durationMinutes) {
    for (final package in packages) {
      if (package.durationMinutes == durationMinutes) return package;
    }
    if (primaryPackageId == null) {
      return packages.isEmpty ? null : packages.first;
    }
    for (final package in packages) {
      if (package.id == primaryPackageId) return package;
    }
    return packages.isEmpty ? null : packages.first;
  }
}

class MentorPackage {
  const MentorPackage({
    required this.id,
    required this.durationMinutes,
    required this.priceUsd,
    required this.isPopular,
  });

  final String id;
  final int durationMinutes;
  final double priceUsd;
  final bool isPopular;
}

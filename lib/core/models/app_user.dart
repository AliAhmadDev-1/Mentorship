enum UserRole { mentee, mentor }

enum AuthStatus { loading, authenticated, unauthenticated }

class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.avatarInitials,
    this.mentorProfileId,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;
  final String avatarInitials;
  final String? mentorProfileId;

  String get fullName => '$firstName $lastName';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final firstName = _string(json['first_name'] ?? json['firstName']);
    final lastName = _string(json['last_name'] ?? json['lastName']);
    return AppUser(
      id: _string(json['id']),
      firstName: firstName,
      lastName: lastName,
      email: _string(json['email']),
      role: _roleFromJson(json['role']),
      avatarInitials: _initials(firstName, lastName, _string(json['email'])),
      mentorProfileId: _nullableString(json['mentor_profile_id']),
    );
  }

  AppUser copyWith({UserRole? role, String? mentorProfileId}) => AppUser(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    role: role ?? this.role,
    avatarInitials: avatarInitials,
    mentorProfileId: mentorProfileId ?? this.mentorProfileId,
  );
}

String _string(Object? value) => value?.toString() ?? '';

String? _nullableString(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

UserRole _roleFromJson(Object? value) {
  final role = value?.toString().toLowerCase().trim();
  return role == 'mentor' || role == 'mentor_user' || role == 'teacher'
      ? UserRole.mentor
      : UserRole.mentee;
}

String _initials(String firstName, String lastName, String email) {
  final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
  final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
  final initials = '$first$last'.toUpperCase();
  if (initials.isNotEmpty) return initials;
  return email.isNotEmpty ? email[0].toUpperCase() : '?';
}

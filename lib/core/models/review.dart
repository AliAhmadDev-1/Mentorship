class Review {
  const Review({
    required this.id,
    required this.mentorId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.tags,
  });

  final String id;
  final String mentorId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String> tags;

  String get ratingLabel => rating.toStringAsFixed(1);
}

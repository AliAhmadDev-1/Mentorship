class Conversation {
  const Conversation({
    required this.id,
    required this.participantName,
    required this.participantInitials,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.isOnline,
    required this.avatarColorValue,
    this.relatedSessionId,
  });

  final String id;
  final String participantName;
  final String participantInitials;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOnline;
  final int avatarColorValue;
  final String? relatedSessionId;
}

import '../models/api_models.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../network/api_exception.dart';
import '../network/error_handler.dart';
import '../network/micro_mentor_api.dart';

class MessageRepository {
  MessageRepository({MicroMentorApi? api}) : _api = api ?? MicroMentorApi();

  final MicroMentorApi _api;

  Future<List<Conversation>> getConversations() async {
    final response = await _api.listConversations();
    if (!response.success) throw response.error!;
    return (response.data?.results ?? const [])
        .map(_conversationFromResponse)
        .toList();
  }

  Future<Conversation> getConversation(String conversationId) async {
    final response = await _api.getConversation(conversationId);
    if (!response.success) throw response.error!;
    final detail = response.data;
    if (detail == null) {
      throw const ApiException(
        message: ErrorHandler.invalidFormatMessage,
        type: ApiExceptionType.parseError,
      );
    }

    final messages = detail.messages;
    final last = messages.isEmpty ? null : messages.last;
    final name = _conversationName(
      otherUserName: detail.otherUserName,
      participants: detail.participants,
    );
    return Conversation(
      id: '${detail.id}',
      participantName: name,
      participantInitials: _initials(name),
      lastMessage: last?.body ?? '',
      lastMessageAt: last?.createdAt ?? DateTime.now(),
      unreadCount: 0,
      isOnline: false,
      avatarColorValue: _avatarColor(detail.id, name),
      relatedSessionId: detail.sessionId?.toString(),
    );
  }

  Future<Conversation> createInquiryConversation({
    required Object mentorId,
  }) async {
    final response = await _api.createConversation(
      type: 'inquiry',
      mentorId: mentorId,
    );
    if (!response.success) {
      final existing = await _findExistingInquiry(mentorId);
      if (existing != null) return existing;
      throw response.error!;
    }
    final conversation = response.data;
    if (conversation == null || conversation.id <= 0) {
      final existing = await _findExistingInquiry(mentorId);
      if (existing != null) return existing;
      throw const ApiException(
        message: ErrorHandler.invalidFormatMessage,
        type: ApiExceptionType.parseError,
      );
    }
    return _conversationFromResponse(conversation);
  }

  Future<Conversation?> _findExistingInquiry(Object mentorId) async {
    final response = await _api.listConversations();
    if (!response.success) return null;
    final targetMentorId = int.tryParse(mentorId.toString());
    for (final item in response.data?.results ?? const []) {
      final isInquiry = item.type == null || item.type == 'inquiry';
      final isOpen = item.status == null || item.status == 'open';
      if (!isInquiry || !isOpen) continue;
      if (targetMentorId != null && item.mentorId == targetMentorId) {
        return _conversationFromResponse(item);
      }
    }
    return null;
  }

  Future<Conversation> createSessionConversation({
    required Object sessionId,
  }) async {
    final response = await _api.createConversation(
      type: 'session',
      sessionId: sessionId,
    );
    if (!response.success) throw response.error!;
    final conversation = response.data;
    if (conversation == null || conversation.id <= 0) {
      throw const ApiException(
        message: ErrorHandler.invalidFormatMessage,
        type: ApiExceptionType.parseError,
      );
    }
    return _conversationFromResponse(conversation);
  }

  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _api.listMessages(conversationId);
    if (!response.success) throw response.error!;
    return (response.data?.results ?? const [])
        .map((item) => _messageFromResponse(conversationId, item))
        .toList();
  }

  Future<Message> sendMessage(String conversationId, String text) async {
    final response = await _api.sendMessage(
      conversationId: conversationId,
      body: text,
    );
    if (!response.success) throw response.error!;
    final message = response.data;
    if (message == null) {
      throw const ApiException(
        message: ErrorHandler.invalidFormatMessage,
        type: ApiExceptionType.parseError,
      );
    }
    return _messageFromResponse(conversationId, message, isMine: true);
  }
}

Conversation _conversationFromResponse(ConversationCreateResponse response) {
  final name = _conversationName(
    otherUserName: response.otherUserName,
    participants: response.participants,
  );
  return Conversation(
    id: '${response.id}',
    participantName: name,
    participantInitials: _initials(name),
    lastMessage: response.lastMessage ?? '',
    lastMessageAt:
        response.lastMessageAt ?? response.updatedAt ?? DateTime.now(),
    unreadCount: response.unreadCount ?? 0,
    isOnline: false,
    avatarColorValue: _avatarColor(response.id, name),
    relatedSessionId: response.sessionId?.toString(),
  );
}

String _conversationName({
  required String? otherUserName,
  required List<String> participants,
}) {
  final name = otherUserName?.trim();
  if (name != null && name.isNotEmpty) return name;
  if (participants.isEmpty) return 'Conversation';
  return participants.join(', ');
}

Message _messageFromResponse(
  String conversationId,
  MessageResponse response, {
  bool isMine = false,
}) {
  return Message(
    id: '${response.id}',
    conversationId: conversationId,
    senderId: response.senderId ?? response.sender ?? '',
    text: response.body ?? '',
    sentAt: response.createdAt ?? DateTime.now(),
    isMine: isMine || (response.isMine ?? false),
    type: 'text',
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'[\s,]+'))
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

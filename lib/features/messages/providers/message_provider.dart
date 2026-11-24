import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/conversation.dart';
import '../../../core/models/message.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/repositories/message_repository.dart';

final messageRepositoryProvider = Provider<MessageRepository>(
  (ref) => MessageRepository(api: ref.watch(microMentorApiProvider)),
);
final conversationProvider =
    AsyncNotifierProvider<ConversationNotifier, List<Conversation>>(
      ConversationNotifier.new,
    );
final messageProvider =
    AsyncNotifierProvider.family<MessageNotifier, List<Message>, String>(
      MessageNotifier.new,
    );
final conversationDetailProvider = FutureProvider.family<Conversation, String>(
  (ref, id) => ref.read(messageRepositoryProvider).getConversation(id),
);

class ConversationNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() =>
      ref.read(messageRepositoryProvider).getConversations();

  Future<Conversation> startInquiry({required Object mentorId}) async {
    final conversation = await ref
        .read(messageRepositoryProvider)
        .createInquiryConversation(mentorId: mentorId);
    ref.invalidateSelf();
    return conversation;
  }

  Future<Conversation> startSession({required Object sessionId}) async {
    final conversation = await ref
        .read(messageRepositoryProvider)
        .createSessionConversation(sessionId: sessionId);
    ref.invalidateSelf();
    return conversation;
  }
}

class MessageNotifier extends FamilyAsyncNotifier<List<Message>, String> {
  @override
  Future<List<Message>> build(String arg) =>
      ref.read(messageRepositoryProvider).getMessages(arg);

  Future<bool> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    try {
      final message = await ref
          .read(messageRepositoryProvider)
          .sendMessage(arg, trimmed);
      state = AsyncData([...(state.valueOrNull ?? []), message]);
      ref.invalidate(conversationProvider);
      ref.invalidate(conversationDetailProvider(arg));
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

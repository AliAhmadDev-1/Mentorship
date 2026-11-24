import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../providers/message_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _text.text;
    if (text.trim().isEmpty) return;
    setState(() => _isSending = true);
    final sent = await ref
        .read(messageProvider(widget.conversationId).notifier)
        .send(text);
    if (!mounted) return;
    if (sent) {
      _text.clear();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message failed to send')));
    }
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(
      conversationDetailProvider(widget.conversationId),
    );
    final messages = ref.watch(messageProvider(widget.conversationId));
    return Scaffold(
      appBar: AppBar(
        title: conversation.when(
          loading: () => const Text('Chat'),
          error: (_, _) => const Text('Chat'),
          data: (convo) => Row(
            children: [
              AppAvatar(
                initials: convo.participantInitials,
                colorValue: convo.avatarColorValue,
                isOnline: convo.isOnline,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(convo.participantName)),
            ],
          ),
        ),
        actions: [
          conversation.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (convo) => IconButton(
              tooltip: convo.relatedSessionId == null
                  ? 'No related session'
                  : 'Join session',
              onPressed: convo.relatedSessionId == null
                  ? null
                  : () => context.push('/session/${convo.relatedSessionId}'),
              icon: const Icon(Icons.videocam_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('$e')),
                data: (items) => ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final message = items[index];
                    return Align(
                      alignment: message.isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .76,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message.isMine
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.attachmentName != null)
                              Text(
                                message.attachmentName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            Text(
                              message.text,
                              style: TextStyle(
                                color: message.isMine
                                    ? AppColors.darkest
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              DateFormat('h:mm a').format(message.sentAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: message.isMine
                                    ? AppColors.darkest
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const IconButton(
                    tooltip: 'Attachments unavailable',
                    onPressed: null,
                    icon: Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(hintText: 'Message'),
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: AppColors.darkest),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

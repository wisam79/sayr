import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

import '../../../../core/sayr_flash.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_input.dart';

/// Page showing a single conversation with realtime updates.
class ChatPage extends StatefulWidget {
  const ChatPage({required this.conversationId, super.key});

  final ConversationId conversationId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final AuthRepository authRepo = context.read<AuthRepository>();
    _currentUserId = authRepo.currentUser?.id.value;
    context.read<ChatBloc>().add(ChatStarted(widget.conversationId));
  }

  @override
  void dispose() {
    context.read<ChatBloc>().add(const ChatClosed());
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثة'),
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (BuildContext context, ChatState state) {
          if (state is ChatError) {
            SayrFlash.error(
              context,
              state.failure.message ?? 'حدث خطأ في المحادثة',
            );
          }
          if (state is ChatLoaded) {
            _scrollToBottom();
          }
        },
        builder: (BuildContext context, ChatState state) {
          return switch (state) {
            ChatInitial() || ChatLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ChatError() => _ChatErrorBody(failure: state.failure),
            ChatLoaded() => _ChatBody(
                state: state,
                textController: _textController,
                scrollController: _scrollController,
                currentUserId: _currentUserId,
              ),
          };
        },
      ),
    );
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody({
    required this.state,
    required this.textController,
    required this.scrollController,
    required this.currentUserId,
  });

  final ChatLoaded state;
  final TextEditingController textController;
  final ScrollController scrollController;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: state.messages.isEmpty
              ? const Center(
                  child: Text('لا توجد رسائل بعد. ابدأ المحادثة!'),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: state.messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Message message = state.messages[index];
                    final bool isMe = message.senderId.value == currentUserId;
                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                ),
        ),
        ChatInput(
          controller: textController,
          isSending: state.isSending,
          onSend: (String body) {
            context.read<ChatBloc>().add(ChatMessageSent(body));
          },
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final Message message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          BubbleNormal(
            text: message.body,
            isSender: isMe,
            color: isMe
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.surface,
            textStyle:
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            seen: message.isRead,
            tail: true,
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
            child: Text(
              DateFormat.Hm().format(message.createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatErrorBody extends StatelessWidget {
  const _ChatErrorBody({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              failure.message ?? 'حدث خطأ',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

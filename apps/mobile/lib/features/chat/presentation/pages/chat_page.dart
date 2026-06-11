import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_state.dart';
import 'package:sayr_mobile/features/chat/presentation/widgets/chat_input.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Page showing a single conversation with realtime updates.
class ChatPage extends StatefulWidget {
  /// Creates a [ChatPage] with the given [conversationId].
  const ChatPage({required this.conversationId, super.key});

  /// The active [ConversationId] of the chat.
  final ConversationId conversationId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatBloc _chatBloc;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final authRepo = context.read<AuthRepository>();
    _currentUserId = authRepo.currentUser?.id.value;
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(ChatStarted(widget.conversationId));
  }

  @override
  void dispose() {
    _chatBloc.add(const ChatClosed());
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chats),
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (BuildContext context, ChatState state) {
          if (state is ChatError) {
            SayrFlash.error(
              context,
              state.failure.toLocalizedString(context),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: state.messages.isEmpty
              ? Center(
                  child: Text(l10n.noChats),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: state.messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final message = state.messages[index];
                    final isMe = message.senderId.value == currentUserId;
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
    final isRtl = Directionality.of(context).index == 1;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMe == isRtl ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          BubbleNormal(
            text: message.body,
            isSender: isMe,
            color: isMe
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            textStyle:
                (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(
              color: isMe
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            seen: message.isRead,
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
              failure.toLocalizedString(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_list_state.dart';
import 'package:sayr_mobile/features/chat/presentation/widgets/conversation_card.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Page listing all conversations the current user participates in.
class ChatListPage extends StatefulWidget {
  /// Creates a [ChatListPage].
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late final ChatListBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<ChatListBloc>();
    _bloc.add(const ChatListLoadRequested());
  }

  @override
  void dispose() {
    _bloc.add(const ChatListClosed());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chats),
      ),
      body: BlocConsumer<ChatListBloc, ChatListState>(
        listener: (context, state) {
          if (state is ChatListError) {
            SayrFlash.error(
              context,
              state.failure.message ?? l10n.errorOccurred,
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            ChatListInitial() || ChatListLoading() => const _LoadingBody(),
            ChatListError() => _ErrorBody(
                failure: state.failure,
                onRetry: () => context
                    .read<ChatListBloc>()
                    .add(const ChatListRefreshRequested()),
              ),
            ChatListLoaded(:final conversations) => _ChatListBody(
                conversations: conversations,
                onTapConversation: (c) => context.push('/chat/${c.id.value}'),
              ),
          };
        },
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.builder(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.sm,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const ListTile(
          leading: Bone.circle(size: 40),
          title: Bone.text(),
          subtitle: Padding(
            padding: EdgeInsetsDirectional.only(top: 4),
            child: Bone.text(),
          ),
        ),
      ),
    );
  }
}

class _ChatListBody extends StatelessWidget {
  const _ChatListBody({
    required this.conversations,
    required this.onTapConversation,
  });

  final List<Conversation> conversations;
  final ValueChanged<Conversation> onTapConversation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (conversations.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.chat_bubble_outline,
          title: l10n.noChats,
          subtitle: l10n.pullToRefresh,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatListBloc>().add(const ChatListRefreshRequested());
      },
      child: ListView.separated(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.sm,
        ),
        itemCount: conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = conversations[index];
          return ConversationCard(
            conversation: c,
            onTap: () => onTapConversation(c),
          );
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              failure.message ?? l10n.errorOccurred,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

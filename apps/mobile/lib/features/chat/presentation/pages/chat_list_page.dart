import 'package:empty_widget/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/sayr_flash.dart';
import '../bloc/chat_list_bloc.dart';
import '../bloc/chat_list_state.dart';
import '../widgets/conversation_card.dart';

/// Page listing all conversations the current user participates in.
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ChatListBloc>().add(const ChatListLoadRequested());
  }

  @override
  void dispose() {
    context.read<ChatListBloc>().add(const ChatListClosed());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات'),
      ),
      body: BlocConsumer<ChatListBloc, ChatListState>(
        listener: (context, state) {
          if (state is ChatListError) {
            SayrFlash.error(
              context,
              state.failure.message ?? 'حدث خطأ في تحميل المحادثات',
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
      enabled: true,
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
    if (conversations.isEmpty) {
      return Center(
        child: EmptyWidget(
          image: null,
          title: 'لا توجد محادثات',
          subTitle: 'ابدأ محادثة مع سائق من صفحة تفاصيل الخط',
          titleTextStyle: Theme.of(context).textTheme.titleMedium,
          subtitleTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
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
          final Conversation c = conversations[index];
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
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:sayr_mobile/features/notifications/presentation/widgets/notification_card.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(const NotificationsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: GlassAppBar(
        title: Text(l10n.notifications),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            buildWhen: (prev, curr) =>
                prev.maybeWhen(loaded: (a, b) => b, orElse: () => 0) !=
                curr.maybeWhen(loaded: (a, b) => b, orElse: () => 0),
            builder: (context, state) {
              final unread = state.maybeWhen(
                loaded: (_, count) => count,
                orElse: () => 0,
              );
              if (unread == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  context
                      .read<NotificationsBloc>()
                      .add(const NotificationsMarkAllRead());
                  SayrFlash.info(context, l10n.allMarkedAsRead);
                },
                child: Text(l10n.markAllAsRead),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsError) {
            SayrFlash.error(
              context,
              state.failure.toLocalizedString(context),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            NotificationsInitial() ||
            NotificationsLoading() =>
              const _SkeletonLoading(),
            NotificationsError(:final failure) => AppErrorWidget(
                message: failure.toLocalizedString(context),
                title: l10n.error,
                retryLabel: l10n.retry,
                onRetry: () => context
                    .read<NotificationsBloc>()
                    .add(const NotificationsRefreshRequested()),
              ),
            NotificationsLoaded(:final notifications) =>
              _NotificationsBody(notifications: notifications),
          };
        },
      ),
    );
  }
}

class _SkeletonLoading extends StatelessWidget {
  const _SkeletonLoading();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.sm,
        ),
        children: List.generate(
          6,
          (_) => _NotificationsBody._skeletonTile(),
        ),
      ),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (notifications.isEmpty) {
      return EmptyState(
        icon: Icons.notifications_none,
        title: l10n.noNotifications,
        subtitle: l10n.pullToRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<NotificationsBloc>()
            .add(const NotificationsRefreshRequested());
      },
      child: ListView.separated(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.sm,
        ),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final n = notifications[index];
          return NotificationCard(
            notification: n,
            onTap: () {
              context
                  .read<NotificationsBloc>()
                  .add(NotificationMarkedRead(n.id));
              _onNotificationTap(context, n);
            },
          );
        },
      ),
    );
  }

  static ListTile _skeletonTile() => const ListTile(
        leading: Bone.circle(size: 40),
        title: Bone.text(),
        subtitle: Padding(
          padding: EdgeInsetsDirectional.only(top: 4),
          child: Bone.text(),
        ),
      );

  void _onNotificationTap(BuildContext context, AppNotification n) {
    final tripId = n.data['trip_id'] as String?;
    if (tripId != null) {
      context.push('/trip/$tripId');
      return;
    }
    final conversationId = n.data['conversation_id'] as String?;
    if (conversationId != null) {
      context.push('/chat/$conversationId');
    }
  }
}

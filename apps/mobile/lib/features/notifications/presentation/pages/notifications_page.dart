import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:sayr_mobile/features/notifications/presentation/widgets/notification_card.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Page responsible for showing user notification inbox.
class NotificationsPage extends StatefulWidget {
  /// Creates a [NotificationsPage].
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
      appBar: AppBar(
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
              state.failure.message ?? l10n.loadFailed,
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            NotificationsInitial() ||
            NotificationsLoading() =>
              const Center(child: CircularProgressIndicator()),
            NotificationsError() => _ErrorBody(
                failure: state.failure,
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

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_none,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.noNotifications,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
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
        separatorBuilder: (_, __) => const Divider(height: 1),
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

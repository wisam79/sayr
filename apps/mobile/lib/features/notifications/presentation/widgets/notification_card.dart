import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// A single notification card in the inbox list.
class NotificationCard extends StatelessWidget {
  /// Creates a [NotificationCard] to show single notification item.
  const NotificationCard({
    required this.notification,
    required this.onTap,
    super.key,
  });

  /// The notification details to display.
  final AppNotification notification;

  /// Callback when the notification card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      color: isUnread ? AppColors.primary.withValues(alpha: 0.03) : null,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isUnread
                ? AppColors.primary.withValues(alpha: 0.15)
                : Theme.of(context).colorScheme.surface,
            child: Icon(
              _iconForType(notification.data['type'] as String?),
              size: 20,
              color: isUnread ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRelative(notification.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          if (isUnread)
            const Padding(
              padding: EdgeInsetsDirectional.only(start: AppSpacing.sm),
              child: SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'trip':
        return Icons.directions_bus;
      case 'payment':
        return Icons.payment;
      case 'message':
        return Icons.chat_bubble;
      case 'emergency':
        return Icons.emergency;
      default:
        return Icons.notifications;
    }
  }

  String _formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());

    if (diff.inMinutes < 1) {
      return DateFormat.Hm().format(dt.toLocal());
    }
    if (diff.inDays < 7) {
      return DateFormat('E HH:mm').format(dt.toLocal());
    }
    return DateFormat('yyyy-MM-dd').format(dt.toLocal());
  }
}

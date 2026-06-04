import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// A single notification card in the inbox list.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.notification,
    required this.onTap,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: notification.isRead
          ? null
          : AppColors.primary.withValues(alpha: 0.05),
      leading: CircleAvatar(
        backgroundColor: notification.isRead
            ? AppColors.surface
            : AppColors.primary.withValues(alpha: 0.15),
        child: Icon(
          _iconForType(notification.data['type'] as String?),
          color:
              notification.isRead ? AppColors.textSecondary : AppColors.primary,
        ),
      ),
      title: Text(
        notification.title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
      ),
      subtitle: Padding(
        padding: const EdgeInsetsDirectional.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
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
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(dt.toLocal());

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} س';
    if (diff.inDays < 7) return 'قبل ${diff.inDays} يوم';
    return DateFormat('yyyy-MM-dd').format(dt.toLocal());
  }
}

import 'package:flutter/material.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// A single row in the conversations list.
///
/// Shows the other participant's name (or route title as fallback),
/// the last message preview, and a relative timestamp.
class ConversationCard extends StatelessWidget {
  const ConversationCard({
    required this.conversation,
    required this.onTap,
    super.key,
  });

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String title =
        conversation.otherUserName ?? conversation.routeName ?? 'محادثة';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          _initials(title),
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Padding(
        padding: const EdgeInsetsDirectional.only(top: 4),
        child: Text(
          conversation.lastMessagePreview ?? 'لا توجد رسائل بعد',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
      trailing: conversation.lastMessageAt != null
          ? Text(
              _formatRelative(conversation.lastMessageAt!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          : null,
    );
  }

  String _initials(String name) {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String _formatRelative(DateTime dt) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} س';
    if (diff.inDays < 7) return 'قبل ${diff.inDays} يوم';
    return '${dt.toLocal().year}-${dt.toLocal().month.toString().padLeft(2, '0')}-${dt.toLocal().day.toString().padLeft(2, '0')}';
  }
}

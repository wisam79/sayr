import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// A single row in the conversations list.
///
/// Shows the other participant's name (or route title as fallback),
/// the last message preview, and a relative timestamp.
class ConversationCard extends StatelessWidget {
  /// Creates a [ConversationCard] for displaying conversation preview.
  const ConversationCard({
    required this.conversation,
    required this.onTap,
    super.key,
  });

  /// The conversation info to display.
  final Conversation conversation;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title =
        conversation.otherUserName ?? conversation.routeName ?? l10n.chats;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          _initials(title),
          style: const TextStyle(
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
          conversation.lastMessagePreview ?? l10n.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
      trailing: conversation.lastMessageAt != null
          ? Text(
              _formatRelative(conversation.lastMessageAt!, context),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          : null,
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String _formatRelative(DateTime dt, BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (diff.inMinutes < 1) {
      return DateFormat.Hm(locale).format(dt.toLocal());
    }
    if (diff.inDays < 7) {
      return DateFormat('E HH:mm', locale).format(dt.toLocal());
    }
    return DateFormat('y-MM-dd', locale).format(dt.toLocal());
  }
}

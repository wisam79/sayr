import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays driver information, rating and action buttons
/// (call + chat) in the trip tracking bottom sheet.
class DriverInfoSection extends StatelessWidget {
  /// Creates a [DriverInfoSection] with the given [profile], [driver],
  /// optional [route] and [trip].
  const DriverInfoSection({
    required this.profile,
    required this.driver,
    required this.route,
    required this.trip,
    super.key,
  });

  /// The driver profile (user info: name, avatar, phone).
  final User profile;

  /// The driver entity (vehicle, rating, verification status).
  final Driver driver;

  /// The route associated with the trip.
  final Route? route;

  /// The current trip.
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            _Avatar(avatarUrl: profile.avatarUrl),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NameRow(
                    fullName: profile.fullName ?? '',
                    isVerified: driver.isVerified,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${driver.vehicleModel} • ${driver.vehiclePlate}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            _RatingBadge(rating: driver.rating),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: l10n.callDriver,
                icon: Icons.phone,
                onPressed: () => _launchCall(profile.phone),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SecondaryButton(
                label: l10n.chatDriver,
                icon: Icons.chat_bubble_outline,
                onPressed: () => _openChat(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _launchCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openChat(BuildContext context) async {
    final chatRepo = sl<ChatRepository>();
    final router = GoRouter.of(context);

    final conversationResult = await chatRepo.getOrCreateConversation(
      routeId: route!.id,
      driverUserId: driver.userId,
    );
    conversationResult.fold(
      (failure) {
        SayrFlash.error(context, failure.toLocalizedString(context));
      },
      (conversation) {
        router.push('/chat/${conversation.id.value}');
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundImage:
          avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
      child: avatarUrl == null
          ? const Icon(Icons.person, color: AppColors.primary)
          : null,
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({
    required this.fullName,
    required this.isVerified,
  });

  final String fullName;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          fullName,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (isVerified) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.verified,
            color: AppColors.primary,
            size: 16,
          ),
        ],
      ],
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.amber[800],
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

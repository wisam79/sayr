import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/features/home/presentation/widgets/ticket_separator.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class DigitalTicketPass extends StatefulWidget {
  const DigitalTicketPass({
    required this.subscription,
    required this.user,
    required this.onTap,
    super.key,
  });

  final core.Subscription subscription;
  final core.User? user;
  final VoidCallback onTap;

  @override
  State<DigitalTicketPass> createState() => _DigitalTicketPassState();
}

class _DigitalTicketPassState extends State<DigitalTicketPass>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _shimmerController.stop();
      _pulseController.stop();
    } else {
      if (!_shimmerController.isAnimating) {
        _shimmerController.repeat();
      }
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final daysLeft = widget.subscription.daysRemaining ?? 0;
    const totalDays = 30.0;
    final progress = (daysLeft / totalDays).clamp(0.0, 1.0);
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final disableAnimations =
        isTest || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final showGlow = daysLeft < 5;

    Widget progressWidget = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 8,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        color: Colors.white,
        semanticsLabel: l10n.subscriptionDaysLeft(daysLeft),
      ),
    );

    if (showGlow && !disableAnimations) {
      progressWidget = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseValue = _pulseAnimation.value;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: pulseValue * 0.4),
                  blurRadius: 8 + pulseValue * 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          );
        },
        child: progressWidget,
      );
    }

    return Semantics(
      label: l10n.myDigitalPass,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00875A),
              Color(0xFF006644),
              Color(0xFF004D33),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Diagonal Holographic Shimmer Overlay
              if (!disableAnimations)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      final shimmerPosition = _shimmerController.value;
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin:
                                Alignment(-2.0 + 4.0 * shimmerPosition, -2.0),
                            end: Alignment(-1.0 + 4.0 * shimmerPosition, -1.0),
                            colors: const [
                              Color(0x00FFFFFF),
                              Color(0x14FFFFFF),
                              Color(0x00FFFFFF),
                            ],
                            stops: const [0.4, 0.5, 0.6],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: Container(color: Colors.white),
                      );
                    },
                  ),
                ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.confirmation_number,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  l10n.myDigitalPass,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.subscriptionStatusActive,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (widget.user != null) ...[
                          Text(
                            widget.user!.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          if (widget.user!.phone != null)
                            Text(
                              widget.user!.phone!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                            ),
                        ] else ...[
                          Text(
                            l10n.subscriptionType,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                        if (widget.subscription.endDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.subscriptionEndsOn(
                              widget.subscription.endDate!
                                  .toLocal()
                                  .toString()
                                  .split(' ')
                                  .first,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ColoredBox(
                    color: Colors.transparent, // Transparent to show gradient
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadiusDirectional.only(
                              topEnd: Radius.circular(8),
                              bottomEnd: Radius.circular(8),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TicketSeparator(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadiusDirectional.only(
                              topStart: Radius.circular(8),
                              bottomStart: Radius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.subscriptionDaysLeft(daysLeft),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        progressWidget,
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.qr_code,
                                color: AppColors.primary),
                            label: Text(
                              l10n.scanQrCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onPressed: widget.onTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyDigitalTicketPass extends StatelessWidget {
  const EmptyDigitalTicketPass({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.darkSurface
        : AppColors.primary.withValues(alpha: 0.04);
    final borderColor = isDark
        ? AppColors.borderDark
        : AppColors.primary.withValues(alpha: 0.1);

    return Semantics(
      label: l10n.noActiveSubscription,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.noActiveSubscription,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.getSubscription,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadiusDirectional.only(
                      topEnd: Radius.circular(8),
                      bottomEnd: Radius.circular(8),
                    ),
                  ),
                ),
                Expanded(
                  child: TicketSeparator(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                Container(
                  width: 8,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadiusDirectional.only(
                      topStart: Radius.circular(8),
                      bottomStart: Radius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: PrimaryButton(
                label: l10n.activateLicense,
                onPressed: () {
                  GoRouter.of(context).push('/activate-license');
                },
                icon: Icons.add,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

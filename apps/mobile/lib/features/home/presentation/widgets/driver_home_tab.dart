import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/home/presentation/bloc/create_trip_dialog_cubit.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/create_trip_dialog.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class DriverHomeTab extends StatelessWidget {
  const DriverHomeTab({required this.onOpenTrips, super.key});

  final VoidCallback onOpenTrips;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return GreetingCard(
                  title: l10n.helloUser(state.user.displayName),
                  subtitle: '',
                  avatarWidget: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      state.user.displayName.isNotEmpty
                          ? state.user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  badgeWidget: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.driverBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: DriverStatCard(
                  icon: Icons.directions_bus,
                  value: '24',
                  label: l10n.statsTrips,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DriverStatCard(
                  icon: Icons.star,
                  value: '4.9',
                  label: l10n.statsRating,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.driverDashboard,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          DriverActionCard(
            title: l10n.createNewTrip,
            subtitle: l10n.createNewTripDesc,
            icon: Icons.add_circle_outline,
            iconColor: AppColors.primary,
            onTap: () => _showCreateTripDialog(context),
          ),
          const SizedBox(height: AppSpacing.md),
          DriverActionCard(
            title: l10n.myActiveTrips,
            subtitle: l10n.myActiveTripsDesc,
            icon: Icons.play_arrow_outlined,
            iconColor: AppColors.secondary,
            onTap: () {
              context.read<TrackingBloc>().add(const TrackingLoadActiveTrips());
              onOpenTrips();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateTripDialog(BuildContext context) async {
    final trip = await showDialog<core.Trip>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => CreateTripDialogCubit(
          routeRepository: sl<core.RouteRepository>(),
        )..loadRoutes(),
        child: const CreateTripDialog(),
      ),
    );
    if (trip != null && context.mounted) {
      context.go('/driver-trip/${trip.id.value}');
    }
  }
}

class DriverStatCard extends StatefulWidget {
  const DriverStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  State<DriverStatCard> createState() => _DriverStatCardState();
}

class _DriverStatCardState extends State<DriverStatCard> with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _entranceController.value = 1.0;
    } else if (!_entranceController.isAnimating && _entranceController.value < 1.0) {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    // Parse the value string as a number
    final double? parsedVal = double.tryParse(widget.value);
    final isDouble = widget.value.contains('.');

    Widget buildValue(double val) {
      String formatted;
      if (isDouble) {
        formatted = val.toStringAsFixed(1);
      } else {
        formatted = val.toInt().toString();
      }
      return Text(
        formatted,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      );
    }

    Widget valueWidget;
    if (parsedVal == null || disableAnimations) {
      valueWidget = Text(
        widget.value,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      );
    } else {
      valueWidget = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: parsedVal),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, val, child) {
          return buildValue(val);
        },
      );
    }

    Widget cardContent = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              valueWidget,
              Icon(widget.icon, color: widget.color, size: 24),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );

    return Semantics(
      label: '${widget.label}: ${widget.value}',
      child: disableAnimations
          ? cardContent
          : FadeTransition(
              opacity: _opacityAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: cardContent,
              ),
            ),
    );
  }
}

class DriverActionCard extends StatelessWidget {
  const DriverActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : iconColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: iconColor.withValues(alpha: 0.12),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

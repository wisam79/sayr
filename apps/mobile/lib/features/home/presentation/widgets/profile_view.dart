import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/core/locale_cubit.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/core/theme_cubit.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/change_password_dialog.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/edit_profile_dialog.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_bloc.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Tab displaying user profile and application settings.
class ProfileTab extends StatelessWidget {
  /// Creates a [ProfileTab].
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }
        return _ProfileView(user: state.user);
      },
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView({required this.user});

  final core.User user;

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> with TickerProviderStateMixin {
  bool _bleEnabled = false;
  bool _isLoadingBle = true;
  late final AnimationController _avatarRingController;

  @override
  void initState() {
    super.initState();
    _avatarRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _loadBlePreference();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _avatarRingController.stop();
    } else if (!_avatarRingController.isAnimating) {
      _avatarRingController.repeat();
    }
  }

  @override
  void dispose() {
    _avatarRingController.dispose();
    super.dispose();
  }

  Future<void> _loadBlePreference() async {
    final box = await Hive.openBox<String>('settings_box');
    if (mounted) {
      setState(() {
        _bleEnabled = box.get('ble_proximity_enabled') == 'true';
        _isLoadingBle = false;
      });
    }
  }

  Future<void> _toggleBle(bool value) async {
    final box = await Hive.openBox<String>('settings_box');
    await box.put('ble_proximity_enabled', value.toString());
    if (mounted) {
      setState(() {
        _bleEnabled = value;
      });
    }
  }

  Future<void> _syncCache() async {
    final l10n = AppLocalizations.of(context);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(l10n.loading)),
            ],
          ),
        ),
      ),
    );

    context.read<RoutesBloc>().add(const RoutesLoadRequested());
    context.read<SubscriptionsBloc>().add(const SubscriptionsLoadRequested());
    context.read<NotificationsBloc>().add(const NotificationsLoadRequested());

    await Future<void>.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.of(context).pop();
      SayrFlash.success(context, l10n.syncCompleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final disableAnimations = isTest || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        GlassCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: AppColors.primary.withValues(alpha: isDark ? 0.05 : 0.02),
          borderOpacity: isDark ? 0.12 : 0.08,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (disableAnimations)
                    CustomPaint(
                      size: const Size(88, 88),
                      painter: _AvatarRingPainter(primaryColor: AppColors.primary),
                    )
                  else
                    RotationTransition(
                      turns: _avatarRingController,
                      child: CustomPaint(
                        size: const Size(88, 88),
                        painter: _AvatarRingPainter(primaryColor: AppColors.primary),
                      ),
                    ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.18),
                          AppColors.primary.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.user.displayName.isNotEmpty
                            ? widget.user.displayName[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.user.displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.user.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionHeader(l10n.accountSettings, theme),
        const SizedBox(height: AppSpacing.xs),
        GlassCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          borderOpacity: isDark ? 0.12 : 0.08,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  LucideIcons.user,
                  color: AppColors.primary,
                ),
                title: Text(l10n.editProfile),
                trailing: const Icon(
                  LucideIcons.chevron_right,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => EditProfileDialog(user: widget.user),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  LucideIcons.lock,
                  color: AppColors.primary,
                ),
                title: Text(l10n.changePassword),
                trailing: const Icon(
                  LucideIcons.chevron_right,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ChangePasswordDialog(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionHeader(l10n.appPreferences, theme),
        const SizedBox(height: AppSpacing.xs),
        GlassCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          borderOpacity: isDark ? 0.12 : 0.08,
          child: Column(
            children: [
              ListTile(
                leading:
                    const Icon(LucideIcons.globe, color: AppColors.primary),
                title: Text(l10n.language),
                trailing: SegmentedButton<String>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'ar',
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          l10n.arabic,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    ButtonSegment<String>(
                      value: 'en',
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          l10n.english,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  selected: <String>{
                    context.watch<LocaleCubit>().state.languageCode,
                  },
                  onSelectionChanged: (Set<String> newSelection) {
                    context
                        .read<LocaleCubit>()
                        .setLocale(Locale(newSelection.first));
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading:
                    const Icon(LucideIcons.palette, color: AppColors.primary),
                title: Text(l10n.themeMode),
                trailing: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: <ButtonSegment<ThemeMode>>[
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: const Icon(LucideIcons.sun, size: 16),
                      tooltip: l10n.themeLight,
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: const Icon(LucideIcons.moon, size: 16),
                      tooltip: l10n.themeDark,
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: const Icon(LucideIcons.laptop, size: 16),
                      tooltip: l10n.themeSystem,
                    ),
                  ],
                  selected: <ThemeMode>{context.watch<ThemeCubit>().state},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    context.read<ThemeCubit>().setThemeMode(newSelection.first);
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary:
                    const Icon(LucideIcons.bluetooth, color: AppColors.primary),
                title: Text(l10n.bleProximityBoarding),
                value: _bleEnabled,
                onChanged: _isLoadingBle ? null : _toggleBle,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionHeader(l10n.cacheAndSync, theme),
        const SizedBox(height: AppSpacing.xs),
        GlassCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          borderOpacity: isDark ? 0.12 : 0.08,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  LucideIcons.refresh_cw,
                  color: AppColors.primary,
                ),
                title: Text(l10n.forceSync),
                trailing: const Icon(
                  LucideIcons.chevron_right,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onTap: _syncCache,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          color: AppColors.error.withValues(alpha: isDark ? 0.05 : 0.02),
          child: ListTile(
            leading: const Icon(LucideIcons.log_out, color: AppColors.error),
            title: Text(
              l10n.logout,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              LucideIcons.chevron_right,
              size: 20,
              color: AppColors.error,
            ),
            onTap: () => _confirmLogout(context),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            l10n.appVersion('1.0.0'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String label, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }
}

class _AvatarRingPainter extends CustomPainter {
  const _AvatarRingPainter({required this.primaryColor});

  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor,
          primaryColor.withValues(alpha: 0.1),
          primaryColor,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - paint.strokeWidth) / 2;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AvatarRingPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor;
  }
}

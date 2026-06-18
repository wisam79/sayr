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

class _ProfileViewState extends State<_ProfileView>
    with TickerProviderStateMixin {
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
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final verifiedLabel = isAr ? 'حساب موثق' : 'Verified';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
        100, // Extra padding for the floating navigation bar
      ),
      children: [
        // Premium Profile Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B), // Dark slate
                Color(0xFF0F172A), // Deep charcoal
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(isDark ? 0.03 : 0.06),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(isDark ? 0.02 : 0.04),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
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
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.user.displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.user.isDriver
                                      ? Icons.directions_bus_rounded
                                      : Icons.school_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.user.isDriver
                                      ? l10n.driverBadge
                                      : l10n.studentBadge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.user.isVerified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    verifiedLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Section: Account Settings
        _buildSectionHeader(l10n.accountSettings, theme),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          borderOpacity: isDark ? 0.12 : 0.08,
          borderRadius: 24,
          child: Column(
            children: [
              _SettingsTile(
                icon: LucideIcons.user,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primary.withOpacity(0.08),
                title: l10n.editProfile,
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => EditProfileDialog(user: widget.user),
                ),
              ),
              Divider(
                height: 1,
                indent: 64,
                endIndent: 16,
                color: isDark
                    ? AppColors.borderDark.withOpacity(0.3)
                    : AppColors.divider.withOpacity(0.5),
              ),
              _SettingsTile(
                icon: LucideIcons.lock,
                iconColor: AppColors.secondary,
                iconBgColor: AppColors.secondary.withOpacity(0.08),
                title: l10n.changePassword,
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ChangePasswordDialog(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Section: App Preferences
        _buildSectionHeader(l10n.appPreferences, theme),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          borderOpacity: isDark ? 0.12 : 0.08,
          borderRadius: 24,
          child: Column(
            children: [
              _SettingsTile(
                icon: LucideIcons.globe,
                iconColor: Colors.blue,
                iconBgColor: Colors.blue.withOpacity(0.08),
                title: l10n.language,
                trailing: SegmentedButton<String>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'ar',
                      label: Text(
                        l10n.arabic,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ButtonSegment<String>(
                      value: 'en',
                      label: Text(
                        l10n.english,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
              Divider(
                height: 1,
                indent: 64,
                endIndent: 16,
                color: isDark
                    ? AppColors.borderDark.withOpacity(0.3)
                    : AppColors.divider.withOpacity(0.5),
              ),
              _SettingsTile(
                icon: LucideIcons.palette,
                iconColor: Colors.amber[700]!,
                iconBgColor: Colors.amber.withOpacity(0.08),
                title: l10n.themeMode,
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
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: const Icon(LucideIcons.moon, size: 16),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: const Icon(LucideIcons.laptop, size: 16),
                    ),
                  ],
                  selected: <ThemeMode>{context.watch<ThemeCubit>().state},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    context.read<ThemeCubit>().setThemeMode(newSelection.first);
                  },
                ),
              ),
              Divider(
                height: 1,
                indent: 64,
                endIndent: 16,
                color: isDark
                    ? AppColors.borderDark.withOpacity(0.3)
                    : AppColors.divider.withOpacity(0.5),
              ),
              _SettingsTile(
                icon: LucideIcons.bluetooth,
                iconColor: Colors.teal,
                iconBgColor: Colors.teal.withOpacity(0.08),
                title: l10n.bleProximityBoarding,
                trailing: Switch(
                  value: _bleEnabled,
                  onChanged: _isLoadingBle ? null : _toggleBle,
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Section: Sync & Maintenance
        _buildSectionHeader(l10n.cacheAndSync, theme),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          borderOpacity: isDark ? 0.12 : 0.08,
          borderRadius: 24,
          child: _SettingsTile(
            icon: LucideIcons.refresh_cw,
            iconColor: Colors.purple,
            iconBgColor: Colors.purple.withOpacity(0.08),
            title: l10n.forceSync,
            onTap: _syncCache,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Logout Button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(LucideIcons.log_out, size: 18, color: AppColors.error),
            label: Text(
              l10n.logout,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.error, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
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

/// A modern, beautiful settings item card.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(
                isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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

part 'profile_view.freezed.dart';

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

@freezed
abstract class BleSettingsState with _$BleSettingsState {
  const factory BleSettingsState({
    required bool enabled,
    required bool loading,
  }) = _BleSettingsState;
}

class _ProfileViewState extends State<_ProfileView> {
  final ValueNotifier<BleSettingsState> _bleSettingsNotifier =
      ValueNotifier(const BleSettingsState(enabled: false, loading: true));

  @override
  void initState() {
    super.initState();
    _loadBlePreference();
  }

  @override
  void dispose() {
    _bleSettingsNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadBlePreference() async {
    final box = await Hive.openBox<String>('settings_box');
    if (mounted) {
      _bleSettingsNotifier.value = BleSettingsState(
        enabled: box.get('ble_proximity_enabled') == 'true',
        loading: false,
      );
    }
  }

  Future<void> _toggleBle(bool value) async {
    final box = await Hive.openBox<String>('settings_box');
    await box.put('ble_proximity_enabled', value.toString());
    if (mounted) {
      _bleSettingsNotifier.value = BleSettingsState(
        enabled: value,
        loading: false,
      );
    }
  }

  Future<void> _syncCache() async {
    final l10n = AppLocalizations.of(context);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(l10n.loading)),
              ],
            ),
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

    final statusBarHeight = MediaQuery.of(context).padding.top;

    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final cardBorderColor =
        isDark ? AppColors.borderDark : Colors.grey.shade200;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        statusBarHeight + AppSpacing.sm,
        AppSpacing.pagePadding,
        100, // Extra padding for the floating navigation bar
      ),
      children: [
        // 1. Custom Header
        Row(
          textDirection: TextDirection.ltr, // Ensures Settings on Left
          children: [
            IconButton(
              icon: Icon(
                LucideIcons.settings,
                color: primaryTextColor,
                size: 24,
              ),
              onPressed: () {
                // Settings icon action placeholder
              },
            ),
            Expanded(
              child: Text(
                l10n.profile,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48), // Balancing spacer
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. Profile Details Card (Solid teal with white content, matching home page style)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                textDirection: TextDirection
                    .ltr, // Left: avatar, Middle: info, Right: chevron
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      widget.user.displayName.trim().isNotEmpty
                          ? widget.user.displayName.trim()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.user.isDriver
                                  ? Icons.directions_bus
                                  : Icons.school,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.user.isDriver
                                  ? l10n.driverBadge
                                  : l10n.studentBadge,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.user.email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Button: Edit Profile (تعديل ملف الشخصي)
              InkWell(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => EditProfileDialog(user: widget.user),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l10n.editProfile,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Section: Account Settings
        _buildSectionHeader(l10n.accountSettings),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor),
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: LucideIcons.user,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primary.withValues(alpha: 0.08),
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
                color: cardBorderColor,
              ),
              _SettingsTile(
                icon: LucideIcons.lock,
                iconColor: AppColors.secondary,
                iconBgColor: AppColors.secondary.withValues(alpha: 0.08),
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
        _buildSectionHeader(l10n.appPreferences),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor),
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: LucideIcons.globe,
                iconColor: Colors.blue,
                iconBgColor: Colors.blue.withValues(alpha: 0.08),
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
                color: cardBorderColor,
              ),
              _SettingsTile(
                icon: LucideIcons.palette,
                iconColor: Colors.amber[700]!,
                iconBgColor: Colors.amber.withValues(alpha: 0.08),
                title: l10n.themeMode,
                trailing: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: const <ButtonSegment<ThemeMode>>[
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: Icon(LucideIcons.sun, size: 16),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: Icon(LucideIcons.moon, size: 16),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: Icon(LucideIcons.laptop, size: 16),
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
                color: cardBorderColor,
              ),
              ValueListenableBuilder<BleSettingsState>(
                valueListenable: _bleSettingsNotifier,
                builder: (context, bleState, _) {
                  return _SettingsTile(
                    icon: LucideIcons.bluetooth,
                    iconColor: Colors.teal,
                    iconBgColor: Colors.teal.withValues(alpha: 0.08),
                    title: l10n.bleProximityBoarding,
                    trailing: Switch(
                      value: bleState.enabled,
                      onChanged: bleState.loading ? null : _toggleBle,
                      activeThumbColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Section: Sync & Maintenance
        _buildSectionHeader(l10n.cacheAndSync),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor),
          ),
          child: _SettingsTile(
            icon: LucideIcons.refresh_cw,
            iconColor: Colors.purple,
            iconBgColor: Colors.purple.withValues(alpha: 0.08),
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
            icon: const Icon(
              LucideIcons.log_out,
              size: 18,
              color: AppColors.error,
            ),
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

  Widget _buildSectionHeader(String label) {
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            fontSize: 14,
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
      borderRadius: BorderRadius.circular(16),
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
                isRtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/locale_cubit.dart';
import 'package:sayr_mobile/core/theme_cubit.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
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

class _ProfileViewState extends State<_ProfileView> {
  bool _bleEnabled = false;
  bool _isLoadingBle = true;

  @override
  void initState() {
    super.initState();
    _loadBlePreference();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.syncCompleted),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    widget.user.displayName.isNotEmpty
                        ? widget.user.displayName[0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.user.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.accountSettings,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.editProfile),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => _EditProfileDialog(user: widget.user),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.changePassword),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _ChangePasswordDialog(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.appPreferences,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                subtitle: Text(
                  context.watch<LocaleCubit>().state.languageCode == 'ar'
                      ? l10n.arabic
                      : l10n.english,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final current = context.read<LocaleCubit>().state;
                  context.read<LocaleCubit>().setLocale(
                        current.languageCode == 'ar'
                            ? const Locale('en')
                            : const Locale('ar'),
                      );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.themeMode),
                subtitle: Text(
                  switch (context.watch<ThemeCubit>().state) {
                    ThemeMode.light => l10n.themeLight,
                    ThemeMode.dark => l10n.themeDark,
                    ThemeMode.system => l10n.themeSystem,
                  },
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeSelectionDialog(context),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.bluetooth),
                title: Text(l10n.bleProximityBoarding),
                subtitle: Text(l10n.bleProximityBoardingDesc),
                value: _bleEnabled,
                onChanged: _isLoadingBle ? null : _toggleBle,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.cacheAndSync,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.sync),
                title: Text(l10n.forceSync),
                subtitle: Text(l10n.forceSyncDesc),
                trailing: const Icon(Icons.chevron_right),
                onTap: _syncCache,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  l10n.logout,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            l10n.appVersion('1.0.0'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }

  void _showThemeSelectionDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentTheme = context.read<ThemeCubit>().state;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.themeMode),
          content: RadioGroup<ThemeMode>(
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) {
                context.read<ThemeCubit>().setThemeMode(value);
                Navigator.of(dialogContext).pop();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeLight),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeDark),
                  value: ThemeMode.dark,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeSystem),
                  value: ThemeMode.system,
                ),
              ],
            ),
          ),
        );
      },
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

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.user});
  final core.User user;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  String? _selectedInstitutionId;
  List<({String id, String name, String city})> _institutions = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _selectedInstitutionId = widget.user.institutionId?.value;
    _loadInstitutions();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutions() async {
    final result = await sl<core.AuthRepository>().getInstitutions();
    if (mounted) {
      result.fold(
        (failure) => setState(() {
          _errorMessage = failure.toLocalizedString(context);
          _isLoading = false;
        }),
        (list) {
          final exists = list.any((inst) => inst.id == _selectedInstitutionId);
          setState(() {
            _institutions = list;
            if (!exists) {
              _selectedInstitutionId = list.isNotEmpty ? list.first.id : null;
            }
            _isLoading = false;
          });
        },
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInstitutionId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await sl<core.AuthRepository>().updateProfile(
      phone: _phoneController.text.trim(),
      institutionId: _selectedInstitutionId!,
    );

    if (mounted) {
      result.fold(
        (failure) => setState(() {
          _errorMessage = failure.toLocalizedString(context);
          _isSaving = false;
        }),
        (_) {
          context.read<AuthBloc>().add(const AuthCheckRequested());
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).editProfileSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.editProfile),
      content: Form(
        key: _formKey,
        child: _isLoading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: l10n.phoneLabel,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedInstitutionId,
                      decoration: InputDecoration(
                        labelText: l10n.institutionLabel,
                      ),
                      items: _institutions
                          .map(
                            (inst) => DropdownMenuItem(
                              value: inst.id,
                              child: Text(inst.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedInstitutionId = val);
                      },
                      validator: (val) => val == null ? l10n.error : null,
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isLoading || _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n.saveButton),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await sl<core.AuthRepository>().updatePassword(
      _passwordController.text.trim(),
    );

    if (mounted) {
      result.fold(
        (failure) => setState(() {
          _errorMessage = failure.toLocalizedString(context);
          _isSaving = false;
        }),
        (_) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).changePasswordSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.changePassword),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.newPasswordLabel,
                ),
                obscureText: true,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return l10n.passwordRequired;
                  }
                  if (val.length < 6) {
                    return l10n.passwordTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _confirmController,
                decoration: InputDecoration(
                  labelText: l10n.confirmNewPasswordLabel,
                ),
                obscureText: true,
                validator: (val) {
                  if (val != _passwordController.text) {
                    return l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n.saveButton),
        ),
      ],
    );
  }
}

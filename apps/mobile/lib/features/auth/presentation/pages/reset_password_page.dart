import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/reset_password_form_cubit.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Page that allows users to reset/update their password.
class ResetPasswordPage extends StatelessWidget {
  /// Creates a [ResetPasswordPage].
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ResetPasswordFormCubit(),
      child: const _ResetPasswordView(),
    );
  }
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView();

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthPasswordUpdateRequested(_passwordController.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthPasswordUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.passwordUpdated)),
              );
              context.go('/');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.failure.toLocalizedString(context)),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.resetPasswordTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.resetPasswordSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    BlocBuilder<ResetPasswordFormCubit,
                        ({bool obscurePassword, bool obscureConfirm})>(
                      builder: (context, visibility) {
                        return Column(
                          children: [
                            AppTextField(
                              label: l10n.newPassword,
                              hint: l10n.passwordHint,
                              controller: _passwordController,
                              obscureText: visibility.obscurePassword,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  visibility.obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => context
                                    .read<ResetPasswordFormCubit>()
                                    .togglePasswordVisibility(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.validationPasswordRequired;
                                }
                                if (value.length < 6) {
                                  return l10n.validationPasswordTooShort;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              label: l10n.confirmPassword,
                              hint: l10n.passwordHint,
                              controller: _confirmController,
                              obscureText: visibility.obscureConfirm,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  visibility.obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => context
                                    .read<ResetPasswordFormCubit>()
                                    .toggleConfirmVisibility(),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return l10n.validationPasswordsDoNotMatch;
                                }
                                return null;
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: l10n.updatePassword,
                      onPressed: isLoading ? null : _submit,
                      isLoading: isLoading,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

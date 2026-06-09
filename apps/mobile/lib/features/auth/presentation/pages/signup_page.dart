import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/signup_form_cubit.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Page containing the registration form for new users.
class SignupPage extends StatelessWidget {
  /// Creates a [SignupPage].
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignupFormCubit(),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthSignupRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.failure.toLocalizedString(context)),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is AuthAuthenticated) {
              context.go('/');
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
                    Text(
                      l10n.signupTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.signupSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    AppTextField(
                      label: l10n.fullName,
                      hint: l10n.fullNameHint,
                      controller: _fullNameController,
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.validationFullNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.email,
                      hint: l10n.emailHint,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.validationEmailRequired;
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value.trim())) {
                          return l10n.validationEmailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.phone,
                      hint: l10n.phoneHint,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            value.trim().length < 10) {
                          return l10n.validationPhoneInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BlocBuilder<SignupFormCubit, bool>(
                      builder: (context, obscurePassword) {
                        return AppTextField(
                          label: l10n.password,
                          hint: l10n.passwordHint,
                          controller: _passwordController,
                          obscureText: obscurePassword,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => context
                                .read<SignupFormCubit>()
                                .toggleVisibility(),
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
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: l10n.signupButton,
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

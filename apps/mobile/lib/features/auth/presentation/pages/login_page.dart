import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.failure.message ?? 'خطأ غير معروف'),
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
                    const SizedBox(height: AppSpacing.huge),
                    Text(
                      l10n.loginTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.loginSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    AppTextField(
                      label: l10n.email,
                      hint: l10n.emailHint,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'البريد مطلوب';
                        }
                        if (!value.contains('@')) {
                          return 'بريد غير صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: l10n.password,
                      hint: l10n.passwordHint,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'كلمة المرور مطلوبة';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور قصيرة جداً';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(l10n.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: l10n.loginButton,
                      onPressed: isLoading ? null : _submit,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            l10n.orContinueWith,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SecondaryButton(
                      label: l10n.loginWithGoogle,
                      icon: Icons.g_mobiledata,
                      onPressed: isLoading
                          ? null
                          : () {
                              context
                                  .read<AuthBloc>()
                                  .add(const AuthGoogleSignInRequested());
                            },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.noAccount),
                        TextButton(
                          onPressed: () => context.push('/signup'),
                          child: Text(l10n.signup),
                        ),
                      ],
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

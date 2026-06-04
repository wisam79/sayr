import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
                  content: Text(state.failure.message ?? 'خطأ'),
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
                        if (value == null || value.trim().length < 3) {
                          return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: l10n.email,
                      hint: l10n.emailHint,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'بريد غير صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: l10n.phone,
                      hint: l10n.phoneHint,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
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
                        if (value == null || value.length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: l10n.signupButton,
                      onPressed: isLoading ? null : _submit,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.haveAccount),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(l10n.signin),
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

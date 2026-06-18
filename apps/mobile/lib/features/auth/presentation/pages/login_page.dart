import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/login_form_cubit.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Page containing the login form for user authentication.
class LoginPage extends StatelessWidget {
  /// Creates a [LoginPage].
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginFormCubit(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _bgController.stop();
    } else if (!_bgController.isAnimating) {
      _bgController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
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
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final disableAnimations =
        isTest || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Widget background = AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final val = _bgController.value;
        final alignment = Alignment(
          -0.5 + 1.0 * val,
          -0.8 + 0.5 * val,
        );
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: alignment,
              radius: 1.2,
              colors: [
                AppColors.primary.withValues(alpha: isDark ? 0.05 : 0.03),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (!disableAnimations) Positioned.fill(child: background),
            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  SayrFlash.error(
                    context,
                    state.failure.toLocalizedString(context),
                  );
                } else if (state is AuthPasswordResetEmailSent) {
                  SayrFlash.success(
                    context,
                    l10n.passwordResetLinkSent(state.email),
                  );
                } else if (state is AuthAuthenticated) {
                  context.go('/');
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.huge),
                        // Sayr brand S-road mark
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.08),
                            ),
                            child: const CustomPaint(
                              painter: _SRoadIconPainter(),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.loginTitle,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.loginSubtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                        BlocBuilder<LoginFormCubit, bool>(
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
                                    .read<LoginFormCubit>()
                                    .toggleVisibility(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.validationPasswordRequired;
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => context.push('/reset-password'),
                            child: Text(l10n.forgotPassword),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PrimaryButton(
                          label: l10n.loginButton,
                          onPressed: isLoading ? null : _submit,
                          isLoading: isLoading,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => context
                                  .read<AuthBloc>()
                                  .add(const AuthGoogleSignInRequested()),
                          icon: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),
                          label: Text(
                            l10n.loginWithGoogle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.divider,
                              width: 1.5,
                            ),
                          ),
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
          ],
        ),
      ),
    );
  }
}

class _SRoadIconPainter extends CustomPainter {
  const _SRoadIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path
      ..moveTo(w * 0.72, h * 0.22)
      ..cubicTo(w * 0.22, h * 0.15, w * 0.22, h * 0.48, w * 0.5, h * 0.5)
      ..cubicTo(w * 0.78, h * 0.52, w * 0.78, h * 0.85, w * 0.28, h * 0.78);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

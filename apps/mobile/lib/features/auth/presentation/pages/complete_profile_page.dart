import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/complete_profile_cubit.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

/// Screen shown after Google sign-in when the user's profile is incomplete.
class CompleteProfilePage extends StatelessWidget {
  /// Creates a [CompleteProfilePage].
  const CompleteProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CompleteProfileCubit(
        authRepository: sl<AuthRepository>(),
      )..loadInstitutions(),
      child: const _CompleteProfileView(),
    );
  }
}

class _CompleteProfileView extends StatefulWidget {
  const _CompleteProfileView();

  @override
  State<_CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<_CompleteProfileView> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, curr) => curr is AuthAuthenticated || curr is AuthError,
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.message ?? ''),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),

                      // Header
                      Icon(
                        Icons.person_add_rounded,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.completeProfileTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.completeProfileSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Phone field
                      _PhoneField(controller: _phoneController),
                      const SizedBox(height: 20),

                      // Institution dropdown
                      const _InstitutionDropdown(),
                      const SizedBox(height: 40),

                      // Submit button
                      _SubmitButton(phoneController: _phoneController),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<CompleteProfileCubit>();

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      decoration: InputDecoration(
        labelText: l10n.phoneNumber,
        hintText: '07XXXXXXXXX',
        prefixIcon: const Icon(Icons.phone_rounded),
        border: const OutlineInputBorder(),
      ),
      onChanged: cubit.phoneChanged,
    );
  }
}

class _InstitutionDropdown extends StatelessWidget {
  const _InstitutionDropdown();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
      builder: (context, state) {
        if (state.isLoadingInstitutions) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (state.institutions.isEmpty) {
          return Text(
            l10n.noInstitutionsFound,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: state.selectedInstitutionId,
          decoration: InputDecoration(
            labelText: l10n.university,
            prefixIcon: const Icon(Icons.school_rounded),
            border: const OutlineInputBorder(),
          ),
          items: state.institutions.map((inst) {
            return DropdownMenuItem(
              value: inst.id,
              child: Text('${inst.name} — ${inst.city}'),
            );
          }).toList(),
          onChanged: context.read<CompleteProfileCubit>().institutionChanged,
        );
      },
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.phoneController});

  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
      builder: (context, profileState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final isLoading = authState is AuthLoading;
            final canSubmit = profileState.isValid && !isLoading;

            return FilledButton.icon(
              onPressed: canSubmit
                  ? () {
                      context.read<AuthBloc>().add(
                            AuthProfileCompleted(
                              phone: profileState.phone,
                              institutionId:
                                  profileState.selectedInstitutionId!,
                            ),
                          );
                    }
                  : null,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(l10n.completeProfile),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            );
          },
        );
      },
    );
  }
}

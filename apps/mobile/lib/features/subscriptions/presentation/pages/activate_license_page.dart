import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_state.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/widgets/success_subscription_dialog.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Page for activating student subscription via pre-paid license code.
class ActivateLicensePage extends StatefulWidget {
  /// Creates an [ActivateLicensePage].
  const ActivateLicensePage({super.key});

  @override
  State<ActivateLicensePage> createState() => _ActivateLicensePageState();
}

class _ActivateLicensePageState extends State<ActivateLicensePage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SubscriptionsBloc>().add(
          LicenseActivateRequested(
            _codeController.text.trim().toUpperCase(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activateLicense),
      ),
      body: SafeArea(
        child: BlocConsumer<SubscriptionsBloc, SubscriptionsState>(
          listener: (context, state) {
            if (state is LicenseActivated) {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => SuccessSubscriptionDialog(
                  onConfirm: () {
                    Navigator.of(dialogContext).pop();
                    context.pop();
                  },
                ),
              );
            } else if (state is SubscriptionsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.failure.toLocalizedString(context)),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is LicenseActivating;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.huge),
                    const Icon(
                      Icons.qr_code_2,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.enterLicenseCode,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: l10n.licenseCodeLabel,
                      hint: 'A1B2C3D4',
                      controller: _codeController,
                      keyboardType: TextInputType.visiblePassword,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 8,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[A-Za-z0-9]'),
                        ),
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) {
                            return newValue.copyWith(
                              text: newValue.text.toUpperCase(),
                            );
                          },
                        ),
                        LengthLimitingTextInputFormatter(8),
                      ],
                      prefixIcon: Icons.key,
                      validator: (value) {
                        if (value == null || value.length != 8) {
                          return l10n.licenseCodeValidation;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: l10n.activate,
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

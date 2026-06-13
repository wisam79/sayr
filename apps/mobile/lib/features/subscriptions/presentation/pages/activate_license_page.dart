import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
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
          LicensePreviewRequested(
            _codeController.text.trim().toUpperCase(),
          ),
        );
  }

  void _showPreviewBottomSheet(BuildContext context, LicensePreview preview) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.licenseDetails,
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                preview.routeTitle,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: l10n.startLocation,
                value: preview.startLocation,
              ),
              const Divider(height: AppSpacing.lg),
              _DetailRow(
                icon: Icons.flag_outlined,
                label: l10n.endLocation,
                value: preview.endLocation,
              ),
              const Divider(height: AppSpacing.lg),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: l10n.subscription,
                value: l10n.daysRemainingShort(preview.validDays),
              ),
              const Divider(height: AppSpacing.lg),
              _DetailRow(
                icon: Icons.event_seat_outlined,
                label: l10n.availableSeats,
                value: '${preview.availableSeats}',
              ),
              const Divider(height: AppSpacing.lg),
              _DetailRow(
                icon: Icons.payments_outlined,
                label: l10n.price,
                value: preview.price.format(),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.confirmActivation,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.read<SubscriptionsBloc>().add(
                        LicenseActivateRequested(
                          _codeController.text.trim().toUpperCase(),
                        ),
                      );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: l10n.cancel,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.read<SubscriptionsBloc>().add(
                        const LicensePreviewReset(),
                      );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    ).then((_) {
      if (context.mounted &&
          context.read<SubscriptionsBloc>().state is LicensePreviewLoaded) {
        context.read<SubscriptionsBloc>().add(const LicensePreviewReset());
      }
    });
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
            } else if (state is LicensePreviewLoaded) {
              _showPreviewBottomSheet(context, state.preview);
            } else if (state is LicensePreviewError) {
              SayrFlash.error(context, state.failure.toLocalizedString(context));
            } else if (state is SubscriptionsError) {
              SayrFlash.error(context, state.failure.toLocalizedString(context));
            }
          },
          builder: (context, state) {
            final isLoading =
                state is LicenseActivating || state is LicensePreviewLoading;

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
                        const ArabicToEnglishDigitsFormatter(),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const Spacer(),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// A [TextInputFormatter] that translates Arabic/Persian digits to English digits.
class ArabicToEnglishDigitsFormatter extends TextInputFormatter {
  /// Creates an [ArabicToEnglishDigitsFormatter].
  const ArabicToEnglishDigitsFormatter();

  static const _arabicDigits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
  };

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newText = newValue.text;
    _arabicDigits.forEach((key, value) {
      newText = newText.replaceAll(key, value);
    });

    if (newText != newValue.text) {
      return newValue.copyWith(
        text: newText,
        selection: newValue.selection,
      );
    }
    return newValue;
  }
}

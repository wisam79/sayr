import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_event.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_state.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Payment page for Zain Cash integration.
class PaymentPage extends StatefulWidget {
  /// Creates a [PaymentPage] for the given [routeId] and [amount].
  const PaymentPage({
    required this.routeId,
    required this.amount,
    this.paymentId,
    this.paymentUrl,
    super.key,
  });

  /// The ID of the route to subscribe to.
  final RouteId routeId;

  /// The total payment amount.
  final int amount;

  /// Optional existing payment ID for resuming polling.
  final String? paymentId;

  /// Optional existing payment URL for resuming.
  final String? paymentUrl;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  void initState() {
    super.initState();
    final paymentId = widget.paymentId;
    final paymentUrl = widget.paymentUrl;
    if (paymentId != null && paymentUrl != null) {
      context.read<PaymentBloc>().add(
            PaymentResume(
              paymentId: paymentId,
              paymentUrl: paymentUrl,
              amount: widget.amount,
              currency: 'IQD',
            ),
          );
    } else {
      context.read<PaymentBloc>().add(
            PaymentStartZainCash(
              routeId: widget.routeId,
              amount: widget.amount,
              currency: 'IQD',
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.payment)),
      body: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            context.read<PaymentBloc>().add(const PaymentReset());
          }
        },
        child: BlocConsumer<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentSuccess) {
              SayrFlash.success(context, l10n.paymentSuccessSubscription);
              Navigator.of(context).pop(true);
            }
            if (state is PaymentFailed) {
              SayrFlash.error(
                context,
                state.failure.toLocalizedString(context),
              );
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state is PaymentLoading) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Text(
                        state.message ?? l10n.processing,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                  if (state is PaymentUrlReady) ...[
                    const Icon(
                      Icons.payment,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.paymentViaZainCash,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.amount('${state.amount}', state.currency),
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: l10n.openZainCash,
                      icon: Icons.open_in_new,
                      onPressed: () => _launchPaymentUrl(state.paymentUrl),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(
                      label: l10n.cancel,
                      onPressed: () {
                        context.read<PaymentBloc>().add(const PaymentReset());
                        Navigator.of(context).pop(false);
                      },
                    ),
                  ],
                  if (state is PaymentAwaitingCompletion) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.awaitingPaymentConfirmation,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.completePaymentInZainCash,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (state is PaymentFailed) ...[
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.paymentFailed,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.failure.toLocalizedString(context),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: l10n.retry,
                      icon: Icons.refresh,
                      onPressed: () => context.read<PaymentBloc>().add(
                            PaymentStartZainCash(
                              routeId: widget.routeId,
                              amount: widget.amount,
                              currency: 'IQD',
                            ),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(
                      label: l10n.help,
                      icon: Icons.help_outline,
                      onPressed: () => _launchWhatsAppSupport(context),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _launchPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchWhatsAppSupport(BuildContext context) async {
    final message = AppLocalizations.of(context).whatsappSupportMessage;
    final uri = Uri.parse(
      'https://wa.me/9647800000000?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      SayrFlash.error(
        context,
        AppLocalizations.of(context).unexpectedError,
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';

/// Payment page for Zain Cash integration.
class PaymentPage extends StatefulWidget {
  const PaymentPage({
    required this.routeId,
    required this.amount,
    super.key,
  });

  final RouteId routeId;
  final int amount;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(PaymentStartZainCash(
          routeId: widget.routeId,
          amount: widget.amount,
          currency: 'IQD',
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدفع')),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            SayrFlash.success(context, 'تم الدفع بنجاح! تم تفعيل اشتراكك');
            Navigator.of(context).pop(true);
          }
          if (state is PaymentFailed) {
            SayrFlash.error(
              context,
              state.failure.message ?? 'حدث خطأ في الدفع',
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
                      state.message ?? 'جاري المعالجة...',
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
                    'الدفع عبر زين كاش',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'المبلغ: ${state.amount} ${state.currency}',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'افتح زين كاش',
                    icon: Icons.open_in_new,
                    onPressed: () => _launchPaymentUrl(state.paymentUrl),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    label: 'إلغاء',
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
                    'في انتظار تأكيد الدفع...',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'أكمل الدفع في تطبيق زين كاش ثم عد هنا',
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
                    'فشل الدفع',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.failure.message ?? 'حدث خطأ غير متوقع',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'إعادة المحاولة',
                    icon: Icons.refresh,
                    onPressed: () => context.read<PaymentBloc>().add(
                          PaymentStartZainCash(
                            routeId: widget.routeId,
                            amount: widget.amount,
                            currency: 'IQD',
                          ),
                        ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

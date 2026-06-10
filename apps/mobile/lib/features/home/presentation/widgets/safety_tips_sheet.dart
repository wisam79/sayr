import 'package:flutter/material.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

void showSafetyTipsBottomSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.security,
                    color: AppColors.warning,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    l10n.safetyTipsTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SafetyTipRow(
                icon: Icons.bluetooth,
                text: l10n.safetyTip1,
              ),
              const SizedBox(height: AppSpacing.md),
              SafetyTipRow(
                icon: Icons.directions_bus,
                text: l10n.safetyTip2,
              ),
              const SizedBox(height: AppSpacing.md),
              SafetyTipRow(
                icon: Icons.sos,
                text: l10n.safetyTip3,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class SafetyTipRow extends StatelessWidget {
  const SafetyTipRow({required this.icon, required this.text, super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: label,
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.08 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: GlassCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          margin: EdgeInsets.zero,
          borderRadius: 16,
          color: color.withValues(alpha: isDark ? 0.06 : 0.03),
          borderOpacity: isDark ? 0.12 : 0.08,
          shadowOpacity: 0,
          blurSigma: 8,
          child: SizedBox(
            height: 108,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.18),
                        color.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: color,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

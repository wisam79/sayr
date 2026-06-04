import 'package:flutter/material.dart';

import 'package:sayr_ui_kit/src/theme/app_spacing.dart';

/// A section header with title and optional action.
class SectionHeader extends StatelessWidget {
  /// Creates a [SectionHeader].
  const SectionHeader({
    required this.title,
    super.key,
    this.action,
  });

  /// The header title.
  final String title;

  /// Optional action widget.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

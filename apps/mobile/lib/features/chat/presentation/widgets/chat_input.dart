import 'package:flutter/material.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Bottom input bar for the chat page.
///
/// Stateless — parent owns the text controller and dispatches send events.
class ChatInput extends StatelessWidget {
  /// Creates a [ChatInput] input bar.
  const ChatInput({
    required this.controller,
    required this.onSend,
    required this.isSending,
    super.key,
  });

  /// Controller for the text field input.
  final TextEditingController controller;

  /// Callback when a message is sent.
  final ValueChanged<String> onSend;

  /// Indicates whether a message is currently being sent.
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: l10n.messageHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onSubmitted: (String text) {
                  final trimmed = text.trim();
                  if (trimmed.isNotEmpty) {
                    onSend(trimmed);
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isSending
                    ? null
                    : () {
                        final trimmed = controller.text.trim();
                        if (trimmed.isNotEmpty) {
                          onSend(trimmed);
                          controller.clear();
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

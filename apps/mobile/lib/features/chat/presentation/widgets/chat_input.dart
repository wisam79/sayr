import 'package:flutter/material.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Bottom input bar for the chat page.
///
/// Stateless — parent owns the text controller and dispatches send events.
class ChatInput extends StatelessWidget {
  const ChatInput({
    required this.controller,
    required this.onSend,
    required this.isSending,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
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
                  hintText: 'اكتب رسالة...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onSubmitted: (String text) {
                  final String trimmed = text.trim();
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
                        final String trimmed = controller.text.trim();
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

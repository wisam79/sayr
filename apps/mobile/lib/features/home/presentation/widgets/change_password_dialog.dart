import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

part 'change_password_dialog.freezed.dart';

/// Dialog to change the user's password.
class ChangePasswordDialog extends StatefulWidget {
  /// Creates a [ChangePasswordDialog].
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

@freezed
abstract class ChangePasswordState with _$ChangePasswordState {
  const factory ChangePasswordState({
    required bool isSaving,
    String? errorMessage,
  }) = _ChangePasswordState;
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final ValueNotifier<ChangePasswordState> _stateNotifier =
      ValueNotifier(const ChangePasswordState(isSaving: false));

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _stateNotifier.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    _stateNotifier.value = const ChangePasswordState(
      isSaving: true,
    );

    final result = await sl<core.AuthRepository>().updatePassword(
      _passwordController.text.trim(),
    );

    if (mounted) {
      result.fold(
        (failure) => _stateNotifier.value = ChangePasswordState(
          errorMessage: failure.toLocalizedString(context),
          isSaving: false,
        ),
        (_) {
          Navigator.of(context).pop();
          SayrFlash.success(
            context,
            AppLocalizations.of(context).changePasswordSuccess,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<ChangePasswordState>(
      valueListenable: _stateNotifier,
      builder: (context, state, _) {
        return AlertDialog(
          title: Text(l10n.changePassword),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.newPasswordLabel,
                    ),
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return l10n.passwordRequired;
                      }
                      if (val.length < 6) {
                        return l10n.passwordTooShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _confirmController,
                    decoration: InputDecoration(
                      labelText: l10n.confirmNewPasswordLabel,
                    ),
                    obscureText: true,
                    validator: (val) {
                      if (val != _passwordController.text) {
                        return l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  state.isSaving ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: state.isSaving ? null : _save,
              child: state.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.saveButton),
            ),
          ],
        );
      },
    );
  }
}

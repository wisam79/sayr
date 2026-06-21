import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

part 'edit_profile_dialog.freezed.dart';

/// Dialog to edit user profile (phone + institution).
class EditProfileDialog extends StatefulWidget {
  /// Creates an [EditProfileDialog] with the given [user].
  const EditProfileDialog({required this.user, super.key});

  /// The current user to edit.
  final core.User user;

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

@freezed
abstract class EditProfileState with _$EditProfileState {
  const factory EditProfileState({
    required List<({String id, String name, String city})> institutions,
    required bool isLoading,
    required bool isSaving,
    String? selectedInstitutionId,
    String? errorMessage,
  }) = _EditProfileState;
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  final ValueNotifier<EditProfileState> _stateNotifier = ValueNotifier(
    const EditProfileState(
      institutions: [],
      isLoading: true,
      isSaving: false,
    ),
  );

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _stateNotifier.value = EditProfileState(
      selectedInstitutionId: widget.user.institutionId?.value,
      institutions: const [],
      isLoading: true,
      isSaving: false,
    );
    _loadInstitutions();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _stateNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutions() async {
    final result = await sl<core.AuthRepository>().getInstitutions();
    if (mounted) {
      result.fold(
        (failure) => _stateNotifier.value = EditProfileState(
          selectedInstitutionId: _stateNotifier.value.selectedInstitutionId,
          institutions: const [],
          isLoading: false,
          isSaving: false,
          errorMessage: failure.toLocalizedString(context),
        ),
        (list) {
          final exists = list.any(
            (inst) => inst.id == _stateNotifier.value.selectedInstitutionId,
          );
          final selId = exists
              ? _stateNotifier.value.selectedInstitutionId
              : (list.isNotEmpty ? list.first.id : null);
          _stateNotifier.value = EditProfileState(
            selectedInstitutionId: selId,
            institutions: list,
            isLoading: false,
            isSaving: false,
          );
        },
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final selectedId = _stateNotifier.value.selectedInstitutionId;
    if (selectedId == null) return;

    _stateNotifier.value = EditProfileState(
      selectedInstitutionId: selectedId,
      institutions: _stateNotifier.value.institutions,
      isLoading: false,
      isSaving: true,
    );

    final result = await sl<core.AuthRepository>().updateProfile(
      phone: _phoneController.text.trim(),
      institutionId: selectedId,
    );

    if (mounted) {
      result.fold(
        (failure) => _stateNotifier.value = EditProfileState(
          selectedInstitutionId: selectedId,
          institutions: _stateNotifier.value.institutions,
          isLoading: false,
          isSaving: false,
          errorMessage: failure.toLocalizedString(context),
        ),
        (_) {
          context.read<AuthBloc>().add(const AuthCheckRequested());
          Navigator.of(context).pop();
          SayrFlash.success(
            context,
            AppLocalizations.of(context).editProfileSuccess,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<EditProfileState>(
      valueListenable: _stateNotifier,
      builder: (context, state, _) {
        return AlertDialog(
          title: Text(l10n.editProfile),
          content: Form(
            key: _formKey,
            child: state.isLoading
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.errorMessage != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: l10n.phoneLabel,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String>(
                          initialValue: state.selectedInstitutionId,
                          decoration: InputDecoration(
                            labelText: l10n.institutionLabel,
                          ),
                          items: state.institutions
                              .map(
                                (inst) => DropdownMenuItem(
                                  value: inst.id,
                                  child: Text(inst.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            _stateNotifier.value = EditProfileState(
                              selectedInstitutionId: val,
                              institutions: _stateNotifier.value.institutions,
                              isLoading: false,
                              isSaving: false,
                              errorMessage: _stateNotifier.value.errorMessage,
                            );
                          },
                          validator: (val) => val == null ? l10n.error : null,
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
              onPressed: state.isLoading || state.isSaving ? null : _save,
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

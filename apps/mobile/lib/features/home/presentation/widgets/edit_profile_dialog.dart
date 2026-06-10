import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Dialog to edit user profile (phone + institution).
class EditProfileDialog extends StatefulWidget {
  /// Creates an [EditProfileDialog] with the given [user].
  const EditProfileDialog({required this.user, super.key});

  /// The current user to edit.
  final core.User user;

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  String? _selectedInstitutionId;
  List<({String id, String name, String city})> _institutions = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _selectedInstitutionId = widget.user.institutionId?.value;
    _loadInstitutions();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutions() async {
    final result = await sl<core.AuthRepository>().getInstitutions();
    if (mounted) {
      result.fold(
        (failure) => setState(() {
          _errorMessage = failure.toLocalizedString(context);
          _isLoading = false;
        }),
        (list) {
          final exists = list.any((inst) => inst.id == _selectedInstitutionId);
          setState(() {
            _institutions = list;
            if (!exists) {
              _selectedInstitutionId = list.isNotEmpty ? list.first.id : null;
            }
            _isLoading = false;
          });
        },
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInstitutionId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await sl<core.AuthRepository>().updateProfile(
      phone: _phoneController.text.trim(),
      institutionId: _selectedInstitutionId!,
    );

    if (mounted) {
      result.fold(
        (failure) => setState(() {
          _errorMessage = failure.toLocalizedString(context);
          _isSaving = false;
        }),
        (_) {
          context.read<AuthBloc>().add(const AuthCheckRequested());
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).editProfileSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.editProfile),
      content: Form(
        key: _formKey,
        child: _isLoading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          _errorMessage!,
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
                      initialValue: _selectedInstitutionId,
                      decoration: InputDecoration(
                        labelText: l10n.institutionLabel,
                      ),
                      items: _institutions
                          .map(
                            (inst) => DropdownMenuItem(
                              value: inst.id,
                              child: Text(inst.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedInstitutionId = val);
                      },
                      validator: (val) => val == null ? l10n.error : null,
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isLoading || _isSaving ? null : _save,
          child: _isSaving
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
  }
}

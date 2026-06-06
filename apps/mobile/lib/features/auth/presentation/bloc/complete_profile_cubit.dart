import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart';

/// State for [CompleteProfileCubit].
class CompleteProfileState extends Equatable {
  /// Creates a [CompleteProfileState].
  const CompleteProfileState({
    this.institutions = const [],
    this.selectedInstitutionId,
    this.phone = '',
    this.isLoading = false,
    this.isLoadingInstitutions = true,
    this.errorMessage,
  });

  /// List of available institutions (id, name, city).
  final List<({String id, String name, String city})> institutions;

  /// The currently selected institution ID.
  final String? selectedInstitutionId;

  /// The phone number entered by the user.
  final String phone;

  /// Whether a save operation is in progress.
  final bool isLoading;

  /// Whether institutions are being fetched.
  final bool isLoadingInstitutions;

  /// Error message, if any.
  final String? errorMessage;

  /// Whether the form is valid and can be submitted.
  bool get isValid =>
      phone.length >= 11 &&
      phone.startsWith('07') &&
      selectedInstitutionId != null;

  /// Copies the state with the given overrides.
  CompleteProfileState copyWith({
    List<({String id, String name, String city})>? institutions,
    String? selectedInstitutionId,
    String? phone,
    bool? isLoading,
    bool? isLoadingInstitutions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CompleteProfileState(
      institutions: institutions ?? this.institutions,
      selectedInstitutionId:
          selectedInstitutionId ?? this.selectedInstitutionId,
      phone: phone ?? this.phone,
      isLoading: isLoading ?? this.isLoading,
      isLoadingInstitutions:
          isLoadingInstitutions ?? this.isLoadingInstitutions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        institutions,
        selectedInstitutionId,
        phone,
        isLoading,
        isLoadingInstitutions,
        errorMessage,
      ];
}

/// Cubit for the complete-profile screen.
class CompleteProfileCubit extends Cubit<CompleteProfileState> {
  /// Creates a [CompleteProfileCubit].
  CompleteProfileCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const CompleteProfileState());

  final AuthRepository _authRepository;

  /// Fetches the institutions list on screen open.
  Future<void> loadInstitutions() async {
    emit(state.copyWith(isLoadingInstitutions: true, clearError: true));
    final result = await _authRepository.getInstitutions();
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingInstitutions: false,
          errorMessage: failure.message,
        ),
      ),
      (list) => emit(
        state.copyWith(institutions: list, isLoadingInstitutions: false),
      ),
    );
  }

  /// Updates the phone field value.
  void phoneChanged(String value) =>
      emit(state.copyWith(phone: value, clearError: true));

  /// Updates the selected institution.
  void institutionChanged(String? id) =>
      emit(state.copyWith(selectedInstitutionId: id, clearError: true));
}

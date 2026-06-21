import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'complete_profile_cubit.freezed.dart';

/// State for [CompleteProfileCubit].
@freezed
abstract class CompleteProfileState with _$CompleteProfileState {
  /// Creates a [CompleteProfileState].
  const factory CompleteProfileState({
    /// List of available institutions (id, name, city).
    @Default([]) List<({String id, String name, String city})> institutions,
    
    /// The currently selected institution ID.
    String? selectedInstitutionId,
    
    /// The phone number entered by the user.
    @Default('') String phone,
    
    /// Whether a save operation is in progress.
    @Default(false) bool isLoading,
    
    /// Whether institutions are being fetched.
    @Default(true) bool isLoadingInstitutions,
    
    /// Error message, if any.
    String? errorMessage,
  }) = _CompleteProfileState;

  const CompleteProfileState._();

  /// Whether the form is valid and can be submitted.
  bool get isValid =>
      phone.length >= 11 &&
      phone.startsWith('07') &&
      selectedInstitutionId != null;
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
    emit(state.copyWith(isLoadingInstitutions: true, errorMessage: null));
    final result = await _authRepository.getInstitutions();
    if (isClosed) return;
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
      emit(state.copyWith(phone: value, errorMessage: null));

  /// Updates the selected institution.
  void institutionChanged(String? id) =>
      emit(state.copyWith(selectedInstitutionId: id, errorMessage: null));
}

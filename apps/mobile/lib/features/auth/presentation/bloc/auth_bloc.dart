import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';

/// Bloc for managing authentication state.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Creates an instance of [AuthBloc] with the given [authRepository].
  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthProfileCompleted>(_onProfileCompleted);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthPasswordUpdateRequested>(_onPasswordUpdateRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserChanged>(_onUserChanged);
  }

  final AuthRepository _authRepository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      emit(const AuthLoading());
      final user = await _authRepository.fetchFullProfile();
      if (isClosed) return;
      if (user != null) {
        final isComplete = user.phone != null && user.institutionId != null;
        if (isComplete) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthProfileIncomplete(user));
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.signInWithPassword(
      email: event.email,
      password: event.password,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignupRequested(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.signUp(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
      phone: event.phone,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.signInWithGoogle();
    if (isClosed) return;

    await result.fold(
      (failure) async => emit(AuthError(failure)),
      (_) async {
        // Fetch full profile from `profiles` table to check completeness.
        // JWT alone doesn't carry phone / institution_id for Google users.
        final user = await _authRepository.fetchFullProfile();
        if (isClosed) return;
        if (user == null) {
          emit(const AuthUnauthenticated());
          return;
        }
        final isComplete = user.phone != null && user.institutionId != null;
        if (isComplete) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthProfileIncomplete(user));
        }
      },
    );
  }

  Future<void> _onProfileCompleted(
    AuthProfileCompleted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.updateProfile(
      phone: event.phone,
      institutionId: event.institutionId,
    );

    if (isClosed) return;
    await result.fold(
      (failure) async => emit(AuthError(failure)),
      (_) async {
        final user = await _authRepository.fetchFullProfile();
        if (isClosed) return;
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    if (isClosed) return;
    emit(const AuthUnauthenticated());
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.sendPasswordResetEmail(
      event.email.trim(),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure)),
      (_) => emit(AuthPasswordResetEmailSent(event.email.trim())),
    );
  }

  Future<void> _onPasswordUpdateRequested(
    AuthPasswordUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.updatePassword(event.password);

    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure)),
      (_) => emit(const AuthPasswordUpdated()),
    );
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }
}

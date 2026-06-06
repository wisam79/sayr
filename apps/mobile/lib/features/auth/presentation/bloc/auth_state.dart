import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';

/// Base state class for authentication bloc.
sealed class AuthState extends Equatable {
  /// Const constructor for [AuthState].
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the authentication status check has not started yet.
class AuthInitial extends AuthState {
  /// Constructor for [AuthInitial].
  const AuthInitial();
}

/// State indicating that an authentication process is in progress.
class AuthLoading extends AuthState {
  /// Constructor for [AuthLoading].
  const AuthLoading();
}

/// State indicating that the user is successfully authenticated.
class AuthAuthenticated extends AuthState {
  /// Constructor for [AuthAuthenticated].
  const AuthAuthenticated(this.user);

  /// The authenticated user entity.
  final User user;

  @override
  List<Object?> get props => [user];
}

/// State indicating that the user is not authenticated.
class AuthUnauthenticated extends AuthState {
  /// Constructor for [AuthUnauthenticated].
  const AuthUnauthenticated();
}

/// State indicating that the user signed in (e.g. via Google) but their
/// profile is incomplete — phone or institution is missing.
class AuthProfileIncomplete extends AuthState {
  /// Constructor for [AuthProfileIncomplete].
  const AuthProfileIncomplete(this.user);

  /// The partially-set-up user.
  final User user;

  @override
  List<Object?> get props => [user];
}

/// State indicating that a password reset email has been successfully sent.
class AuthPasswordResetEmailSent extends AuthState {
  /// Constructor for [AuthPasswordResetEmailSent].
  const AuthPasswordResetEmailSent(this.email);

  /// The email address to which the reset link was sent.
  final String email;

  @override
  List<Object?> get props => [email];
}

/// State indicating that the user's password has been updated successfully.
class AuthPasswordUpdated extends AuthState {
  /// Constructor for [AuthPasswordUpdated].
  const AuthPasswordUpdated();
}

/// State indicating that an authentication error occurred.
class AuthError extends AuthState {
  /// Constructor for [AuthError].
  const AuthError(this.failure);

  /// The failure detail of the error.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';

/// Base event class for authentication bloc.
sealed class AuthEvent extends Equatable {
  /// Const constructor for [AuthEvent].
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched to check current authentication status.
class AuthCheckRequested extends AuthEvent {
  /// Constructor for [AuthCheckRequested].
  const AuthCheckRequested();
}

/// Event dispatched when a user requests email/password login.
class AuthLoginRequested extends AuthEvent {
  /// Constructor for [AuthLoginRequested].
  const AuthLoginRequested({required this.email, required this.password});

  /// The email address of the user attempting to log in.
  final String email;

  /// The password of the user attempting to log in.
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Event dispatched when a user requests sign-up.
class AuthSignupRequested extends AuthEvent {
  /// Constructor for [AuthSignupRequested].
  const AuthSignupRequested({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
  });

  /// The email address of the user signing up.
  final String email;

  /// The password for the new user account.
  final String password;

  /// The full name of the user.
  final String fullName;

  /// The optional phone number of the user.
  final String? phone;

  @override
  List<Object?> get props => [email, password, fullName, phone];
}

/// Event dispatched when Google sign-in is requested.
class AuthGoogleSignInRequested extends AuthEvent {
  /// Constructor for [AuthGoogleSignInRequested].
  const AuthGoogleSignInRequested();
}

/// Event dispatched when requesting a password reset email.
class AuthPasswordResetRequested extends AuthEvent {
  /// Constructor for [AuthPasswordResetRequested].
  const AuthPasswordResetRequested(this.email);

  /// The email address to send the password reset link to.
  final String email;

  @override
  List<Object?> get props => [email];
}

/// Event dispatched when updating the user's password.
class AuthPasswordUpdateRequested extends AuthEvent {
  /// Constructor for [AuthPasswordUpdateRequested].
  const AuthPasswordUpdateRequested(this.password);

  /// The new password value.
  final String password;

  @override
  List<Object?> get props => [password];
}

/// Event dispatched when a user requests to log out.
class AuthLogoutRequested extends AuthEvent {
  /// Constructor for [AuthLogoutRequested].
  const AuthLogoutRequested();
}

/// Event dispatched when the user's authentication state changes.
class AuthUserChanged extends AuthEvent {
  /// Constructor for [AuthUserChanged].
  const AuthUserChanged(this.user);

  /// The updated user entity (null if unauthenticated).
  final User? user;

  @override
  List<Object?> get props => [user];
}

/// Event dispatched when the user completes their profile after Google sign-in.
class AuthProfileCompleted extends AuthEvent {
  /// Constructor for [AuthProfileCompleted].
  const AuthProfileCompleted({
    required this.phone,
    required this.institutionId,
  });

  /// The phone number entered by the user.
  final String phone;

  /// The selected institution ID.
  final String institutionId;

  @override
  List<Object?> get props => [phone, institutionId];
}

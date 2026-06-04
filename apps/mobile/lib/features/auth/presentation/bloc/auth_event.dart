import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignupRequested extends AuthEvent {
  const AuthSignupRequested({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
  });
  final String email;
  final String password;
  final String fullName;
  final String? phone;

  @override
  List<Object?> get props => [email, password, fullName, phone];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthPasswordUpdateRequested extends AuthEvent {
  const AuthPasswordUpdateRequested(this.password);

  final String password;

  @override
  List<Object?> get props => [password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthUserChanged extends AuthEvent {
  const AuthUserChanged(this.user);
  final User? user;

  @override
  List<Object?> get props => [user];
}

import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthPasswordResetEmailSent extends AuthState {
  const AuthPasswordResetEmailSent(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthPasswordUpdated extends AuthState {
  const AuthPasswordUpdated();
}

class AuthError extends AuthState {
  const AuthError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

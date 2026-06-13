import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class CheckSession extends AuthEvent {
  const CheckSession();
}

class BiometricAuthRequested extends AuthEvent {
  const BiometricAuthRequested();
}

class PinAuthRequested extends AuthEvent {
  final String pin;

  const PinAuthRequested({required this.pin});

  @override
  List<Object?> get props => [pin];
}

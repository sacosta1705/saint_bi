part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final ApiConnection connection;
  final String password;

  const AuthLoginRequested({required this.connection, required this.password});

  @override
  List<Object?> get props => [connection, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthConsolidatedRequested extends AuthEvent {
  final String password;

  const AuthConsolidatedRequested({required this.password});

  @override
  List<Object?> get props => [password];
}

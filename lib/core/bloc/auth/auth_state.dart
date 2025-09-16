part of 'auth_bloc.dart';

enum AuthStatus {
  unknown,
  loading,
  authenticated,
  unauthenticated,
  consolidated,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final LoginResponse? loginResponse;
  
  final String? error;
  final Map<int, String> activeTokens;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.loginResponse,
    this.error,
    this.activeTokens = const {},
  });

  AuthState copyWith({
    AuthStatus? status,
    LoginResponse? loginResponse,
    String? error,
    Map<int, String>? activeTokens,
  }) {
    return AuthState(
      status: status ?? this.status,
      loginResponse: loginResponse ?? this.loginResponse,
      error: error ?? this.error,
      activeTokens: activeTokens ?? this.activeTokens,
    );
  }

  @override
  List<Object?> get props => [status, loginResponse, error, activeTokens];
}

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:saint_bi/core/bloc/connection/connection_bloc.dart';
import 'package:saint_bi/core/data/models/api_connection.dart';
import 'package:saint_bi/core/data/models/login_response.dart';
import 'package:saint_bi/core/data/repositories/auth_repository.dart';
import 'package:saint_bi/core/data/sources/remote/saint_api_exceptions.dart';
import 'package:saint_bi/core/utils/constants.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final ConnectionBloc _connectionBloc;

  AuthBloc({
    required AuthRepository authRepository,
    required ConnectionBloc connectionBloc,
  }) : _authRepository = authRepository,
       _connectionBloc = connectionBloc,
       super(const AuthState()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthConsolidatedRequested>(_onConsolidatedLoginRequested);
  }

  Future<void> _onConsolidatedLoginRequested(
    AuthConsolidatedRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final connectionState = _connectionBloc.state;
    final Map<int, String> authenticatedTokens = {};
    bool hasFailed = false;

    for (final connection in connectionState.availableConnections) {
      try {
        final response = await _authRepository.login(
          baseUrl: connection.baseUrl,
          username: connection.username,
          password: event.password,
          terminal: connection.terminal,
        );

        if (response?.authToken != null && response!.authToken!.isNotEmpty) {
          authenticatedTokens[connection.id!] = response.authToken!;
        } else {
          hasFailed = true;
          break;
        }
      } catch (e) {
        hasFailed = true;
        break;
      }
    }

    if (hasFailed) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Fallo la autenticacion en al menos una conexion.',
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.consolidated,
          activeTokens: authenticatedTokens,
          loginResponse: null,
        ),
      );
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final response = await _authRepository.login(
        baseUrl: event.connection.baseUrl,
        username: event.connection.username,
        password: event.password,
        terminal: event.connection.terminal,
      );

      if (response?.authToken != null && response!.authToken!.isNotEmpty) {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            loginResponse: response,
          ),
        );
      } else {
        throw AuthenticationException(
          'Respuesta de inicio de sesión inválida.',
        );
      }
    } on AuthenticationException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: '${AppConstants.authErrorMessage}: ${e.msg}',
        ),
      );
    } on NetworkException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: '${AppConstants.networkErrorMessage}: ${e.msg}',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Error inesperado: ${e.toString()}',
        ),
      );
    }
  }

  void _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) {
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}

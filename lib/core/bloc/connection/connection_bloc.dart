import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:saint_bi/core/data/models/api_connection.dart';
import 'package:saint_bi/core/data/repositories/connection_repository.dart';

part 'connection_event.dart';
part 'connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  final ConnectionRepository _connectionRepository;

  ConnectionBloc({required ConnectionRepository connectionRepository})
    : _connectionRepository = connectionRepository,
      super(const ConnectionState()) {
    on<ConnectionsLoaded>(_onConnectionsLoaded);
    on<ConnectionAdded>(_onConnectionAdded);
    on<ConnectionUpdated>(_onConnectionUpdated);
    on<ConnectionDeleted>(_onConnectionDeleted);
    on<ConnectionSelected>(_onConnectionSelected);
  }

  Future<void> _onConnectionsLoaded(
    ConnectionsLoaded event,
    Emitter<ConnectionState> emit,
  ) async {
    emit(state.copyWith(status: ConnectionStatus.loading));
    try {
      final connections = await _connectionRepository.getAllConnections();
      connections.sort(
        (a, b) => a.companyAlias.toLowerCase().compareTo(
          b.companyAlias.toLowerCase(),
        ),
      );

      ApiConnection? active = state.activeConnection;

      // Se separa la lógica de la comprobación para garantizar la seguridad nula.
      bool activeConnectionStillExists = false;
      if (active != null) {
        // Comprobamos si la conexión que estaba activa sigue en la lista actualizada.
        activeConnectionStillExists = connections.any(
          (c) => c.id == active!.id,
        );
      }

      // Si hay conexiones disponibles Y la que estaba activa ya no existe (o nunca hubo una),
      // se establece la primera de la lista como la nueva activa.
      if (connections.isNotEmpty && !activeConnectionStillExists) {
        active = connections.first;
      } else if (connections.isEmpty) {
        // Si no hay ninguna conexión, la activa debe ser null.
        active = null;
      }
      // En el caso de que la conexión activa SÍ exista en la nueva lista,
      // 'active' mantiene su valor original y no se modifica.

      emit(
        state.copyWith(
          status: ConnectionStatus.success,
          availableConnections: connections,
          activeConnection: active,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ConnectionStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onConnectionAdded(
    ConnectionAdded event,
    Emitter<ConnectionState> emit,
  ) async {
    try {
      await _connectionRepository.addConnection(event.connection);
      add(ConnectionsLoaded());
    } catch (e) {
      emit(
        state.copyWith(status: ConnectionStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onConnectionUpdated(
    ConnectionUpdated event,
    Emitter<ConnectionState> emit,
  ) async {
    try {
      await _connectionRepository.updateConnection(event.connection);

      final activeConn = state.activeConnection;
      if (activeConn != null && activeConn.id == event.connection.id) {
        emit(state.copyWith(activeConnection: event.connection));
      }
      add(ConnectionsLoaded());
    } catch (e) {
      emit(
        state.copyWith(status: ConnectionStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onConnectionDeleted(
    ConnectionDeleted event,
    Emitter<ConnectionState> emit,
  ) async {
    try {
      await _connectionRepository.deleteConnection(event.connectionId);

      final activeConn = state.activeConnection;
      final isDeletingActive =
          activeConn != null && activeConn.id == event.connectionId;

      emit(state.copyWith(forceActiveNull: isDeletingActive));
      add(ConnectionsLoaded());
    } catch (e) {
      emit(
        state.copyWith(status: ConnectionStatus.failure, error: e.toString()),
      );
    }
  }

  void _onConnectionSelected(
    ConnectionSelected event,
    Emitter<ConnectionState> emit,
  ) {
    emit(state.copyWith(activeConnection: event.connection));
  }
}

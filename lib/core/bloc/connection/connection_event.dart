part of 'connection_bloc.dart';

abstract class ConnectionEvent extends Equatable {
  const ConnectionEvent();

  @override
  List<Object?> get props => [];
}

// Evento para cargar todas las conexiones desde la DB
class ConnectionsLoaded extends ConnectionEvent {}

// Evento para añadir una nueva conexión
class ConnectionAdded extends ConnectionEvent {
  final ApiConnection connection;
  const ConnectionAdded(this.connection);
  @override
  List<Object?> get props => [connection];
}

// Evento para actualizar una conexión existente
class ConnectionUpdated extends ConnectionEvent {
  final ApiConnection connection;
  const ConnectionUpdated(this.connection);
  @override
  List<Object?> get props => [connection];
}

// Evento para eliminar una conexión
class ConnectionDeleted extends ConnectionEvent {
  final int connectionId;
  const ConnectionDeleted(this.connectionId);
  @override
  List<Object?> get props => [connectionId];
}

// Evento para establecer una conexión como activa
class ConnectionSelected extends ConnectionEvent {
  final ApiConnection? connection;
  const ConnectionSelected(this.connection);
  @override
  List<Object?> get props => [connection];
}

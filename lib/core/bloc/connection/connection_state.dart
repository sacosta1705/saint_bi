part of 'connection_bloc.dart';

enum ConnectionStatus { initial, loading, success, failure }

class ConnectionState extends Equatable {
  final ConnectionStatus status;
  final List<ApiConnection> availableConnections;
  final ApiConnection? activeConnection;
  final String? error;

  const ConnectionState({
    this.status = ConnectionStatus.initial,
    this.availableConnections = const [],
    this.activeConnection,
    this.error,
  });

  ConnectionState copyWith({
    ConnectionStatus? status,
    List<ApiConnection>? availableConnections,
    ApiConnection? activeConnection,
    String? error,
    bool forceActiveNull = false,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      availableConnections: availableConnections ?? this.availableConnections,
      activeConnection: forceActiveNull
          ? null
          : activeConnection ?? this.activeConnection,
      error: error, // No heredar error para evitar mostrarlo indefinidamente
    );
  }

  @override
  List<Object?> get props => [
    status,
    availableConnections,
    activeConnection,
    error,
  ];
}

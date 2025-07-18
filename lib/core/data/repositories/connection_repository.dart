import 'package:saint_bi/core/data/sources/local/database_service.dart';
import 'package:saint_bi/core/data/models/api_connection.dart';

class ConnectionRepository {
  final DatabaseService _dbService;

  ConnectionRepository({required DatabaseService dbService})
    : _dbService = dbService;

  Future<List<ApiConnection>> getAllConnections() =>
      _dbService.getAllConnections();
  Future<int> addConnection(ApiConnection connection) =>
      _dbService.insertConnection(connection);
  Future<int> updateConnection(ApiConnection connection) =>
      _dbService.updateConnection(connection);
  Future<int> deleteConnection(int connectionId) =>
      _dbService.deleteConnection(connectionId);
  Future<void> saveAppSettings({
    String? adminPasswordHash,
    String? defaultApiUser,
  }) => _dbService.saveAppSettings(
    adminPasswordHash: adminPasswordHash,
    defaultApiUser: defaultApiUser,
  );
  Future<Map<String, dynamic>> getAppSettings() => _dbService.getAppSettings();
}
